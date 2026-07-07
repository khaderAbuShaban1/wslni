import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/realtime_ride_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_card.dart';
import 'driver_offers_screen.dart';

class TripHistoryScreen extends StatelessWidget {
  TripHistoryScreen({
    required this.user,
    this.showBack = true,
    RealtimeRideService? realtimeService,
    super.key,
  }) : realtimeService = realtimeService ?? RealtimeRideService();

  final AppUser user;
  final bool showBack;
  final RealtimeRideService realtimeService;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'سجل الرحلات',
      showBack: showBack,
      child: StreamBuilder<List<RideDraft>>(
        stream: realtimeService.watchCustomerRides(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data ?? const <RideDraft>[];
          if (rides.isEmpty) {
            return const EmptyStateCard(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد رحلات بعد',
              message: 'لما تعمل طلب رحلة، سيظهر هنا بحالة بانتظار العروض.',
            );
          }

          return Column(
            children: [
              for (final ride in rides) ...[
                _CustomerRideCard(ride: ride),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CustomerRideCard extends StatelessWidget {
  const _CustomerRideCard({required this.ride});

  final RideDraft ride;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.local_taxi_rounded, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.rideName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.statusLabel,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _OffersBadge(count: ride.offersCount),
            ],
          ),
          const Divider(height: 24),
          _RouteText(label: 'من', value: ride.pickup),
          const SizedBox(height: 8),
          _RouteText(label: 'إلى', value: ride.destination),
          const SizedBox(height: 16),
          CustomButton(
            label: ride.offersCount == 0
                ? 'بانتظار عروض السائقين'
                : 'مشاهدة العروض',
            icon: Icons.local_offer_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DriverOffersScreen(draft: ride),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersBadge extends StatelessWidget {
  const _OffersBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count عروض',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  const _RouteText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF6B7280))),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
