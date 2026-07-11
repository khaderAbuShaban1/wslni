import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';

class TripCompletedScreen extends StatefulWidget {
  const TripCompletedScreen({required this.draft, super.key});

  final RideDraft draft;

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'اكتملت الرحلة',
      child: Column(
        children: [
          PremiumCard(
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'وصلت بالسلامة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.draft.destination,
                  style: const TextStyle(color: mutedText),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'العودة للرئيسية',
            icon: Icons.home_rounded,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
