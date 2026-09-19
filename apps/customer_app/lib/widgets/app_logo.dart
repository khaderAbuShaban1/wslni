import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/wslni_customer_logo.png',
      width: size,
      fit: BoxFit.contain,
    );
  }
}
