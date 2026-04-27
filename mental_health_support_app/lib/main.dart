import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/controllers/notification_controller.dart';
import 'firebase_options.dart';
import 'core/controllers/auth_controller.dart';
import 'core/navigation/navigation_helper.dart';
import 'core/services/phenotyping_service.dart';
import 'test_presentation/screens/test_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // for notifiations
  await NotificationController.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _collectResumeSignals();
    }
  }

  Future<void> _collectResumeSignals() async {
    final user = await AuthController.restoreSession();
    if (user == null) return;
    await PhenotypingService.collectStartupSignals(user);
  }

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
      Future<void>.microtask(() => PhenotypingService.collectStartupSignals(user));
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
