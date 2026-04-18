import 'package:flutter/material.dart';
import '../../../components/section_title.dart';
import 'common_card.dart';
import 'save_indicator.dart';

class ObservationsSection extends StatelessWidget {
  final TextEditingController controller;
  final bool saving;
  final bool saved;
  final VoidCallback onSave;

  const ObservationsSection({
    super.key,
    required this.controller,
    required this.saving,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Observations',
            subtitle: 'Write notes about patient condition',
            trailing: SaveIndicator(saving: saving, saved: saved),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter observations...',
              hintStyle: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFDEEDFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFBDD7F8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFBDD7F8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 1.8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(saving ? 'Saving...' : 'Save Observations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//end of file mishara