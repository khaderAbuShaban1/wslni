part of '../main.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({required this.user, super.key});

  final DriverUser user;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _api = ApiClient();
  final _realtime = RealtimeDriverService();
  int _index = 0;
  bool _online = true;
  bool _checkingActiveRide = false;
  bool _initializing = true;
  int? _withdrawnOffersForRideId;
  int _activeRideRevision = 0;
  RideRequestItem? _activeRide;
  Timer? _activeRideTimer;
  StreamSubscription<List<RideRequestItem>>? _activeRideSubscription;

  late final List<Widget> _pages = [
    RequestsPage(user: widget.user),
    _TripsPage(user: widget.user),
    const _EarningsPage(),
    _DriverProfilePage(user: widget.user),
  ];

  @override
  void initState() {
    super.initState();
    _checkForActiveRide();
    _activeRideTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkForActiveRide(),
    );
    if (_realtime.isEnabled) {
      _activeRideSubscription = _realtime
          .watchActiveRides(widget.user.id)
          .listen((rides) {
            if (rides.isNotEmpty && mounted && _activeRide == null) {
              setState(() => _activeRide = rides.first);
            }
            _checkForActiveRide();
          });
    }
  }

  @override
  void dispose() {
    _activeRideTimer?.cancel();
    _activeRideSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkForActiveRide() async {
    if (_checkingActiveRide) return;
    _checkingActiveRide = true;
    final revision = _activeRideRevision;
    try {
      final rows = await _api.getList(
        'rides?driver_id=${widget.user.id}&status=active',
      );
      final rides = rows
          .whereType<Map<String, dynamic>>()
          .map(RideRequestItem.fromJson)
          .where((ride) => ride.isActive)
          .toList();
      if (!mounted || revision != _activeRideRevision) return;
      setState(() {
        _activeRide = rides.isEmpty ? null : rides.first;
        _initializing = false;
      });
      if (rides.isNotEmpty && _withdrawnOffersForRideId != rides.first.id) {
        _withdrawnOffersForRideId = rides.first.id;
        unawaited(_withdrawOtherOffers(rides.first.id));
      }
    } catch (_) {
      if (mounted && _initializing) {
        setState(() => _initializing = false);
      }
    } finally {
      _checkingActiveRide = false;
    }
  }

  Future<void> _withdrawOtherOffers(int activeRideId) async {
    try {
      await _realtime.withdrawOtherOffers(
        driverId: widget.user.id,
        activeRideId: activeRideId,
      );
    } catch (_) {
      // Laravel still prevents another offer from being accepted for this driver.
    }
  }

  void _releaseActiveRide() {
    if (!mounted) return;
    setState(() {
      _activeRideRevision++;
      _activeRide = null;
      _withdrawnOffersForRideId = null;
      _index = 0;
    });
    _checkForActiveRide();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing && _activeRide == null) {
      return const Scaffold(body: SafeArea(child: _SkeletonList()));
    }

    final activeRide = _activeRide;
    if (activeRide != null) {
      return ActiveRidePage(
        key: ValueKey('${activeRide.id}-${activeRide.status}'),
        ride: activeRide,
        user: widget.user,
        onReleased: _releaseActiveRide,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('وصلني للسائق'),
        actions: [
          Row(
            children: [
              Text(_online ? 'متصل' : 'غير متصل'),
              Switch(
                value: _online,
                onChanged: (value) => setState(() => _online = value),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_taxi_outlined),
                activeIcon: Icon(Icons.local_taxi),
                label: 'الطلبات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.route_outlined),
                activeIcon: Icon(Icons.route),
                label: 'رحلاتي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'الأرباح',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
