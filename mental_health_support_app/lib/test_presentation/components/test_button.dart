import 'package:flutter/material.dart';

class TestButton extends StatelessWidget {
  final String       label;
  final VoidCallback? onPressed;
  final bool         isLoading;
  final Color        color;
  final bool         outlined;

  const TestButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color     = Colors.teal,
    this.outlined  = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label,
        style: TextStyle(
          color:      outlined ? color : Colors.white,
          fontWeight: FontWeight.w600,
        ));

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: outlined
          ? OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side:  BorderSide(color: color),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        child: child,
      )
          : ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        child: child,
      ),
    );
  }
}