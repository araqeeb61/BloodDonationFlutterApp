import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view your history.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Request History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where('userEmail', isEqualTo: currentUser.email)
            .where('isActive', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No closed requests yet.'));
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index].data() as Map<String, dynamic>;
              final createdAt = req['createdAt'];
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
                            backgroundColor: Colors.grey,
                            child: Text(req['bloodGroup']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
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
                      const SizedBox(height: 12),
                      Text('Status: Closed', style: const TextStyle(color: Colors.grey)),
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
