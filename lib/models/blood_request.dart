import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String id;
  final String userId;
  final String bloodGroup;
  final String hospital;
  final double latitude;
  final double longitude;
  final String contactNumber;
  final String patientName;
  final String urgency;
  final DateTime createdAt;
  final bool isActive;
  final String? acceptedBy;
  final String? userEmail;

  BloodRequest({
    required this.id,
    required this.userId,
    required this.bloodGroup,
    required this.hospital,
    required this.latitude,
    required this.longitude,
    required this.contactNumber,
    required this.patientName,
    required this.urgency,
    required this.createdAt,
    this.isActive = true,
    this.acceptedBy,
    this.userEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bloodGroup': bloodGroup,
      'hospital': hospital,
      'latitude': latitude,
      'longitude': longitude,
      'contactNumber': contactNumber,
      'patientName': patientName,
      'urgency': urgency,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'acceptedBy': acceptedBy,
      'userEmail': userEmail,
    };
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'],
      userId: json['userId'],
      bloodGroup: json['bloodGroup'],
      hospital: json['hospital'],
      latitude: json['latitude'] is double ? json['latitude'] : double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: json['longitude'] is double ? json['longitude'] : double.tryParse(json['longitude'].toString()) ?? 0.0,
      contactNumber: json['contactNumber'],
      patientName: json['patientName'],
      urgency: json['urgency'],
      createdAt: json['createdAt'] is DateTime
          ? json['createdAt']
          : (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'],
      acceptedBy: json['acceptedBy'],
      userEmail: json['userEmail'],
    );
  }
}
