import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real data from Firestore
    final List<Map<String, dynamic>> requests = [
      {
        'id': '1',
        'bloodGroup': 'A+',
        'hospital': 'City Hospital',
        'urgency': 'High',
        'patientName': 'John Doe',
        'isActive': true,
      },
      {
        'id': '2',
        'bloodGroup': 'O-',
        'hospital': 'General Hospital',
        'urgency': 'Medium',
        'patientName': 'Jane Smith',
        'isActive': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Blood Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-request'),
            tooltip: 'Add Request',
          ),
        ],
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No active requests.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
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
                              child: Text(req['bloodGroup'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req['hospital'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Urgency: ${req['urgency']}', style: const TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Patient: ${req['patientName']}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text('Decline', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/request-details');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
