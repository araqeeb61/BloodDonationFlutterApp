import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/blood_request.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                children: const [
                  Icon(Icons.bloodtype, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text('Blood Donation', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Menu', style: TextStyle(color: Colors.white70, fontSize: 16)),
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
      body: StreamBuilder<QuerySnapshot>(
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
          // Filter and sort requests by createdAt in Dart
          final currentUser = FirebaseAuth.instance.currentUser;
          final requests = snapshot.data!.docs
              .where((doc) => doc['createdAt'] != null && (doc['createdAt'] is Timestamp || doc['createdAt'] is DateTime))
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Exclude requests created by the current user (by email or userId)
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
                      // Show creator's name if not my request and userName exists
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
                                // Close request (set isActive to false)
                                await FirebaseFirestore.instance.collection('blood_requests').doc(docId).update({'isActive': false});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request closed.'), backgroundColor: Colors.green),
                                );
                              },
                              child: const Text('Close', style: TextStyle(color: Colors.redAccent)),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement update request screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit feature coming soon!'), backgroundColor: Colors.blue),
                                );
                              },
                              child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                            ),
                          ] else ...[
                            TextButton(
                              onPressed: () {},
                              child: const Text('Decline', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                // Update the request to set acceptedBy
                                await FirebaseFirestore.instance.collection('blood_requests').doc(docId).update({
                                  'acceptedBy': user.uid,
                                });
                                // Fetch the updated request document
                                final updatedDoc = await FirebaseFirestore.instance.collection('blood_requests').doc(docId).get();
                                final updatedReq = updatedDoc.data();
                                if (updatedReq != null) {
                                  // Convert to BloodRequest object
                                  final bloodRequest = BloodRequest.fromJson({
                                    ...updatedReq,
                                    'id': docId, // ensure id is set
                                    'createdAt': (updatedReq['createdAt'] is String)
                                        ? updatedReq['createdAt']
                                        : (updatedReq['createdAt'] is Timestamp)
                                            ? (updatedReq['createdAt'] as Timestamp).toDate().toIso8601String()
                                            : DateTime.now().toIso8601String(),
                                  });
                                  Navigator.pushNamed(context, '/request-details', arguments: bloodRequest);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
