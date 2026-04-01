import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import 'test_patient_home.dart';
import 'test_patient_medications.dart';
import 'test_patient_appointments.dart';
import 'test_patient_profile.dart';

class TestPatientRoot extends StatefulWidget {
  final AppUser user;
  const TestPatientRoot({super.key, required this.user});

  @override
  State<TestPatientRoot> createState() => _TestPatientRootState();
}

class _TestPatientRootState extends State<TestPatientRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TestPatientHome(user: widget.user),
      TestPatientMedications(user: widget.user),
      TestPatientAppointments(user: widget.user),
      TestPatientProfile(user: widget.user),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor:   Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Medicines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}