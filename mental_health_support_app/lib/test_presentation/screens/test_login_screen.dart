import 'package:flutter/material.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../components/test_button.dart';
import '../components/test_text_field.dart';

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool    _loading    = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthController.login(
      _emailCtrl.text,
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() { _loading = false; });

    if (result.isSuccess) {
      NavigationHelper.goToRoleScreen(context, result.user!);
    } else {
      setState(() { _error = result.error; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                // ── Test UI indicator ──────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('[TEST UI]',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      )),
                ),

                const SizedBox(height: 16),
                const Text('Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 24),

                TestTextField(
                  label:        'Email',
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TestTextField(
                  label:      'Password',
                  controller: _passwordCtrl,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Error message
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),

                const SizedBox(height: 16),

                TestButton(
                  label:     'Login',
                  onPressed: _login,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}