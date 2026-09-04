import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../services/realtime_ride_service.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/premium_card.dart';
import 'trip_completed_screen.dart';
import 'driver_offers_screen.dart';

class TripProgressScreen extends StatelessWidget {
  TripProgressScreen({required this.draft, super.key});

  final RideDraft draft;
  final RealtimeRideService _realtime = RealtimeRideService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RideDraft?>(
      stream: _realtime.watchRide(draft.id),
      initialData: draft,
      builder: (context, snapshot) {
        final ride = snapshot.data ?? draft;
        return PopScope(
          canPop: true,
          child: AppScaffold(
            showBack: true,
            title: 'حالة الرحلة',
            child: Column(
              children: [
                _StatusHero(status: ride.status, label: ride.statusLabel),
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
          ),
        );
      },
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
