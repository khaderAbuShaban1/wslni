import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'premium_card.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: lightGray,
            child: Icon(icon, color: emerald, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedText, height: 1.5),
          ),
        ],
      ),
    );
  }
}
