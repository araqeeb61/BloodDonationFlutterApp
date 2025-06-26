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
    };
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'],
      userId: json['userId'],
      bloodGroup: json['bloodGroup'],
      hospital: json['hospital'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      contactNumber: json['contactNumber'],
      patientName: json['patientName'],
      urgency: json['urgency'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
      acceptedBy: json['acceptedBy'],
    );
  }
}
