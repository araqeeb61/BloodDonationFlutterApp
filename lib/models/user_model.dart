class UserModel {
  final String id;
  final String name;
  final String email;
  final String bloodGroup;
  final String phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.bloodGroup,
    required this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bloodGroup': bloodGroup,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      bloodGroup: json['bloodGroup'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
