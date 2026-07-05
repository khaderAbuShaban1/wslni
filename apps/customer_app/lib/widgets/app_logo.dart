import 'package:flutter/material.dart';

import '../utils/constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: emerald,
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Icon(Icons.near_me_rounded, color: Colors.white, size: size * .52),
    );
  }
}
