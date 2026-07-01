import 'package:flutter/material.dart';

void main() {
  runApp(const DriverRideApp());
}

class DriverRideApp extends StatelessWidget {
  const DriverRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride Driver',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
      ),
      home: const DriverHomePage(),
    );
  }
}

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _index = 0;
  bool _online = true;

  final _pages = const [
    _DriverDashboard(),
    _TripsPage(),
    _EarningsPage(),
    _DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Driver'),
        actions: [
          Row(
            children: [
              Text(_online ? 'Online' : 'Offline'),
              Switch(
                value: _online,
                onChanged: (value) => setState(() => _online = value),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DriverDashboard extends StatelessWidget {
  const _DriverDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('84.60 USD', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(child: _StatTile(label: 'Trips', value: '11')),
                  SizedBox(width: 12),
                  Expanded(child: _StatTile(label: 'Rating', value: '4.92')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Incoming request', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Maya Ahmed'),
                  subtitle: Text('Pickup: Al-Balqa'),
                  trailing: Text('3.8 km'),
                ),
                const SizedBox(height: 8),
                const Text('Dropoff: City Center'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.close),
                        label: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Active trip', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        const _TripCard(
          title: 'Airport pickup',
          subtitle: 'On route to passenger',
          note: 'ETA 6 min',
        ),
      ],
    );
  }
}

class _TripsPage extends StatelessWidget {
  const _TripsPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionTitle(title: 'Trips'),
        SizedBox(height: 12),
        _TripCard(title: 'Completed: Downtown', subtitle: 'Today 09:40', note: '12.50 USD'),
        SizedBox(height: 10),
        _TripCard(title: 'Completed: University', subtitle: 'Today 08:15', note: '9.30 USD'),
      ],
    );
  }
}

class _EarningsPage extends StatelessWidget {
  const _EarningsPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Earnings'),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _StatTile(label: 'Week', value: '421 USD')),
            SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Cash', value: '96 USD')),
          ],
        ),
        const SizedBox(height: 18),
        const _TripCard(title: 'Peak hours', subtitle: '12:00 - 16:00', note: 'Best demand'),
      ],
    );
  }
}

class _DriverProfilePage extends StatelessWidget {
  const _DriverProfilePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Profile'),
        const SizedBox(height: 12),
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
        const SizedBox(height: 12),
        Text('Driver Name', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('driver@ride.app', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        const _ProfileRow(icon: Icons.directions_car, label: 'Vehicle', value: 'Toyota Corolla'),
        const _ProfileRow(icon: Icons.badge, label: 'License', value: 'AB-12345'),
        const _ProfileRow(icon: Icons.support_agent, label: 'Support', value: '24/7'),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.title, required this.subtitle, required this.note});

  final String title;
  final String subtitle;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.local_taxi)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(note, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
