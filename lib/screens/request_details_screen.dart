import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/user_name_banner.dart';
import '../widgets/location_tracking_map.dart';
import '../models/blood_request.dart';

class RequestDetailsScreen extends StatelessWidget {
  final BloodRequest request;

  RequestDetailsScreen({super.key, required dynamic request})
    : request = request is BloodRequest
          ? request
          : BloodRequest.fromJson(request as Map<String, dynamic>);

  Future<Map<String, dynamic>?> _getAcceptorDetails() async {
    try {
      print('Fetching acceptor details for: ${request.acceptedBy}');
      if (request.acceptedBy == null) return null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(request.acceptedBy)
          .get();
      print('Acceptor doc data: ${doc.data()}');
      return doc.data();
    } catch (e) {
      print('Error fetching acceptor details: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getHospitalLocation() async {
    try {
      print(
        'Fetching hospital location for: "${request.hospital}" (length: ${request.hospital.length})',
      );
      // Trim the hospital name to remove any trailing spaces
      final trimmedHospitalName = request.hospital.trim();
      print('Trimmed hospital name: "$trimmedHospitalName"');

      // Try exact match first
      var query = await FirebaseFirestore.instance
          .collection('hospitals')
          .where('name', isEqualTo: trimmedHospitalName)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('No exact match found, trying case-insensitive match');
        // Try case-insensitive match by fetching all hospitals and filtering
        query = await FirebaseFirestore.instance.collection('hospitals').get();

        // Try to find a matching hospital with more flexible matching
        final matchingDoc = query.docs.firstWhere((doc) {
          final hospitalName = doc['name']?.toString() ?? '';
          return hospitalName.toLowerCase().contains(
                trimmedHospitalName.toLowerCase(),
              ) ||
              trimmedHospitalName.toLowerCase().contains(
                hospitalName.toLowerCase(),
              );
        }, orElse: () => throw Exception('No matching hospital found'));
        print('Case-insensitive match found: ${matchingDoc.data()}');
        return matchingDoc.data();
      }

      final data = query.docs.first.data();
      print('Hospital doc data: $data');
      return data;
    } catch (e) {
      print('Error fetching hospital location: ${e.toString()}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building RequestDetailsScreen for request: ${request.id}');
    final currentUser = FirebaseAuth.instance.currentUser;
    final isDonor = request.acceptedBy == currentUser?.uid;
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
            FutureBuilder<Map<String, dynamic>?>(
              future: _getHospitalLocation(),
              builder: (context, snapshot) {
                print('Hospital FutureBuilder snapshot: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  print('Snapshot error: ${snapshot.error}');
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Error loading hospital location.')),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  print('Hospital location not found in builder');
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Hospital location not found.')),
                  );
                }
                final hospitalData = snapshot.data!;
                print('Hospital data: $hospitalData');

                // Robust extraction of latitude and longitude from possible Firestore structures
                var lat = hospitalData['latitude'] ?? hospitalData['lat'];
                var lng = hospitalData['longitude'] ?? hospitalData['lng'];
                if ((lat == null || lng == null) && hospitalData['location'] is Map) {
                  final loc = hospitalData['location'];
                  lat = loc['latitude'] ?? loc['lat'];
                  lng = loc['longitude'] ?? loc['lng'];
                }
                print('Raw latitude: $lat (${lat?.runtimeType})');
                print('Raw longitude: $lng (${lng?.runtimeType})');

                // Parse coordinates with robust handling
                double? latitude;
                double? longitude;
                try {
                  latitude = 24.8607; // Dummy latitude (e.g., Karachi)
                  longitude = 67.0011; // Dummy longitude (e.g., Karachi)
                } catch (e) {
                  print('Error parsing coordinates: $e');
                }

                print('Parsed coordinates: lat=$latitude, lng=$longitude');

                // Validate coordinates
                if (latitude == null || longitude == null || latitude == 0.0 || longitude == 0.0) {
                  print('Invalid or missing hospital coordinates');
                  return const SizedBox(
                    height: 300,
                    child: Center(child: Text('Invalid or missing hospital coordinates.')),
                  );
                }

                // Show map using LocationTrackingMap widget for all platforms
                return SizedBox(
                  height: 300,
                  child: LocationTrackingMap(
                    request: request,
                    isDonor: isDonor,
                    hospitalLat: latitude,
                    hospitalLng: longitude,
                  ),
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
                      _detailRow('Blood Group', request.bloodGroup),
                      _detailRow('Hospital', request.hospital),
                      _detailRow('Patient Name', request.patientName),
                      _detailRow('Urgency', request.urgency),
                      _detailRow('Contact', request.contactNumber),
                      _detailRow(
                        'Status',
                        request.isActive ? 'Active' : 'Closed',
                      ),
                      _detailRow(
                        'Created At',
                        (() {
                          try {
                            final val = request.createdAt;
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
                      if (request.acceptedBy != null)
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
            if (request.isActive &&
                request.acceptedBy == null &&
                currentUser != null &&
                request.userId != currentUser.uid)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(context),
                  child: const Text('Accept Request'),
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

  Future<void> _acceptRequest(BuildContext context) async {
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
          .doc(request.id)
          .update({
            'acceptedBy': currentUser.uid,
            'isActive': true, // Ensure it's still active
          });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the page to show updated status
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsScreen(request: request),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
