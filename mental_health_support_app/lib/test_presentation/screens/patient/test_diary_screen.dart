import 'package:flutter/material.dart';
import '../../../core/models/app_user.dart';
import '../../../core/controllers/patient_controller.dart';
import '../../components/test_button.dart';
import '../../components/test_section_title.dart';

class TestDiaryScreen extends StatefulWidget {
  final AppUser user;
  const TestDiaryScreen({super.key, required this.user});

  @override
  State<TestDiaryScreen> createState() => _TestDiaryScreenState();
}

class _TestDiaryScreenState extends State<TestDiaryScreen> {
  final _ctrl    = TextEditingController();
  bool  _saving  = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await PatientController.saveDiaryEntry(
        widget.user.uid, _ctrl.text.trim());
    _ctrl.clear();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Diary entry saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('[TEST] Diary'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TestSectionTitle(
              title: 'Write Your Thoughts',
              subtitle: 'Stored for future AI analysis',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines:   null,
                expands:    true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText:    'What\'s on your mind today?',
                  filled:      true,
                  fillColor:   Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TestButton(
              label:     'Save Entry',
              onPressed: _save,
              isLoading: _saving,
              color:     Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}