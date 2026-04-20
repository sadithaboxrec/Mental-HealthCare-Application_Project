import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import 'doctor_home.dart';
import 'doctor_schedule.dart';
import 'doctor_patients.dart';
import '../../components/app_button.dart';
import '../../components/section_title.dart';
import '../../components/app_text_field.dart';

class DoctorRoot extends StatefulWidget {
  final AppUser user;
  const DoctorRoot({super.key, required this.user});
 
  @override
  State<DoctorRoot> createState() => _DoctorRootState();
}
 
class _DoctorRootState extends State<DoctorRoot> {
  int _index = 0;
 
  @override
  Widget build(BuildContext context) {
    final screens = [
      DoctorHome(user: widget.user),
      DoctorSchedule(user: widget.user),
      DoctorPatients(user: widget.user),
 
      // Messages Screen (to be replaced later)
      const Center(
        child: Text(
          "Messages Screen",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
    ];
 
    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[_index],
      bottomNavigationBar: _FloatingDoctorNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
 
class _FloatingDoctorNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
 
  const _FloatingDoctorNavBar({
    required this.currentIndex,
    required this.onTap,
  });
 
  static const _items = [
    _NavItem(icon: Icons.home_rounded,                label: 'Home'),
    _NavItem(icon: Icons.calendar_month_outlined,     label: 'schedule'),
    _NavItem(icon: Icons.groups_rounded,              label: 'patients'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages'),
  ];
 
  static const _activeColor   = Color(0xFF4FC3F7);
  static const _inactiveColor = Color(0xFF1C1C1E);
 
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item       = _items[i];
              final isSelected = i == currentIndex;
 
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? _activeColor : _inactiveColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? _activeColor : _inactiveColor,
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
  final String   label;
  const _NavItem({required this.icon, required this.label});
}
 