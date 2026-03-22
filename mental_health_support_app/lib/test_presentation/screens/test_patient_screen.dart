import 'package:flutter/material.dart';
import '../../core/models/app_user.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/navigation/navigation_helper.dart';
import '../components/test_button.dart';

class TestPatientScreen extends StatelessWidget {
  final AppUser user;
  const TestPatientScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('[TEST] Patient'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Role',  user.role),
            _row('Name',  user.name),
            _row('Email', user.email),
            _row('UID',   user.uid),
            const SizedBox(height: 24),
            TestButton(
              label: 'Logout',
              color: Colors.red,
              onPressed: () async {
                await AuthController.logout();
                if (context.mounted) NavigationHelper.goToLogin(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 60,
          child: Text('$label:',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13))),
      Text(value, style: const TextStyle(fontSize: 13)),
    ]),
  );
}