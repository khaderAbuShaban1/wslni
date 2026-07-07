part of '../main.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({required this.user, super.key});

  final DriverUser user;

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _index = 0;
  bool _online = true;

  late final List<Widget> _pages = [
    RequestsPage(user: widget.user),
    const _TripsPage(),
    const _EarningsPage(),
    _DriverProfilePage(user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: _pages[_index],
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _emerald,
            unselectedItemColor: _muted,
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
