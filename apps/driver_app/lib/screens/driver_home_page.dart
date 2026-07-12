part of '../main.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({required this.user, super.key});

  final DriverUser user;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _realtime = RealtimeDriverService();
  int _index = 0;
  bool _online = true;
  bool _initializing = true;
  int? _withdrawnOffersForRideId;
  RideRequestItem? _activeRide;
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
    if (_realtime.isEnabled) {
      _activeRideSubscription = _realtime
          .watchActiveRides(widget.user.id)
          .listen((rides) {
            if (!mounted) return;
            final activeRide = rides.isEmpty ? null : rides.first;
            setState(() {
              _activeRide = activeRide;
              _initializing = false;
            });
            if (activeRide != null &&
                _withdrawnOffersForRideId != activeRide.id) {
              _withdrawnOffersForRideId = activeRide.id;
              unawaited(_withdrawOtherOffers(activeRide.id));
            }
          });
    } else {
      _initializing = false;
    }
  }

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    super.dispose();
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
      _activeRide = null;
      _withdrawnOffersForRideId = null;
      _index = 0;
    });
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
