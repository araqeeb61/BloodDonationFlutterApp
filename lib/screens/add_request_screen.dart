import 'package:flutter/material.dart';

class AddRequestScreen extends StatefulWidget {
  const AddRequestScreen({super.key});

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

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> hospitals = ['City Hospital', 'General Hospital', 'Red Cross', 'Community Clinic'];
  final List<String> urgencies = ['Low', 'Medium', 'High'];

  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Save request to Firestore
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Blood Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
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
              DropdownButtonFormField<String>(
                value: _selectedHospital,
                items: hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                onChanged: (val) => setState(() => _selectedHospital = val),
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
      ),
    );
  }
}
