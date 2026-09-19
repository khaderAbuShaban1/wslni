import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/api_client.dart';
import '../services/realtime_ride_service.dart';
import '../services/ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/premium_card.dart';
import 'trip_completed_screen.dart';
import 'driver_offers_screen.dart';

class TripProgressScreen extends StatefulWidget {
  const TripProgressScreen({required this.draft, super.key});

  final RideDraft draft;

  @override
  State<TripProgressScreen> createState() => _TripProgressScreenState();
}

class _TripProgressScreenState extends State<TripProgressScreen> {
  final RealtimeRideService _realtime = RealtimeRideService();
  final RideService _rideService = RideService();
  bool _cancelling = false;
  late RideDraft _ride = widget.draft;
  StreamSubscription<RideDraft?>? _rideSub;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _expiryRequested = false;

  static const _statusOrder = [
    RideStatuses.pending,
    RideStatuses.receivingOffers,
    RideStatuses.driverSelected,
    RideStatuses.driverConfirmed,
    RideStatuses.driverOnTheWay,
    RideStatuses.driverArrived,
    RideStatuses.tripStarted,
    RideStatuses.tripCompleted,
    RideStatuses.rated,
  ];

  bool _isProgression(String incoming) {
    if (incoming == RideStatuses.cancelled) return true;
    final current = _statusOrder.indexOf(_ride.status);
    final next = _statusOrder.indexOf(incoming);
    if (current == -1 || next == -1) return true;
    return next >= current;
  }

  bool _canCancel(String status) => {
    RideStatuses.pending,
    RideStatuses.receivingOffers,
    RideStatuses.driverSelected,
  }.contains(status);

  Future<void> _confirmCancel(RideDraft ride) async {
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
      await _rideService.cancelRide(ride);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الرحلة بنجاح.')));
      Navigator.of(context).pop();
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
  void initState() {
    super.initState();
    _startCountdown();
    _rideSub = _realtime
        .watchRide(widget.draft.customerId, widget.draft.id)
        .listen((update) {
          if (update != null && _isProgression(update.status) && mounted) {
            setState(() => _ride = update);
            if (!_canCancel(update.status)) {
              _countdownTimer?.cancel();
              _countdownTimer = null;
            } else if (update.expiresAt != null && _countdownTimer == null) {
              _startCountdownFrom(update.expiresAt!);
            }
          }
        });
  }

  void _startCountdown() {
    final expiresAt = widget.draft.expiresAt;
    if (expiresAt == null || !_canCancel(widget.draft.status)) return;
    _startCountdownFrom(expiresAt);
  }

  Duration _leftUntil(DateTime expiresAt) {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _startCountdownFrom(DateTime expiresAt) {
    _remaining = _leftUntil(expiresAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _leftUntil(expiresAt));
      if (_remaining == Duration.zero) _requestExpiry();
    });
    if (_remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestExpiry());
    }
  }

  // Firebase delivers the resulting cancellation to the listener above.
  Future<void> _requestExpiry() async {
    if (_expiryRequested) return;
    _expiryRequested = true;
    try {
      await _rideService.expireRide(_ride.id);
    } catch (_) {
      // The server-side scheduler still expires the ride within seconds.
    }
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    return PopScope(
      canPop: true,
      child: AppScaffold(
        showBack: true,
        title: 'حالة الرحلة',
        child: Column(
          children: [
            _StatusHero(status: ride.status, label: ride.statusLabel),
            if (_canCancel(ride.status) && ride.expiresAt != null) ...[
              const SizedBox(height: 14),
              _CountdownBanner(remaining: _remaining),
            ],
            const SizedBox(height: 18),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage(ride.status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!_isFinalStatus(ride.status)) ...[
                    const SizedBox(height: 22),
                    _RideTimeline(status: ride.status),
                  ],
                  if (ride.driverName.isNotEmpty) ...[
                    const Divider(height: 34),
                    _SectionLabel(
                      icon: Icons.person_outline_rounded,
                      label: 'بيانات السائق',
                    ),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: 'السائق',
                      value: ride.driverName,
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'الهاتف',
                      value: ride.driverPhone.isEmpty
                          ? 'غير متوفر'
                          : ride.driverPhone,
                    ),
                    _InfoTile(
                      icon: Icons.directions_car_outlined,
                      label: 'السيارة',
                      value: [
                        ride.driverCar,
                        ride.driverPlate,
                      ].where((value) => value.isNotEmpty).join(' - '),
                    ),
                  ],
                  const Divider(height: 34),
                  _SectionLabel(
                    icon: Icons.route_outlined,
                    label: 'مسار الرحلة',
                  ),
                  const SizedBox(height: 12),
                  _RouteStop(
                    icon: Icons.trip_origin_rounded,
                    label: 'نقطة الانطلاق',
                    value: ride.pickup,
                  ),
                  _RouteStop(
                    icon: Icons.location_on_rounded,
                    label: 'الوجهة',
                    value: ride.destination,
                    isLast: true,
                  ),
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
                    builder: (_) =>
                        DriverOffersScreen(draft: ride, lockNavigation: true),
                  ),
                ),
                icon: const Icon(Icons.local_offer_outlined),
                label: const Text('اختيار سائق آخر'),
              ),
            ],
            if (_canCancel(ride.status)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: .4),
                  ),
                ),
                onPressed: _cancelling ? null : () => _confirmCancel(ride),
                icon: _cancelling
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(_cancelling ? 'جاري الإلغاء...' : 'إلغاء الرحلة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) => switch (status) {
    RideStatuses.driverSelected => 'تم إرسال طلب تأكيد إلى السائق.',
    RideStatuses.driverConfirmed => 'أكد السائق الرحلة وسيبدأ التحرك قريبًا.',
    RideStatuses.driverOnTheWay => 'السائق في الطريق إلى نقطة الانطلاق.',
    RideStatuses.driverArrived => 'وصل السائق. يرجى التوجه إلى المركبة.',
    RideStatuses.tripStarted => 'الرحلة قيد التنفيذ.',
    RideStatuses.tripCompleted =>
      'اكتملت الرحلة بنجاح. شاركنا رأيك في تجربة السائق.',
    RideStatuses.rated => 'شكرًا لتقييمك. نأمل أن تكون تجربتك رائعة.',
    RideStatuses.cancelled =>
      'تم إلغاء هذه الرحلة. يمكنك طلب رحلة جديدة في أي وقت.',
    RideStatuses.receivingOffers => 'رفض السائق الطلب. يمكنك اختيار عرض آخر.',
    _ => 'يتم تحديث حالة الرحلة تلقائيًا.',
  };

  bool _isFinalStatus(String status) => {
    RideStatuses.tripCompleted,
    RideStatuses.rated,
    RideStatuses.cancelled,
  }.contains(status);
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color, background) = switch (status) {
      RideStatuses.cancelled => (
        Icons.cancel_outlined,
        scheme.error,
        scheme.errorContainer,
      ),
      RideStatuses.tripCompleted || RideStatuses.rated => (
        Icons.check_circle_rounded,
        successColor,
        successColor.withValues(alpha: .14),
      ),
      RideStatuses.tripStarted => (
        Icons.route_rounded,
        scheme.primary,
        scheme.primaryContainer,
      ),
      RideStatuses.driverArrived => (
        Icons.location_on_rounded,
        scheme.primary,
        scheme.primaryContainer,
      ),
      RideStatuses.driverOnTheWay || RideStatuses.driverConfirmed => (
        Icons.directions_car_filled_outlined,
        scheme.primary,
        scheme.primaryContainer,
      ),
      RideStatuses.driverSelected => (
        Icons.mark_email_read_outlined,
        warningColor,
        warningColor.withValues(alpha: .16),
      ),
      _ => (
        Icons.radar_rounded,
        warningColor,
        warningColor.withValues(alpha: .16),
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الرحلة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideTimeline extends StatelessWidget {
  const _RideTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (
        RideStatuses.driverConfirmed,
        'تأكيد السائق',
        Icons.verified_user_outlined,
      ),
      (RideStatuses.driverOnTheWay, 'في الطريق', Icons.directions_car_outlined),
      (RideStatuses.driverArrived, 'وصل السائق', Icons.location_on_outlined),
      (RideStatuses.tripStarted, 'بدء الرحلة', Icons.route_outlined),
    ];
    final current = steps.indexWhere((step) => step.$1 == status);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(steps.length, (index) {
        final isCurrent = index == current;
        final isDone = current > index;
        final color = isCurrent || isDone
            ? scheme.primary
            : scheme.outlineVariant;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0 ? Colors.transparent : color,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : steps[index].$3,
                      size: 17,
                      color: isCurrent || isDone
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (isDone ? scheme.primary : scheme.outlineVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                steps[index].$2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isCurrent ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
    ],
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value.isEmpty ? 'غير متوفر' : value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 26,
        child: Column(
          children: [
            Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final label =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
