part of '../main.dart';

class _TripsPage extends StatefulWidget {
  const _TripsPage({required this.user});

  final DriverUser user;

  @override
  State<_TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<_TripsPage> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  late Future<List<RideRequestItem>> _future;
  late Stream<List<RideRequestItem>> _rideStream;
  Timer? _pollTimer;
  List<RideRequestItem> _lastRides = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _rideStream = _realtime.watchAcceptedRides(widget.user.id);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<RideRequestItem>> _load() async {
    final rows = await _api.getList(
      'rides?driver_id=${widget.user.id}&status=all',
    );
    final rides = rows
        .whereType<Map<String, dynamic>>()
        .map(RideRequestItem.fromJson)
        .where(
          (ride) => ride.status == 'completed' || ride.status == 'cancelled',
        )
        .toList();
    _lastRides = rides;
    return rides;
  }

  void _refresh() {
    setState(() {
      _future = _load();
      _rideStream = _realtime.watchAcceptedRides(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RideRequestItem>>(
      future: _future,
      initialData: _lastRides,
      builder: (context, databaseSnapshot) {
        if (databaseSnapshot.connectionState == ConnectionState.waiting &&
            _lastRides.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final databaseRides =
            databaseSnapshot.data ?? const <RideRequestItem>[];

        return StreamBuilder<List<RideRequestItem>>(
          stream: _rideStream,
          initialData: databaseRides,
          builder: (context, realtimeSnapshot) {
            final rides =
                _mergeRides(databaseRides, realtimeSnapshot.data ?? const [])
                    .where(
                      (ride) =>
                          ride.status == 'completed' ||
                          ride.status == 'cancelled',
                    )
                    .toList();

            if (rides.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _EmptyStateCard(
                    icon: Icons.route_outlined,
                    title: 'لا يوجد سجل رحلات بعد',
                    message: 'الرحلات المكتملة والملغاة ستظهر هنا.',
                    actionLabel: 'تحديث',
                    onAction: _refresh,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'سجل الرحلات',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _dark,
                      ),
                    );
                  }
                  return _AcceptedRideCard(ride: rides[index - 1]);
                },
              ),
            );
          },
        );
      },
    );
  }

  List<RideRequestItem> _mergeRides(
    List<RideRequestItem> databaseRides,
    List<RideRequestItem> realtimeRides,
  ) {
    final byId = <int, RideRequestItem>{};
    for (final ride in databaseRides) {
      byId[ride.id] = ride;
    }
    for (final ride in realtimeRides) {
      byId[ride.id] = ride;
    }
    return byId.values.toList()..sort((a, b) => b.id.compareTo(a.id));
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 24,
            offset: Offset(0, 10),
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
                backgroundColor: ride.status == 'completed'
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                child: Icon(
                  ride.status == 'completed'
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  color: ride.status == 'completed'
                      ? _emerald
                      : Colors.red.shade700,
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
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride.statusLabel,
                      style: TextStyle(
                        color: ride.status == 'completed'
                            ? _emerald
                            : Colors.red.shade700,
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Icon(
                  ride.status == 'completed'
                      ? Icons.task_alt_rounded
                      : Icons.info_outline_rounded,
                  color: ride.status == 'completed'
                      ? _emerald
                      : Colors.red.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ride.status == 'completed'
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
