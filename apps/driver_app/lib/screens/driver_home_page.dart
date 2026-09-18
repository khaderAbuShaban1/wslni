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
  bool _initializing = true;
  int? _withdrawnOffersForRideId;
  RideRequestItem? _activeRide;
  StreamSubscription<List<RideRequestItem>>? _activeRideSubscription;
  late DriverUser _user = widget.user;

  void _onUserChanged(DriverUser updated) {
    setState(() => _user = updated);
  }

  @override
  void initState() {
    super.initState();
    // A single API read restores state when opening the app. All subsequent
    // changes arrive from Firebase; polling would defeat realtime updates.
    unawaited(_loadActiveRideFromApi());
    if (_realtime.isEnabled) {
      _activeRideSubscription = _realtime
          .watchActiveRides(_user.id)
          // Firebase is the realtime signal. Verify its update against
          // Laravel so an old cached Firebase ride can never lock the app.
          .listen((_) => unawaited(_loadActiveRideFromApi()));
    } else {
      // The API load above remains available even without Firebase.
    }
  }

  Future<void> _loadActiveRideFromApi() async {
    try {
      final rows = await _api.getList('rides?status=active');
      final rides = rows
          .whereType<Map<String, dynamic>>()
          .map(RideRequestItem.fromJson)
          .where((ride) => ride.isActive)
          .toList();
      rides.sort((a, b) => b.id.compareTo(a.id));

      if (!mounted) return;
      setState(() {
        _activeRide = rides.isEmpty ? null : rides.first;
        _initializing = false;
      });
      final activeRide = _activeRide;
      if (activeRide != null && _withdrawnOffersForRideId != activeRide.id) {
        _withdrawnOffersForRideId = activeRide.id;
        unawaited(_withdrawOtherOffers(activeRide.id));
      }
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
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

  Future<void> _signOut() async {
    await NotificationService.instance.unregisterToken();
    await ApiTokenStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
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
        user: _user,
        onReleased: _releaseActiveRide,
      );
    }

    final pages = [
      RequestsPage(user: _user),
      _TripsPage(user: _user),
      _EarningsPage(user: _user),
      _DriverProfilePage(
        user: _user,
        onSignOut: _signOut,
        onUserChanged: _onUserChanged,
      ),
    ];

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
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
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
