import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/app_user.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../components/test_section_title.dart';

class TestPatientProfile extends StatefulWidget {
  final AppUser user;
  const TestPatientProfile({super.key, required this.user});

  @override
  State<TestPatientProfile> createState() => _TestPatientProfileState();
}

class _TestPatientProfileState extends State<TestPatientProfile> {
  Map<String,dynamic>? _patientData;
  String               _doctorName = '';
  bool                 _loading    = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients').doc(widget.user.uid).get();
      if (doc.exists) {
        _patientData = doc.data();
        final drUid = _patientData?['assignedDoctor'] as String? ?? '';
        if (drUid.isNotEmpty) {
          final drDoc = await FirebaseFirestore.instance
              .collection('users').doc(drUid).get();
          _doctorName = drDoc.data()?['name'] as String? ?? '';
        }
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthController.logout();
              if (context.mounted) NavigationHelper.goToLogin(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(widget.user.name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Center(child: Text(widget.user.role.toUpperCase(),
              style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1))),

          const SizedBox(height: 24),
          const TestSectionTitle(title: 'Personal Details'),

          _row('Email',       widget.user.email),
          _row('Phone',       widget.user.phone.isEmpty
              ? '—' : widget.user.phone),
          _row('Gender',      _patientData?['gender'] ?? '—'),
          _row('Date of Birth', _patientData?['dob'] ?? '—'),
          _row('Employment',  _patientData?['employeeStatus'] ?? '—'),

          const SizedBox(height: 16),
          const TestSectionTitle(title: 'Medical'),
          _row('Assigned Doctor',
              _doctorName.isEmpty ? '—' : 'Dr. $_doctorName'),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    margin:  const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color:        Colors.white,
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: Colors.grey.shade200),
    ),
    child: Row(children: [
      SizedBox(width: 120,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w500))),
    ]),
  );
}