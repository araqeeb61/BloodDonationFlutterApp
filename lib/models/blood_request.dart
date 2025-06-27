
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
  final double? donorLatitude;  // New field for donor's current latitude
  final double? donorLongitude; // New field for donor's current longitude
  final DateTime? lastLocationUpdate; // New field for tracking when location was last updated

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
    this.donorLatitude,
    this.donorLongitude,
    this.lastLocationUpdate,
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
      'donorLatitude': donorLatitude,
      'donorLongitude': donorLongitude,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
    };
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bloodGroup: json['bloodGroup'] as String,
      hospital: json['hospital'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      contactNumber: json['contactNumber'] as String,
      patientName: json['patientName'] as String,
      urgency: json['urgency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      acceptedBy: json['acceptedBy'] as String?,
      userEmail: json['userEmail'] as String?,
      donorLatitude: json['donorLatitude'] != null ? (json['donorLatitude'] as num).toDouble() : null,
      donorLongitude: json['donorLongitude'] != null ? (json['donorLongitude'] as num).toDouble() : null,
      lastLocationUpdate: json['lastLocationUpdate'] != null ? DateTime.parse(json['lastLocationUpdate'] as String) : null,
    );
  }
}
