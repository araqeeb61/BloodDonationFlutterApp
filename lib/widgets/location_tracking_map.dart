import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/blood_request.dart';
import 'package:geolocator/geolocator.dart';
import 'directions_page.dart';
import 'custom_map_icons.dart';

class LocationTrackingMap extends StatefulWidget {
  final BloodRequest request;
  final bool isDonor;
  final double hospitalLat;
  final double hospitalLng;
  final String? apiKey;

  const LocationTrackingMap({
    Key? key,
    required this.request,
    required this.isDonor,
    required this.hospitalLat,
    required this.hospitalLng,
    this.apiKey,
  }) : super(key: key);

  @override
  State<LocationTrackingMap> createState() => _LocationTrackingMapState();
}

class _LocationTrackingMapState extends State<LocationTrackingMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _mapReady = false;
  bool _hasError = false;
  String _errorMessage = '';
  Position? _currentPosition;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    CustomMapIcons.loadIcons().then((_) {
      _determinePosition();
      try {
        _initializeMap();
      } catch (e) {
        print('Error initializing map: $e');
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    });
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Location services are disabled.';
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('donor'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: CustomMapIcons.personIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _initializeMap() {
    // Validate coordinates
    if (widget.hospitalLat.isNaN || widget.hospitalLng.isNaN) {
      throw Exception('Invalid coordinates: NaN values detected');
    }
    // Add hospital marker
    _markers.add(
      Marker(
        markerId: const MarkerId('hospital'),
        position: LatLng(widget.hospitalLat, widget.hospitalLng),
        infoWindow: InfoWindow(
          title: 'Hospital',
          snippet: widget.request.hospital,
        ),
        icon: CustomMapIcons.bloodIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _openDirections() async {
    final double destLat = widget.hospitalLat;
    final double destLng = widget.hospitalLng;
    double? startLat = _currentPosition?.latitude;
    double? startLng = _currentPosition?.longitude;
    if (startLat != null && startLng != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DirectionsPage(
            start: LatLng(startLat, startLng),
            end: LatLng(destLat, destLng),
            hospitalName: widget.request.hospital,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there was an error during initialization, show an error message
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading map: $_errorMessage'),
          ],
        ),
      );
    }

    // If we have an API key provided, we'll use it for initialization
    if (widget.apiKey != null) {
      // This would normally happen in AndroidManifest.xml or AppDelegate.swift
      // We're handling it in the widget as a workaround
      print('Using provided API key for maps: ${widget.apiKey}');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.hospitalLat, widget.hospitalLng),
              zoom: 14.0,
            ),
            markers: _markers,
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
                _mapController = controller;
                setState(() {
                  _mapReady = true;
                });
              }
            },
          ),
          if (!_mapReady)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading map...'),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 24,
            child: ElevatedButton.icon(
              onPressed: _openDirections,
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Match app theme
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
