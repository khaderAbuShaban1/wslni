import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الدعم',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .15),
                  child: Icon(Icons.support_agent_rounded, color: emerald),
                ),
                const SizedBox(height: 16),
                Text(
                  'كيف نقدر نساعدك؟',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'لأي مشكلة في الطلب أو الدفع أو التواصل مع السائق، تواصل معنا مباشرة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText, height: 1.5),
                ),
                const SizedBox(height: 18),
                OutlinedActionButton(
                  icon: Icons.call_rounded,
                  label: 'اتصال بالدعم',
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                OutlinedActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'مراسلة الدعم',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
