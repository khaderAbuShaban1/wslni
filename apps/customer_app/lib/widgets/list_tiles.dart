import 'package:flutter/material.dart';

import 'premium_card.dart';

class QuickActionRow extends StatelessWidget {
  const QuickActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      padding: 14,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primary.withValues(alpha: .15),
              child: Icon(icon, color: scheme.primary, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class RecentTripCard extends StatelessWidget {
  const RecentTripCard({required this.route, required this.date, super.key});

  final String route;
  final String date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: 14,
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primary.withValues(alpha: .15),
              child: Icon(Icons.route_rounded, color: scheme.primary, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
