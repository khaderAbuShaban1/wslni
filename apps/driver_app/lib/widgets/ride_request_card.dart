part of '../main.dart';

class _RideRequestCard extends StatelessWidget {
  const _RideRequestCard({required this.ride, required this.onOffer});

  final RideRequestItem ride;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: .11),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .15),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.customerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'طلب رحلة جديد',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteSummaryBox(ride: ride),
          const SizedBox(height: 12),
          _CompetitorOffersPanel(ride: ride),
          if (ride.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'ملاحظات: ${ride.notes}',
              style: const TextStyle(color: _muted),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _emerald,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onOffer,
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text(
              'قدّم عرض سعر',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitorOffersPanel extends StatelessWidget {
  const _CompetitorOffersPanel({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (ride.offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: const Row(
          children: [
            Icon(Icons.trending_down, color: _emerald),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'لا توجد عروض منافسة بعد. كن أول سائق يقدم سعره.',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final lowest = ride.lowestOffer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: _emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lowest == null
                      ? 'العروض المقدمة'
                      : 'أقل عرض حالي: $lowest شيكل',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${ride.offers.length} عروض',
                style: const TextStyle(color: _muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final offer in ride.offers.take(3)) ...[
            _CompetitorOfferRow(offer: offer),
            if (offer != ride.offers.take(3).last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CompetitorOfferRow extends StatelessWidget {
  const _CompetitorOfferRow({required this.offer});

  final DriverRideOffer offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: .15),
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${offer.driverName} • ${offer.vehicle}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${offer.price} شيكل',
          style: const TextStyle(color: _emerald, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _RouteSummaryBox extends StatelessWidget {
  const _RouteSummaryBox({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _RouteLine(label: 'من', value: ride.pickup, icon: Icons.my_location),
          const Divider(height: 22),
          _RouteLine(
            label: 'إلى',
            value: ride.dropoff,
            icon: Icons.place_outlined,
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: scheme.primary.withValues(alpha: .15),
          child: Icon(icon, size: 25, color: scheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
