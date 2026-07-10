part of '../main.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({required this.user, super.key});

  final DriverUser user;

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  late Future<List<RideRequestItem>> _future;
  Stream<List<RideRequestItem>>? _rideStream;
  Timer? _pollTimer;
  List<RideRequestItem> _lastRides = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    if (_realtime.isEnabled) {
      _rideStream = _realtime.watchOpenRides();
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<RideRequestItem>> _load() async {
    final rows = await _api.getList('rides');
    final rides = rows
        .whereType<Map<String, dynamic>>()
        .map(RideRequestItem.fromJson)
        .toList();
    _lastRides = rides;
    return rides;
  }

  void _refresh({bool silent = false}) {
    setState(() {
      _future = _load();
      if (_realtime.isEnabled) {
        _rideStream = _realtime.watchOpenRides();
      }
    });
    if (!silent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جاري تحديث الطلبات...')));
    }
  }

  Future<void> _sendOffer(
    RideRequestItem ride,
    String price,
    String notes,
  ) async {
    if (price.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اكتب سعر العرض أولًا')));
      return;
    }
    await _api.post('rides/${ride.id}/offers', {
      'driver_id': widget.user.id,
      'price': price,
      'notes': notes.isEmpty ? null : notes,
    });
    await _realtime.sendOffer(
      ride: ride,
      driver: widget.user,
      price: price,
      notes: notes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إرسال عرضك للزبون')));
    _refresh();
  }

  void _openOfferSheet(RideRequestItem ride) {
    final price = TextEditingController();
    final notes = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'قدّم عرض سعر',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
            const SizedBox(height: 12),
            _RouteSummaryBox(ride: ride),
            const SizedBox(height: 12),
            _CompetitorOffersPanel(ride: ride),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payments_outlined),
                labelText: 'السعر',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes),
                labelText: 'ملاحظات اختيارية',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () async {
                await _sendOffer(ride, price.text.trim(), notes.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.send),
              label: const Text('إرسال العرض'),
            ),
          ],
        ),
      ),
    );
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

        if (databaseSnapshot.hasError && _rideStream == null) {
          return Center(
            child: TextButton.icon(
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('تعذر تحميل الطلبات، حاول مرة أخرى'),
            ),
          );
        }

        final databaseRides =
            databaseSnapshot.data ?? const <RideRequestItem>[];

        if (_rideStream == null) {
          return _RequestsList(
            rides: databaseRides,
            onRefresh: () => _refresh(),
            onPullRefresh: () async => _refresh(silent: true),
            onOffer: _openOfferSheet,
          );
        }

        return StreamBuilder<List<RideRequestItem>>(
          stream: _rideStream,
          initialData: databaseRides,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                databaseRides.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError && databaseRides.isEmpty) {
              return Center(
                child: TextButton.icon(
                  onPressed: () => _refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('تعذر تحميل الطلبات، حاول مرة أخرى'),
                ),
              );
            }
            return _RequestsList(
              rides: _mergeRides(databaseRides, snapshot.data ?? const []),
              onRefresh: () => _refresh(),
              onPullRefresh: () async => _refresh(silent: true),
              onOffer: _openOfferSheet,
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

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.rides,
    required this.onRefresh,
    required this.onOffer,
    this.onPullRefresh,
  });

  final List<RideRequestItem> rides;
  final VoidCallback onRefresh;
  final Future<void> Function()? onPullRefresh;
  final void Function(RideRequestItem ride) onOffer;

  @override
  Widget build(BuildContext context) {
    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _EmptyStateCard(
            icon: Icons.local_taxi_outlined,
            title: 'لا توجد طلبات حاليًا',
            message: 'عندما يرسل الزبائن طلبات جديدة ستظهر هنا فورًا.',
            actionLabel: 'تحديث',
            onAction: onRefresh,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onPullRefresh ?? () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'طلبات الزبائن',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _dark,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'تحديث',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            );
          }
          final ride = rides[index - 1];
          return _RideRequestCard(ride: ride, onOffer: () => onOffer(ride));
        },
      ),
    );
  }
}
