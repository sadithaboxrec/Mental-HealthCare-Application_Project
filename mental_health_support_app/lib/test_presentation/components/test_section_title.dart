import 'package:flutter/material.dart';

class TestSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const TestSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}