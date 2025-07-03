import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/user_name_banner.dart';
import '../widgets/location_tracking_map.dart';
import '../widgets/directions_page.dart';
import '../models/blood_request.dart';

class RequestDetailsScreen extends StatefulWidget {
  final BloodRequest request;

  RequestDetailsScreen({super.key, required dynamic request})
    : request = request is BloodRequest
          ? request
          : BloodRequest.fromJson(request as Map<String, dynamic>);

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  // Store the last parsed hospital coordinates for use in Accept
  double? _lastHospitalLat;
  double? _lastHospitalLng;

  Future<Map<String, dynamic>?> _getAcceptorDetails() async {
    try {
      print('Fetching acceptor details for: ${widget.request.acceptedBy}');
      if (widget.request.acceptedBy == null) return null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.request.acceptedBy)
          .get();
      print('Acceptor doc data: ${doc.data()}');
      return doc.data();
    } catch (e) {
      print('Error fetching acceptor details: ${e.toString()}');
      return null;
    }
  }

  // OpenCage Geocoding function
  Future<Map<String, double>?> _getLatLngFromOpenCage(String address) async {
    const apiKey = 'cde135fa80d34bd88150202958706a7d';
    final url = Uri.parse(
      'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(address)}&key=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final geometry = data['results'][0]['geometry'];
        return {
          'lat': (geometry['lat'] as num).toDouble(),
          'lng': (geometry['lng'] as num).toDouble(),
        };
      }
    }
    return null;
  }

  Future<Map<String, double>?> _getHospitalCoordinates() async {
    final hospitalName = widget.request.hospital.trim();
    if (hospitalName.isEmpty) return null;
    return await _getLatLngFromOpenCage(hospitalName);
  }

  @override
  Widget build(BuildContext context) {
    print('Building RequestDetailsScreen for request: ${widget.request.id}');
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDonor = widget.request.acceptedBy == currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UserNameBanner(),
            const SizedBox(height: 16),
            // Use OpenCage API to get hospital coordinates
            FutureBuilder<Map<String, double>?>(
              future: _getHospitalCoordinates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Error loading hospital location.')),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Hospital location not found.')),
                  );
                }
                final coords = snapshot.data!;
                final latitude = coords['lat'] ?? 24.8607;
                final longitude = coords['lng'] ?? 67.0011;
                _lastHospitalLat = latitude;
                _lastHospitalLng = longitude;
                if (latitude == 0.0 || longitude == 0.0) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Invalid or missing hospital coordinates.')),
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: LocationTrackingMap(
                        request: widget.request,
                        isDonor: isDonor,
                        hospitalLat: latitude,
                        hospitalLng: longitude,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _acceptAndStartJourney(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _ignoreRequest(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Ignore', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Request Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _detailRow('Blood Group', widget.request.bloodGroup),
                      _detailRow('Hospital', widget.request.hospital),
                      _detailRow('Patient Name', widget.request.patientName),
                      _detailRow('Urgency', widget.request.urgency),
                      _detailRow('Contact', widget.request.contactNumber),
                      _detailRow(
                        'Status',
                        widget.request.isActive ? 'Active' : 'Closed',
                      ),
                      _detailRow(
                        'Created At',
                        (() {
                          try {
                            final val = widget.request.createdAt;
                            print(
                              'CreatedAt value: ${val.runtimeType} = ${val.toString()}',
                            );
                            return val.toLocal().toString();
                          } catch (e) {
                            print(
                              'Error displaying createdAt: ${e.toString()}',
                            );
                            return '';
                          }
                        })(),
                      ),
                      if (widget.request.acceptedBy != null)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getAcceptorDetails(),
                          builder: (context, snapshot) {
                            print(
                              'Acceptor FutureBuilder snapshot: ${snapshot.connectionState}, hasData: ${snapshot.hasData}',
                            );
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              final acceptor = snapshot.data!;
                              print('Acceptor details: ${acceptor.toString()}');
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Acceptor Details:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _detailRow('Name', acceptor['name'] ?? ''),
                                  _detailRow('Email', acceptor['email'] ?? ''),
                                  _detailRow(
                                    'Phone',
                                    acceptor['phoneNumber'] ?? '',
                                  ),
                                ],
                              );
                            }
                            print('No acceptor details found');
                            return const SizedBox();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _acceptAndStartJourney(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to accept requests');
      }
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accepting request...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(widget.request.id)
          .update({
            'acceptedBy': currentUser.uid,
            'isActive': true,
          });
      if (context.mounted) {
        // Navigate to directions page with journey details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DirectionsPage(
              start: LatLng(0, 0), // Placeholder, DirectionsPage should use live user location if (0,0)
              end: _lastHospitalLat != null && _lastHospitalLng != null
                  ? LatLng(_lastHospitalLat!, _lastHospitalLng!)
                  : const LatLng(24.8607, 67.0011),
              hospitalName: widget.request.hospital,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: \\${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _ignoreRequest(BuildContext context) async {
    // Hide the request for 5 minutes (locally)
    // You can use shared_preferences for persistence if needed
    // For demo, just pop the page
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request ignored for 5 minutes.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    }
  }
}
