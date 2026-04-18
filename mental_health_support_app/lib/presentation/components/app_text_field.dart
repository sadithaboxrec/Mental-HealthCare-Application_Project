import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final String                     label;
  final TextEditingController      controller;
  final bool                       isPassword;
  final TextInputType              keyboardType;
  final String?                    hint;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword   = false,
    this.keyboardType = TextInputType.text,
    this.hint,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  static const Color _primary  = Color(0xFF4A90D9);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _grey     = Color(0xFF8A8A9A);
  static const Color _fill     = Color(0xFFDEEDFC);
  static const Color _border   = Color(0xFFBDD7F8);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   widget.controller,
      obscureText:  widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      validator:    widget.validator,
      style: const TextStyle(fontSize: 14, color: _textDark),
      decoration: InputDecoration(
        labelText:  widget.label,
        hintText:   widget.hint,
        labelStyle: const TextStyle(color: _grey, fontSize: 14),
        hintStyle:  const TextStyle(color: _grey, fontSize: 13),
        filled:     true,
        fillColor:  _fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.8),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: _grey, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
//end of file mishara