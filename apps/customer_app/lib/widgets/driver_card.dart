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
    super.key,
  });

  final DriverOffer offer;
  final String selectedRide;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: lightGray,
                child: Icon(Icons.person_rounded, color: emerald),
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
                      style: const TextStyle(color: mutedText),
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
                  Text(selectedRide, style: const TextStyle(color: mutedText)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'اختيار العرض',
            icon: Icons.check_rounded,
            onPressed: onChoose,
          ),
        ],
      ),
    );
  }
}
