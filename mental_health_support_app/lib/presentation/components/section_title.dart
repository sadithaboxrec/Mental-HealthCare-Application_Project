import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final Color   color;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.color    = const Color(0xFF1A1A2E),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.w800,
                    color:      color,
                    height:     1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 12,
                        color:    Color(0xFF8A8A9A),
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
//end of file mishara