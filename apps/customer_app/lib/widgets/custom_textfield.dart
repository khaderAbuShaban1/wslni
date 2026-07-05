import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.onSubmitted,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      maxLength: maxLength,
      textAlign: textAlign,
      style: style,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: maxLength == null ? null : '',
        prefixIcon: Icon(icon),
      ),
    );
  }
}
