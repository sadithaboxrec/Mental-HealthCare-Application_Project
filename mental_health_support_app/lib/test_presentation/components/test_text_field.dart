import 'package:flutter/material.dart';

class TestTextField extends StatefulWidget {
  final String                  label;
  final TextEditingController   controller;
  final bool                    isPassword;
  final TextInputType           keyboardType;
  final String?                 hint;
  final String? Function(String?)? validator;

  const TestTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword   = false,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.validator,
  });

  @override
  State<TestTextField> createState() => _TestTextFieldState();
}

class _TestTextFieldState extends State<TestTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   widget.controller,
      obscureText:  widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      validator:    widget.validator,
      decoration: InputDecoration(
        labelText:   widget.label,
        hintText:    widget.hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        filled:      true,
        fillColor:   Colors.white,
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
      ),
    );
  }
}