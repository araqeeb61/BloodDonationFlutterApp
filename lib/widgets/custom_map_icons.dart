import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMapIcons {
  static BitmapDescriptor? personIcon;
  static BitmapDescriptor? bloodIcon;

  static Future<void> loadIcons() async {
    if (personIcon == null) {
      personIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/person_marker.png',
      );
    }
    if (bloodIcon == null) {
      bloodIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/blood_marker.png',
      );
    }
  }
}
