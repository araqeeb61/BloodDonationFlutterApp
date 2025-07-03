import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/user_name_banner.dart';
import '../widgets/directions_page.dart';
import 'request_details_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'request_details_screen.dart';
import '../models/blood_request.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Blood Requests'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.bloodtype, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    const Text('Blood Donation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Menu', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.redAccent),
                title: const Text('Dashboard'),
                onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.redAccent),
                title: const Text('Add Request'),
                onTap: () => Navigator.pushNamed(context, '/add-request'),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.redAccent),
                title: const Text('My Requests'),
                onTap: () => Navigator.pushNamed(context, '/my-requests'),
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.redAccent),
                title: const Text('Request History'),
                onTap: () => Navigator.pushNamed(context, '/request-history'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UserNameBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blood_requests')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No active requests.'));
                  }
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final requests = snapshot.data!.docs
                      .where((doc) => doc['createdAt'] != null && (doc['createdAt'] is Timestamp || doc['createdAt'] is DateTime))
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (currentUser == null) return true;
                        final userEmail = data['userEmail'] as String?;
                        final userId = data['userId'] as String?;
                        return (userEmail != currentUser.email) && (userId != currentUser.uid);
                      })
                      .toList();
                  requests.sort((a, b) {
                    final aTime = a['createdAt'] is Timestamp
                        ? a['createdAt'].toDate()
                        : (a['createdAt'] is DateTime ? a['createdAt'] as DateTime : DateTime.now());
                    final bTime = b['createdAt'] is Timestamp
                        ? b['createdAt'].toDate()
                        : (b['createdAt'] is DateTime ? b['createdAt'] as DateTime : DateTime.now());
                    return bTime.compareTo(aTime);
                  });
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index].data() as Map<String, dynamic>;
                      final docId = requests[index].id;
                      final docData = requests[index].data() as Map<String, dynamic>;
                      final createdAt = docData.containsKey('createdAt') ? docData['createdAt'] : null;

                      String timeAgo = 'just now';
                      DateTime? dateTime;

                      if (createdAt != null && createdAt is Timestamp) {
                        dateTime = createdAt.toDate();
                      } else if (createdAt != null && createdAt is DateTime) {
                        dateTime = createdAt;
                      }

                      if (dateTime != null) {
                        timeAgo = timeago.format(dateTime, locale: 'en_short');
                      }

                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isMyRequest = currentUser != null && req['userEmail'] == currentUser.email;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.redAccent,
                                    child: Text(req['bloodGroup']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  if (isMyRequest) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.person, color: Colors.green, size: 22, semanticLabel: 'Created by you'),
                                  ],
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(req['hospital']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text('Urgency: ${req['urgency']?.toString() ?? ''}', style: const TextStyle(color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                  if (timeAgo.isNotEmpty)
                                    Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Patient: ${req['patientName']?.toString() ?? ''}'),
                              if (!isMyRequest && req['userName'] != null && req['userName'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Requested by: ${req['userName']?.toString() ?? ''}', style: const TextStyle(color: Colors.purple)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isMyRequest) ...[
                                    TextButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('blood_requests').doc(docId).update({'isActive': false});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Request closed.'), backgroundColor: Colors.green),
                                        );
                                      },
                                      child: const Text('Close', style: TextStyle(color: Colors.redAccent)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Edit feature coming soon!'), backgroundColor: Colors.blue),
                                        );
                                      },
                                      child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user == null) return;
                                        try {
                                          await FirebaseFirestore.instance.collection('blood_requests').doc(docId).update({
                                            'acceptedBy': user.uid,
                                          });
                                          final updatedDoc = await FirebaseFirestore.instance.collection('blood_requests').doc(docId).get();
                                          final updatedReq = updatedDoc.data();
                                          double? hospitalLat;
                                          double? hospitalLng;
                                          if (updatedReq != null) {
                                            // Fetch hospital by name
                                            final query = await FirebaseFirestore.instance.collection('hospitals').where('name', isEqualTo: updatedReq['hospital']).get();
                                            Map<String, dynamic>? hospitalData;
                                            if (query.docs.isNotEmpty) {
                                              hospitalData = query.docs.first.data();
                                            }
                                            var lat = hospitalData?['latitude'] ?? hospitalData?['lat'];
                                            var lng = hospitalData?['longitude'] ?? hospitalData?['lng'];
                                            if ((lat == null || lng == null) && hospitalData?['location'] is Map) {
                                              final loc = hospitalData!['location'];
                                              lat = loc['latitude'] ?? loc['lat'];
                                              lng = loc['longitude'] ?? loc['lng'];
                                            }
                                            try {
                                              hospitalLat = lat is double
                                                  ? lat
                                                  : lat is int
                                                      ? lat.toDouble()
                                                      : lat is String
                                                          ? double.tryParse(lat)
                                                          : null;
                                              hospitalLng = lng is double
                                                  ? lng
                                                  : lng is int
                                                      ? lng.toDouble()
                                                      : lng is String
                                                          ? double.tryParse(lng)
                                                          : null;
                                            } catch (e) {
                                              hospitalLat = null;
                                              hospitalLng = null;
                                            }
                                            // Jump directly to journey (DirectionsPage)
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => DirectionsPage(
                                                  start: const LatLng(0, 0), // Let DirectionsPage handle live user location
                                                  end: LatLng(
                                                    hospitalLat ?? 24.8607,
                                                    hospitalLng ?? 67.0011,
                                                  ),
                                                  hospitalName: updatedReq['hospital'] ?? '',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: \\${e.toString()}'), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Request ignored for 5 minutes.'), backgroundColor: Colors.orange),
                                        );
                                        // Optionally, hide the card or mark as ignored in local storage
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Ignore', style: TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RequestDetailsScreen(
                                              request: BloodRequest.fromJson({
                                                ...req,
                                                'id': docId,
                                              }),
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('View', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  );
                }
            ),
          ), // End of Expanded
        ], // End of Column children
        ), // End of Column
      ), // End of Scaffold
    ); // End of SafeArea
  }
}
