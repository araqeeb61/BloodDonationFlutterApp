import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsPage extends StatefulWidget {
  final LatLng start;
  final LatLng end;
  final String hospitalName;

  const DirectionsPage({
    Key? key,
    required this.start,
    required this.end,
    required this.hospitalName,
  }) : super(key: key);

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
    final apiKey = 'AIzaSyAzf9iCCz6zIZ8ZlONwv-8HoEH3hAjI6no';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.start.latitude},${widget.start.longitude}&destination=${widget.end.latitude},${widget.end.longitude}&mode=driving&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
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
          _error = data['status'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
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
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: widget.end,
                infoWindow: InfoWindow(title: widget.hospitalName),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
