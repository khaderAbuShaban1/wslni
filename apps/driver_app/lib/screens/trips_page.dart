part of '../main.dart';

class _TripsPage extends StatefulWidget {
  const _TripsPage({required this.user});

  final DriverUser user;

  @override
  State<_TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<_TripsPage> {
  final _realtime = RealtimeDriverService();
  late Stream<List<RideRequestItem>> _rideStream;

  @override
  void initState() {
    super.initState();
    _rideStream = _realtime.watchDriverRides(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideRequestItem>>(
      stream: _rideStream,
      builder: (context, realtimeSnapshot) {
        if (realtimeSnapshot.connectionState == ConnectionState.waiting) {
          return const _SkeletonList();
        }
        final rides = (realtimeSnapshot.data ?? const <RideRequestItem>[])
            .where(
              (ride) =>
                  ride.status == RideStatuses.tripCompleted ||
                  ride.status == RideStatuses.rated ||
                  ride.status == RideStatuses.cancelled,
            )
            .toList();

        if (rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: const _EmptyStateCard(
                icon: Icons.route_outlined,
                title: 'لا يوجد سجل رحلات بعد',
                message: 'الرحلات المكتملة والملغاة ستظهر هنا.',
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                'سجل الرحلات',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              );
            }
            return _AcceptedRideCard(ride: rides[index - 1]);
          },
        );
      },
    );
  }
}

class _AcceptedRideCard extends StatelessWidget {
  const _AcceptedRideCard({required this.ride});

  final RideRequestItem ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                backgroundColor:
                    ride.status == RideStatuses.tripCompleted ||
                        ride.status == RideStatuses.rated
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .15)
                    : _error.withValues(alpha: .14),
                child: Icon(
                  ride.status == RideStatuses.tripCompleted ||
                          ride.status == RideStatuses.rated
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color:
                      ride.status == RideStatuses.tripCompleted ||
                          ride.status == RideStatuses.rated
                      ? Theme.of(context).colorScheme.primary
                      : _error,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.statusLabel,
                      style: TextStyle(
                        color:
                            ride.status == RideStatuses.tripCompleted ||
                                ride.status == RideStatuses.rated
                            ? _success
                            : _error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteSummaryBox(ride: ride),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ride.status == RideStatuses.tripCompleted ||
                          ride.status == RideStatuses.rated
                      ? Icons.task_alt_rounded
                      : Icons.info_outline_rounded,
                  color:
                      ride.status == RideStatuses.tripCompleted ||
                          ride.status == RideStatuses.rated
                      ? _success
                      : _error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ride.status == RideStatuses.tripCompleted ||
                            ride.status == RideStatuses.rated
                        ? 'تم إنهاء هذه الرحلة ويمكنك الآن استقبال طلبات جديدة.'
                        : 'تم إلغاء هذه الرحلة ويمكنك الآن استقبال طلبات جديدة.',
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                    ),
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
