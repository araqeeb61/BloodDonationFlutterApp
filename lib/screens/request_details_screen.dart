import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blood_request.dart';
import '../widgets/location_tracking_map.dart';

class RequestDetailsScreen extends StatelessWidget {
  final BloodRequest request;

  const RequestDetailsScreen({
    super.key,
    required this.request,
  });

  Future<Map<String, dynamic>?> _getAcceptorDetails() async {
    if (request.acceptedBy == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(request.acceptedBy).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
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
            // Location tracking map
            SizedBox(
              height: 300,
              child: LocationTrackingMap(
                request: request,
                isDonor: isDonor,
              ),
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
                      _detailRow('Status', request.isActive ? 'Active' : 'Closed'),
                      if (request.acceptedBy != null)
                        FutureBuilder<Map<String, dynamic>?>(
                          future: _getAcceptorDetails(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              final acceptor = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text('Acceptor Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _detailRow('Name', acceptor['name'] ?? ''),
                                  _detailRow('Email', acceptor['email'] ?? ''),
                                  _detailRow('Phone', acceptor['phoneNumber'] ?? ''),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (request.isActive && request.acceptedBy == null && currentUser != null && request.userId != currentUser.uid)
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
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

      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(request.id)
          .update({
        'acceptedBy': currentUser.uid,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted successfully!'),
            backgroundColor: Colors.green,
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
