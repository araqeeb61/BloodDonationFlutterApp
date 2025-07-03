import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'custom_map_icons.dart';

class DirectionsPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final String hospitalName;

  const DirectionsPage({
    super.key,
    required this.start,
    required this.end,
    required this.hospitalName,
  });

  @override
  State<DirectionsPage> createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      double startLat = widget.start.latitude;
      double startLng = widget.start.longitude;
      if (startLat == 0 && startLng == 0) {
        // Try to get the user's current location
        try {
          final position = await Geolocator.getCurrentPosition();
          startLat = position.latitude;
          startLng = position.longitude;
        } catch (e) {
          setState(() {
            _error = 'Live user location not available. Please enable location services.';
            _loading = false;
          });
          return;
        }
      }
      final apiKey = 'AIzaSyAzf9iCCz6zIZ8ZlONwv-8HoEH3hAjI6no';
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=${widget.end.latitude},${widget.end.longitude}&mode=driving&key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        setState(() {
          _error = 'Failed to fetch directions: HTTP ${response.statusCode}';
          _loading = false;
        });
        return;
      }
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.deepPurple,
          width: 6,
          points: _decodePolyline(points),
        );
        setState(() {
          _polylines = {polyline};
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Directions API error: ${data['status']}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Exception: ${e.runtimeType}: ${e.toString()}';
        _loading = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directions to ${widget.hospitalName}'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.start, zoom: 13),
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: widget.start,
                infoWindow: const InfoWindow(title: 'Your Location'),
                icon: CustomMapIcons.personIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: widget.end,
                infoWindow: InfoWindow(title: widget.hospitalName),
                icon: CustomMapIcons.bloodIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(child: Text('Error: $_error', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
