import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, const Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .26),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Icon(Icons.near_me_rounded, color: Colors.white, size: size * .52),
    );
  }
}
