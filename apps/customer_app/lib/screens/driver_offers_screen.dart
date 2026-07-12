import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../services/api_client.dart';
import '../services/driver_service.dart';
import '../services/realtime_ride_service.dart';
import '../services/ride_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/driver_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/ride_card.dart';
import '../widgets/section_header.dart';
import 'ride_confirmation_screen.dart';

class DriverOffersScreen extends StatefulWidget {
  DriverOffersScreen({
    required this.draft,
    this.driverService = const DriverService(),
    RideService? rideService,
    RealtimeRideService? realtimeService,
    this.lockNavigation = false,
    super.key,
  }) : rideService = rideService ?? RideService(),
       realtimeService = realtimeService ?? RealtimeRideService();

  final RideDraft draft;
  final DriverService driverService;
  final RideService rideService;
  final RealtimeRideService realtimeService;
  final bool lockNavigation;

  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  int? _acceptingDriverId;

  Future<void> _acceptOffer(DriverOffer offer) async {
    setState(() => _acceptingDriverId = offer.driverId);
    try {
      final acceptedRide = await widget.rideService.acceptOffer(
        ride: widget.draft,
        offer: offer,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              RideConfirmationScreen(draft: acceptedRide, offer: offer),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'تعذر قبول العرض. حاول مرة أخرى.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _acceptingDriverId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.lockNavigation,
      child: AppScaffold(
        showBack: !widget.lockNavigation,
        title: 'عروض السائقين',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteSummary(
              pickup: widget.draft.pickup,
              destination: widget.draft.destination,
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'اختر أفضل عرض'),
            const SizedBox(height: 12),
            StreamBuilder<List<DriverOffer>>(
              stream: widget.realtimeService.watchOffers(widget.draft.id),
              builder: (context, snapshot) {
                final offers =
                    snapshot.data ?? widget.driverService.currentOffers();

                if (offers.isEmpty) {
                  return const EmptyStateCard(
                    icon: Icons.local_taxi_outlined,
                    title: 'لا توجد عروض بعد',
                    message: 'عندما يرسل السائقون أسعارهم ستظهر هنا فورًا.',
                  );
                }

                return Column(
                  children: [
                    for (final offer in offers) ...[
                      DriverCard(
                        offer: offer,
                        selectedRide: widget.draft.rideName,
                        choosing: _acceptingDriverId == offer.driverId,
                        onChoose: _acceptingDriverId == null
                            ? () => _acceptOffer(offer)
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
