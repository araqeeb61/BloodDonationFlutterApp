import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/user_name_banner.dart';

class AddRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? requestData;
  final String? requestId;
  const AddRequestScreen({super.key, this.requestData, this.requestId});

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  String? _selectedBloodGroup;
  String? _selectedHospital;
  String? _selectedUrgency;
  String? _selectedHospitalId;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<String> hospitals = [];
  List<Map<String, dynamic>> hospitalDocs = [];
  final List<String> urgencies = ['Low', 'Medium', 'High'];

  bool _isLoading = false;
  bool _hospitalsLoading = true;
  String? _hospitalsError;

  Future<bool> _ensureUserProfileExists(User user) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      // Try to create the user profile from available info
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'phone': user.phoneNumber,
        'createdAt': DateTime.now(),
      });
      return true;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
    if (widget.requestData != null) {
      final data = widget.requestData!;
      _patientNameController.text = data['patientName'] ?? '';
      _contactController.text = data['contactNumber'] ?? '';
      _selectedBloodGroup = data['bloodGroup'];
      _selectedHospital = data['hospital'];
      _selectedUrgency = data['urgency'];
    }
  }

  Future<void> _fetchHospitals() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('hospitals').get();
      setState(() {
        print(snapshot.docs.length);
        hospitalDocs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        hospitals = hospitalDocs
            .where((h) => h['name'] != null && h['name'].toString().trim().isNotEmpty)
            .map((h) => h['name'].toString())
            .toList();
            
        // If only one hospital, select it by default
        if (hospitals.isNotEmpty && _selectedHospital == null) {
          _selectedHospital = hospitals.first;
          _selectedHospitalId = hospitalDocs.firstWhere((h) => h['name'] == _selectedHospital)['id'];
        }
        _hospitalsLoading = false;
        _hospitalsError = null;
      });
    } catch (e) {
      setState(() {
        _hospitalsLoading = false;
        _hospitalsError = 'Failed to load hospitals: ${e is Exception ? e.toString() : 'Unknown error'}';
      });
    }
  }

  void _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    print('DEBUG: Current user: ${user?.toString() ?? 'null'}');
    print('DEBUG: Current user email: ${user?.email ?? 'null'}');
    print('DEBUG: Current user phone: ${user?.phoneNumber ?? 'null'}');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create a request.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Ensure user profile exists in Firestore
    await _ensureUserProfileExists(user);
    String? userEmail = user.email;
    final String? userPhone = user.phoneNumber;
    // Fetch user's name from Firestore
    String? userName;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!['name'] != null) {
      userName = userDoc.data()!['name'];
    }
    // If email is not available, try to fetch from Firestore user profile
    if (userEmail == null || userEmail.isEmpty) {
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!['email'] != null) {
        userEmail = userDoc.data()!['email'];
        print('DEBUG: Got user email from Firestore: ${userEmail!}');
      }
    }
    if ((userEmail == null || userEmail.isEmpty) && (userPhone == null || userPhone.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email or phone found for your account. Please contact support.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final String requestId = widget.requestId ?? const Uuid().v4();
      final String userId = user.uid;
      try {
        final now = DateTime.now();
        // Fetch hospital coordinates from hospitalDocs
        double latitude = 0.0;
        double longitude = 0.0;
        if (_selectedHospital != null) {
          final hospital = hospitalDocs.firstWhere(
            (h) => h['name'] == _selectedHospital,
            orElse: () => {},
          );
          latitude = (hospital['latitude'] is num)
              ? hospital['latitude'].toDouble()
              : double.tryParse(hospital['latitude']?.toString() ?? '') ?? 0.0;
          longitude = (hospital['longitude'] is num)
              ? hospital['longitude'].toDouble()
              : double.tryParse(hospital['longitude']?.toString() ?? '') ?? 0.0;
        }
        final data = {
          'acceptedBy': null,
          'bloodGroup': _selectedBloodGroup ?? '',
          'contactNumber': _contactController.text.trim(),
          'createdAt': now,
          'hospital': _selectedHospital ?? '',
          'hospitalId': _selectedHospitalId ?? '',
          'id': requestId,
          'isActive': true,
          'latitude': latitude,
          'longitude': longitude,
          'patientName': _patientNameController.text.trim(),
          'urgency': _selectedUrgency ?? '',
          'userId': userId,
        };
        if (userEmail != null && userEmail.isNotEmpty) {
          data['userEmail'] = userEmail;
        }
        if (userPhone != null && userPhone.isNotEmpty) {
          data['userPhone'] = userPhone;
        }
        if (userName != null && userName.isNotEmpty) {
          data['userName'] = userName;
        }
        if (widget.requestId != null) {
          // Update existing request
          await FirebaseFirestore.instance.collection('blood_requests').doc(widget.requestId).update(data);
        } else {
          // Create new request
          await FirebaseFirestore.instance.collection('blood_requests').doc(requestId).set(data);
        }
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.requestId != null ? 'Request updated successfully!' : 'Blood request submitted successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Blood Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UserNameBanner(),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    items: bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                    onChanged: (val) => setState(() => _selectedBloodGroup = val),
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bloodtype),
                    ),
                    validator: (val) => val == null ? 'Select blood group' : null,
                  ),
                  const SizedBox(height: 16),
                  _hospitalsLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hospitalsError != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(_hospitalsError!, style: const TextStyle(color: Colors.red)),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedHospital,
                              items: hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedHospital = val;
                                  final found = hospitalDocs.firstWhere((h) => h['name'] == val, orElse: () => {});
                                  _selectedHospitalId = found['id'];
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Hospital',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_hospital),
                              ),
                              validator: (val) => val == null ? 'Select hospital' : null,
                            ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) => val != null && val.isNotEmpty ? null : 'Enter patient name',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUrgency,
                    items: urgencies.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUrgency = val),
                    decoration: const InputDecoration(
                      labelText: 'Urgency',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    validator: (val) => val == null ? 'Select urgency' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val != null && val.length >= 10 ? null : 'Enter valid contact number',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Request', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
