import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../models/user_model.dart';
import '../services/realtime_ride_service.dart';
import '../services/ride_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_card.dart';
import '../widgets/skeleton_loader.dart';
import 'driver_offers_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  TripHistoryScreen({
    required this.user,
    this.showBack = true,
    RideService? rideService,
    RealtimeRideService? realtimeService,
    super.key,
  }) : rideService = rideService ?? RideService(),
       realtimeService = realtimeService ?? RealtimeRideService();

  final AppUser user;
  final bool showBack;
  final RideService rideService;
  final RealtimeRideService realtimeService;

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  late Future<List<RideDraft>> _databaseRides;
  late Stream<List<RideDraft>> _realtimeRides;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  @override
  void didUpdateWidget(covariant TripHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _loadRides();
    }
  }

  void _loadRides() {
    _databaseRides = widget.rideService.listCustomerRides(widget.user.id);
    _realtimeRides = widget.realtimeService.watchCustomerRides(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'سجل الرحلات',
      showBack: widget.showBack,
      child: FutureBuilder<List<RideDraft>>(
        future: _databaseRides,
        builder: (context, databaseSnapshot) {
          final databaseRides = databaseSnapshot.data ?? const <RideDraft>[];

          if (databaseSnapshot.connectionState == ConnectionState.waiting &&
              databaseRides.isEmpty) {
            return const SkeletonList();
          }

          return StreamBuilder<List<RideDraft>>(
            stream: _realtimeRides,
            builder: (context, realtimeSnapshot) {
              final realtimeRides =
                  realtimeSnapshot.data ?? const <RideDraft>[];
              final rides = _mergeRides(databaseRides, realtimeRides);

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
          );
        },
      ),
    );
  }

  List<RideDraft> _mergeRides(
    List<RideDraft> databaseRides,
    List<RideDraft> realtimeRides,
  ) {
    final byId = <int, RideDraft>{};
    for (final ride in databaseRides) {
      byId[ride.id] = ride;
    }
    for (final ride in realtimeRides) {
      byId[ride.id] = ride;
    }
    return byId.values.toList()..sort((a, b) => b.id.compareTo(a.id));
  }
}

class _CustomerRideCard extends StatelessWidget {
  const _CustomerRideCard({required this.ride});

  final RideDraft ride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: scheme.primary.withValues(alpha: .15),
                child: Icon(Icons.local_taxi_rounded, color: scheme.primary),
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
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
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
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .16),
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
        Text(
          '$label: ',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
