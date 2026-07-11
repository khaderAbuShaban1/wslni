import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../utils/constants.dart';
import 'custom_button.dart';
import 'premium_card.dart';

class DriverCard extends StatelessWidget {
  const DriverCard({
    required this.offer,
    required this.selectedRide,
    required this.onChoose,
    this.choosing = false,
    super.key,
  });

  final DriverOffer offer;
  final String selectedRide;
  final VoidCallback? onChoose;
  final bool choosing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${offer.car} • ${offer.rating} • ${offer.eta}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer.price}\$',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: emerald,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    selectedRide,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: choosing ? 'جاري قبول العرض...' : 'اختيار العرض',
            icon: choosing ? Icons.hourglass_top_rounded : Icons.check_rounded,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}
