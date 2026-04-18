import 'package:flutter/material.dart';
import 'common_card.dart';

class SummaryCard extends StatelessWidget {
  final double mood;
  final int water;
  final bool? taken;

  const SummaryCard({
    super.key,
    required this.mood,
    required this.water,
    required this.taken,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item("Mood", Icons.mood, Colors.orange),
          _item("Water", Icons.local_drink, Colors.blue),
          _item(
            "Meds",
            taken == true ? Icons.check_circle : Icons.cancel,
            taken == true ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _item(String t, IconData i, Color c) {
    return Column(
      children: [
        Icon(i, color: c),
        const SizedBox(height: 6),
        Text(t),
      ],
    );
  }
}

//end of file mishara