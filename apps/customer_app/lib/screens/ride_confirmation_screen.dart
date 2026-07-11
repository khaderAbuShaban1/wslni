import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_card.dart';
import 'trip_progress_screen.dart';

class RideConfirmationScreen extends StatelessWidget {
  const RideConfirmationScreen({
    required this.draft,
    required this.offer,
    super.key,
  });

  final RideDraft draft;
  final DriverOffer offer;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تم العثور على سائق',
      child: Column(
        children: [
          PremiumCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .15),
                      child: Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(offer.rating),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SummaryRow(label: 'نوع المركبة', value: offer.car),
                SummaryRow(label: 'الوصول المتوقع', value: offer.eta),
                SummaryRow(
                  label: 'السعر المتفق عليه',
                  value: '${offer.price} دولار',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedActionButton(
                        icon: Icons.call_rounded,
                        label: 'اتصال',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'محادثة',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'متابعة الرحلة',
            icon: Icons.timeline_rounded,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TripProgressScreen(draft: draft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
