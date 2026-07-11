import 'package:flutter/material.dart';

import 'premium_card.dart';

class RouteSummary extends StatelessWidget {
  const RouteSummary({
    required this.pickup,
    required this.destination,
    super.key,
  });

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          _RouteLine(
            icon: Icons.my_location_rounded,
            label: 'من',
            value: pickup,
          ),
          const Divider(height: 24),
          _RouteLine(
            icon: Icons.place_outlined,
            label: 'إلى',
            value: destination,
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    super.key,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
                fontSize: strong ? 18 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
