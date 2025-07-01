import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../models/blood_request.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationTrackingMap extends StatefulWidget {
  final BloodRequest request;
  final bool isDonor;
  final double? hospitalLat;
  final double? hospitalLng;

  const LocationTrackingMap({
    super.key,
    required this.request,
    required this.isDonor,
    this.hospitalLat,
    this.hospitalLng,
  });

  @override
  State<LocationTrackingMap> createState() => _LocationTrackingMapState();
}

class _LocationTrackingMapState extends State<LocationTrackingMap> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final LocationService _locationService = LocationService();
  StreamSubscription<Position?>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    // Add hospital marker
    final double lat = widget.hospitalLat ?? widget.request.latitude;
    final double lng = widget.hospitalLng ?? widget.request.longitude;
    _markers.add(
      Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: widget.request.hospital),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (widget.isDonor) {
      // Start tracking donor's location
      await _locationService.startTracking(widget.request.id);
    } else {
      // Listen to donor's location updates
      _locationSubscription = _locationService
          .getLocationUpdates(widget.request.id)
          .listen((position) {
        if (position != null && mounted) {
          _updateDonorMarker(position);
          _animateToPosition(position);
        }
      });
    }

    setState(() {});
  }

  void _updateDonorMarker(Position position) {
    setState(() {
      _markers.removeWhere(
          (marker) => marker.markerId == const MarkerId('donor'));
      _markers.add(
        Marker(
          markerId: const MarkerId('donor'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Donor Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });
  }

  Future<void> _animateToPosition(Position position) async {
    final controller = await _controller.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        position.latitude < widget.request.latitude
            ? position.latitude
            : widget.request.latitude,
        position.longitude < widget.request.longitude
            ? position.longitude
            : widget.request.longitude,
      ),
      northeast: LatLng(
        position.latitude > widget.request.latitude
            ? position.latitude
            : widget.request.latitude,
        position.longitude > widget.request.longitude
            ? position.longitude
            : widget.request.longitude,
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    if (widget.isDonor) {
      _locationService.stopTracking();
    }
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double lat = widget.hospitalLat ?? widget.request.latitude;
    final double lng = widget.hospitalLng ?? widget.request.longitude;
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final url = Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open Google Maps'), backgroundColor: Colors.red),
                );
              }
            },
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
            backgroundColor: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}
