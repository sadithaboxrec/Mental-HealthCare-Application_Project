import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/controllers/auth_controller.dart';
import 'core/navigation/navigation_helper.dart';
import 'test_presentation/screens/test_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health App',
      debugShowCheckedModeBanner: false,
      home: const AppStartup(),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await AuthController.restoreSession();
    if (!mounted) return;

    if (user != null) {
      NavigationHelper.goToRoleScreen(context, user);
    } else {
      NavigationHelper.goToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown while session check runs
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}