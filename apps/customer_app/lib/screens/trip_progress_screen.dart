import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/realtime_ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_card.dart';
import 'trip_completed_screen.dart';
import 'driver_offers_screen.dart';

class TripProgressScreen extends StatelessWidget {
  TripProgressScreen({required this.draft, super.key});

  final RideDraft draft;
  final RealtimeRideService _realtime = RealtimeRideService();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: StreamBuilder<RideDraft?>(
        stream: _realtime.watchRide(draft.id),
        initialData: draft,
        builder: (context, snapshot) {
          final ride = snapshot.data ?? draft;
          return AppScaffold(
            showBack: false,
            title: 'حالة الرحلة',
            child: Column(
              children: [
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.statusLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage(ride.status),
                        style: const TextStyle(color: mutedText),
                      ),
                      if (ride.driverName.isNotEmpty) ...[
                        const Divider(height: 28),
                        SummaryRow(label: 'السائق', value: ride.driverName),
                        SummaryRow(
                          label: 'الهاتف',
                          value: ride.driverPhone.isEmpty
                              ? 'غير متوفر'
                              : ride.driverPhone,
                        ),
                        SummaryRow(
                          label: 'السيارة',
                          value: [
                            ride.driverCar,
                            ride.driverPlate,
                          ].where((value) => value.isNotEmpty).join(' - '),
                        ),
                      ],
                      const Divider(height: 28),
                      SummaryRow(label: 'من', value: ride.pickup),
                      SummaryRow(label: 'إلى', value: ride.destination),
                    ],
                  ),
                ),
                if (ride.status == RideStatuses.tripCompleted) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => TripCompletedScreen(draft: ride),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline_rounded),
                    label: const Text('عرض الملخص وتقييم السائق'),
                  ),
                ],
                if (ride.status == RideStatuses.receivingOffers) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DriverOffersScreen(
                          draft: ride,
                          lockNavigation: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('اختيار سائق آخر'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusMessage(String status) => switch (status) {
    RideStatuses.driverSelected => 'تم إرسال طلب تأكيد إلى السائق.',
    RideStatuses.driverConfirmed => 'أكد السائق الرحلة وسيبدأ التحرك قريبًا.',
    RideStatuses.driverOnTheWay => 'السائق في الطريق إلى نقطة الانطلاق.',
    RideStatuses.driverArrived => 'وصل السائق. يرجى التوجه إلى المركبة.',
    RideStatuses.tripStarted => 'الرحلة قيد التنفيذ.',
    RideStatuses.tripCompleted => 'اكتملت الرحلة. يمكنك الآن تقييم السائق.',
    RideStatuses.receivingOffers => 'رفض السائق الطلب. يمكنك اختيار عرض آخر.',
    _ => 'يتم تحديث حالة الرحلة تلقائيًا.',
  };
}
