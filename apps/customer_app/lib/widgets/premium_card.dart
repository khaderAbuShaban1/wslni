import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.child, this.padding = 18, super.key});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x38000000) : const Color(0x14000000),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
