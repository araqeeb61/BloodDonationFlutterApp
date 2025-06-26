import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Only needed for web map embedding
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real Firestore data
    final request = {
      'bloodGroup': 'A+',
      'hospital': 'City Hospital',
      'urgency': 'High',
      'patientName': 'John Doe',
      'contact': '+1234567890',
      'location': '123 Main St, City',
      'latitude': 37.7749, // Example latitude
      'longitude': -122.4194, // Example longitude
    };

    Widget mapWidget = const Center(child: Text('Map not supported on this platform'));

    if (kIsWeb) {
      final latitude = request['latitude'];
      final longitude = request['longitude'];
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'google-map',
        (int viewId) => html.IFrameElement()
          ..width = '100%'
          ..height = '100%'
          ..src = 'https://maps.google.com/maps?q=$latitude,$longitude&z=15&output=embed'
          ..style.border = 'none',
      );
      mapWidget = SizedBox(
        height: 200,
        child: HtmlElementView(viewType: 'google-map'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  radius: 28,
                  child: Text(request['bloodGroup'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request['hospital'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Urgency: ${request['urgency']}',
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Patient: ${request['patientName']}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Contact: ${request['contact']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text('Location: ${request['location']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            mapWidget,
          ],
        ),
      ),
    );
  }
}
