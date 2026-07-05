import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/driver_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/driver_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/ride_card.dart';
import '../widgets/section_header.dart';
import 'ride_confirmation_screen.dart';

class DriverOffersScreen extends StatelessWidget {
  const DriverOffersScreen({
    required this.draft,
    this.driverService = const DriverService(),
    super.key,
  });

  final RideDraft draft;
  final DriverService driverService;

  @override
  Widget build(BuildContext context) {
    final offers = driverService.currentOffers();

    return AppScaffold(
      title: 'عروض السائقين',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RouteSummary(pickup: draft.pickup, destination: draft.destination),
          const SizedBox(height: 22),
          const SectionHeader(title: 'اختر أفضل عرض'),
          const SizedBox(height: 12),
          if (offers.isEmpty)
            const EmptyStateCard(
              icon: Icons.local_taxi_outlined,
              title: 'لا توجد عروض بعد',
              message: 'عندما يرسل السائقون أسعارهم ستظهر هنا فورًا.',
            )
          else
            for (final offer in offers) ...[
              DriverCard(
                offer: offer,
                selectedRide: draft.rideName,
                onChoose: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        RideConfirmationScreen(draft: draft, offer: offer),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
