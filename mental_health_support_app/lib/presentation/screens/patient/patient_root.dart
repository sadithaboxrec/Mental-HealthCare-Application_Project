import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import 'patient_home.dart';
import 'patient_medications.dart';
import 'patient_appointments.dart';
import 'patient_profile.dart';

class PatientRoot extends StatefulWidget {
  final AppUser user;
  const PatientRoot({super.key, required this.user});

  @override
  State<PatientRoot> createState() => _PatientRootState();
}

class _PatientRootState extends State<PatientRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      PatientHome(user: widget.user),
      PatientMedications(user: widget.user),
      PatientAppointments(user: widget.user),
      PatientProfile(user: widget.user),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.medication_rounded, label: 'Medicines'),
    _NavItem(icon: Icons.calendar_today, label: 'Appointments'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1976D2).withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          item.icon,
                          size: 22,
                          color: selected
                              ? const Color(0xFF1976D2)
                              : const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? const Color(0xFF1976D2)
                              : const Color(0xFF1C1C1E),
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
