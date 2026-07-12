import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/ride_model.dart';
import '../services/realtime_ride_service.dart';
import '../services/ride_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, required this.onOpenTrips, super.key});

  final AppUser user;
  final VoidCallback onOpenTrips;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rideService = RideService();
  final _realtime = RealtimeRideService();
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _scrollController = ScrollController();
  bool _requesting = false;

  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestRide([String? destination]) async {
    final pickup = _pickup.text.trim();
    final dropoff = destination ?? _destination.text.trim();
    if (pickup.isEmpty) {
      _showMessage('اكتب مكان الانطلاق أولًا');
      return;
    }
    if (dropoff.isEmpty) {
      _showMessage('اكتب الوجهة أولًا');
      return;
    }

    setState(() => _requesting = true);
    try {
      await _rideService.createRide(
        customerId: widget.user.id,
        customerName: widget.user.name,
        customerPhone: widget.user.phone,
        pickup: pickup,
        destination: dropoff,
      );

      if (!mounted) return;
      _showMessage('تم إرسال الطلب ونقله إلى رحلاتي.');
      widget.onOpenTrips();
    } catch (_) {
      _showMessage('تعذر إرسال الطلب. تأكد أن الخادم يعمل على 8000.');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _repeatRide(RideDraft ride) {
    _pickup.text = ride.pickup;
    _destination.text = ride.destination;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _showMessage('تم تجهيز نفس العناوين. راجعها ثم اضغط طلب رحلة.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحبا 👋',
                        style: TextStyle(color: mutedText, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اطلب رحلتك بسهولة',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .15),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    fixedSize: const Size(54, 54),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PremiumCard(
              child: Column(
                children: [
                  CustomTextField(
                    controller: _pickup,
                    label: 'من وين؟',
                    icon: Icons.my_location_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _destination,
                    label: 'وين رايح؟',
                    icon: Icons.search_rounded,
                    onSubmitted: _requestRide,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: _requesting ? 'جاري إرسال الطلب...' : 'طلب رحلة',
                    icon: Icons.local_taxi_rounded,
                    onPressed: _requesting ? null : _requestRide,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'آخر الرحلات'),
            const SizedBox(height: 12),
            StreamBuilder<List<RideDraft>>(
              stream: _realtime.watchCustomerRides(widget.user.id),
              builder: (context, snapshot) {
                final completed = (snapshot.data ?? const <RideDraft>[])
                    .where(
                      (ride) =>
                          ride.status == RideStatuses.tripCompleted ||
                          ride.status == RideStatuses.rated ||
                          ride.status == 'completed',
                    )
                    .take(3)
                    .toList();
                if (completed.isEmpty) {
                  return const EmptyStateCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا توجد رحلات مكتملة بعد',
                    message: 'بعد إكمال أول رحلة، ستظهر هنا مباشرة.',
                  );
                }
                return Column(
                  children: [
                    for (final ride in completed) ...[
                      _RecentRideCard(
                        ride: ride,
                        onTap: () => _repeatRide(ride),
                      ),
                      const SizedBox(height: 10),
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

class _RecentRideCard extends StatelessWidget {
  const _RecentRideCard({required this.ride, required this.onTap});

  final RideDraft ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: PremiumCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.local_taxi_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ride.pickup} ← ${ride.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ride.price.isNotEmpty && ride.price != 'بانتظار العرض')
                    Text(
                      '${ride.price} ش',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'مكتملة',
                    style: TextStyle(
                      color: successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.replay_rounded, color: mutedText, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
