import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import 'test_doctor_home.dart';
import 'test_doctor_schedule.dart';
import 'test_doctor_patients.dart';

class TestDoctorRoot extends StatefulWidget {
  final AppUser user;
  const TestDoctorRoot({super.key, required this.user});

  @override
  State<TestDoctorRoot> createState() => _TestDoctorRootState();
}

class _TestDoctorRootState extends State<TestDoctorRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TestDoctorHome(user: widget.user),
      TestDoctorSchedule(user: widget.user),
      TestDoctorPatients(user: widget.user),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor:   Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Patients'),
        ],
      ),
    );
  }
}