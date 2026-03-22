import 'package:flutter/material.dart';
import '../../core/models/app_user.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/navigation/navigation_helper.dart';
import '../components/test_button.dart';

class TestDoctorScreen extends StatelessWidget {
  final AppUser user;
  const TestDoctorScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[TEST] Doctor'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TestInfoRow('Role',  user.role),
            _TestInfoRow('Name',  user.name),
            _TestInfoRow('Email', user.email),
            _TestInfoRow('UID',   user.uid),
            const SizedBox(height: 24),
            TestButton(
              label: 'Logout',
              color: Colors.red,
              onPressed: () async {
                await AuthController.logout();
                if (context.mounted) {
                  NavigationHelper.goToLogin(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TestInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _TestInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 60,
          child: Text('$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}