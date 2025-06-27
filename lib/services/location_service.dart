import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _locationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startTracking(String requestId) async {
    // Stop any existing tracking
    await stopTracking();

    // Check and request location permissions
    bool hasPermission = await _handlePermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    // Start location tracking
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      // Update location in Firestore
      await _firestore.collection('blood_requests').doc(requestId).update({
        'donorLatitude': position.latitude,
        'donorLongitude': position.longitude,
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Stream<Position?> getLocationUpdates(String requestId) {
    return _firestore
        .collection('blood_requests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      if (data['donorLatitude'] == null || data['donorLongitude'] == null) {
        return null;
      }
      return Position.fromMap({
        'latitude': data['donorLatitude'],
        'longitude': data['donorLongitude'],
        'timestamp': data['lastLocationUpdate'],
        'accuracy': 0,
        'altitude': 0,
        'heading': 0,
        'speed': 0,
        'speedAccuracy': 0,
      });
    });
  }
}
