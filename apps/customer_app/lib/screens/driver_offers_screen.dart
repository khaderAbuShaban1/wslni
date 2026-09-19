import 'dart:async';

import 'package:flutter/material.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../services/api_client.dart';
import '../services/driver_service.dart';
import '../services/realtime_ride_service.dart';
import '../services/ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/driver_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/ride_card.dart';
import '../widgets/section_header.dart';
import 'trip_progress_screen.dart';

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
  bool _cancelling = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  StreamSubscription<RideDraft?>? _rideSub;
  bool _left = false;
  bool _expiryRequested = false;

  static const _expiredMessage = 'انتهت مهلة الرحلة. يمكنك إنشاء رحلة جديدة.';

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _rideSub = widget.realtimeService
        .watchRide(widget.draft.customerId, widget.draft.id)
        .listen((update) {
          if (update?.status == RideStatuses.cancelled && !_cancelling) {
            _leave(_expiredMessage);
          }
        });
  }

  void _leave(String message) {
    if (_left || !mounted) return;
    _left = true;
    _countdownTimer?.cancel();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  void _startCountdown() {
    final expiresAt = widget.draft.expiresAt;
    if (expiresAt == null) return;
    Duration left() {
      final value = expiresAt.difference(DateTime.now());
      return value.isNegative ? Duration.zero : value;
    }

    _remaining = left();
    if (_remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestExpiry());
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = left());
      if (_remaining == Duration.zero) {
        _countdownTimer?.cancel();
        _requestExpiry();
      }
    });
  }

  Future<void> _requestExpiry() async {
    if (_expiryRequested) return;
    _expiryRequested = true;
    try {
      final cancelled = await widget.rideService.expireRide(widget.draft.id);
      if (cancelled) _leave(_expiredMessage);
    } catch (_) {
      // The server-side scheduler still expires the ride within seconds.
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _rideSub?.cancel();
    super.dispose();
  }

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
          builder: (_) => TripProgressScreen(draft: acceptedRide),
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

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الرحلة؟'),
        content: const Text('هل أنت متأكد من إلغاء هذه الرحلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await widget.rideService.cancelRide(widget.draft);
      _leave('تم إلغاء الرحلة بنجاح.');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إلغاء الرحلة. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
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
            if (widget.draft.expiresAt != null) ...[
              const SizedBox(height: 14),
              _CountdownBanner(remaining: _remaining),
            ],
            const SizedBox(height: 22),
            const SectionHeader(title: 'اختر أفضل عرض'),
            const SizedBox(height: 12),
            StreamBuilder<List<DriverOffer>>(
              stream: widget.realtimeService.watchOffers(
                widget.draft.customerId,
                widget.draft.id,
              ),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: .4),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _cancelling ? null : _confirmCancel,
              icon: _cancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_cancelling ? 'جاري الإلغاء...' : 'إلغاء الرحلة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final label = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isUrgent = remaining.inMinutes < 3;
    final color = isUrgent ? errorColor : warningColor;
    final bg = color.withValues(alpha: .12);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'المهلة المتبقية للطلب',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
