import 'package:flutter/material.dart';

class SaveIndicator extends StatelessWidget {
  final bool saving;
  final bool saved;

  const SaveIndicator({super.key, required this.saving, required this.saved});

  @override
  Widget build(BuildContext context) {
    if (saving) {
      return const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A90D9)),
      );
    }
    if (saved) {
      return const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 18),
        SizedBox(width: 4),
        Text('Saved', style: TextStyle(fontSize: 12, color: Color(0xFF2ECC71))),
      ]);
    }
    return const SizedBox.shrink();
  }
}
//end of file mishara