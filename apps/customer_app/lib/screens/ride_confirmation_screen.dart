import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../services/realtime_ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_card.dart';
import 'driver_offers_screen.dart';
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
    return PopScope(
      canPop: false,
      child: StreamBuilder<RideDraft?>(
        stream: RealtimeRideService().watchRide(draft.customerId, draft.id),
        initialData: draft,
        builder: (context, snapshot) {
          final ride = snapshot.data ?? draft;
          final rejected = ride.status == RideStatuses.receivingOffers;

          return AppScaffold(
            showBack: false,
            title: rejected ? 'اختر سائقًا آخر' : 'متابعة تأكيد السائق',
            child: Column(
              children: [
                PremiumCard(
                  child: Column(
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
                      const SizedBox(height: 12),
                      Text(
                        ride.driverName.isEmpty ? offer.name : ride.driverName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ride.statusLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Divider(height: 28),
                      SummaryRow(
                        label: 'نوع المركبة',
                        value: ride.driverCar.isEmpty
                            ? offer.car
                            : ride.driverCar,
                      ),
                      SummaryRow(
                        label: 'رقم السيارة',
                        value: ride.driverPlate.isEmpty
                            ? offer.vehiclePlate
                            : ride.driverPlate,
                      ),
                      SummaryRow(
                        label: 'الهاتف',
                        value: ride.driverPhone.isEmpty
                            ? offer.phone
                            : ride.driverPhone,
                      ),
                      SummaryRow(label: 'السعر', value: offer.price),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: rejected ? 'مشاهدة العروض المتاحة' : 'متابعة الرحلة',
                  icon: rejected
                      ? Icons.local_offer_outlined
                      : Icons.timeline_rounded,
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => rejected
                          ? DriverOffersScreen(
                              draft: ride,
                              lockNavigation: true,
                            )
                          : TripProgressScreen(draft: ride),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
