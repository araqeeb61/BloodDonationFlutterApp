import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'add_request_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in to view your requests.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Blood Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blood_requests')
            .where(Filter.or(
              Filter('userEmail', isEqualTo: currentUser.email),
              Filter('userId', isEqualTo: currentUser.uid),
            ))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not created any requests.'));
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index].data() as Map<String, dynamic>;
              final docId = requests[index].id;
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
                            backgroundColor: Colors.redAccent,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('blood_requests').doc(docId).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request deleted.'), backgroundColor: Colors.redAccent),
                              );
                            },
                            child: const Text('Close', style: TextStyle(color: Colors.redAccent)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddRequestScreen(
                                    key: UniqueKey(),
                                    // Pass the request data as arguments for editing
                                    // You will need to update AddRequestScreen to accept and handle this
                                    requestData: req,
                                    requestId: docId,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                          ),
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
