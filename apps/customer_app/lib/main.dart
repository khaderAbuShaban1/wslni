import 'package:flutter/material.dart';

void main() {
  runApp(const CustomerRideApp());
}

class CustomerRideApp extends StatelessWidget {
  const CustomerRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride Customer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E),
      ),
      home: const CustomerHomePage(),
    );
  }
}

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _index = 0;

  final _pages = const [
    _CustomerDashboard(),
    _TripHistoryPage(),
    _WalletPage(),
    _AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Customer'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CustomerDashboard extends StatelessWidget {
  const _CustomerDashboard();

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
              Text('Book a ride', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const _LocationField(icon: Icons.my_location, label: 'Pickup', value: 'Current location'),
              const SizedBox(height: 10),
              const _LocationField(icon: Icons.place, label: 'Dropoff', value: 'Choose destination'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.local_taxi),
                label: const Text('Request Ride'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: _StatTile(label: 'ETA', value: '4 min')),
            SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Available', value: '18 drivers')),
          ],
        ),
        const SizedBox(height: 18),
        Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _ActionChip(icon: Icons.schedule, label: 'Schedule'),
            _ActionChip(icon: Icons.flight_land, label: 'Airport'),
            _ActionChip(icon: Icons.local_shipping, label: 'Package'),
            _ActionChip(icon: Icons.star_outline, label: 'Favorites'),
          ],
        ),
        const SizedBox(height: 18),
        Text('Nearby rides', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        const _RideCard(
          title: 'Sedan to downtown',
          subtitle: 'Pickup in 4 min',
          price: '12.50 USD',
          icon: Icons.directions_car,
        ),
        const SizedBox(height: 10),
        const _RideCard(
          title: 'Comfort to airport',
          subtitle: 'Pickup in 9 min',
          price: '19.00 USD',
          icon: Icons.airport_shuttle,
        ),
      ],
    );
  }
}

class _TripHistoryPage extends StatelessWidget {
  const _TripHistoryPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionTitle(title: 'Trips'),
        SizedBox(height: 12),
        _RideCard(title: 'Mall to home', subtitle: 'Completed today', price: '8.40 USD', icon: Icons.check_circle_outline),
        SizedBox(height: 10),
        _RideCard(title: 'Home to clinic', subtitle: 'Completed yesterday', price: '6.90 USD', icon: Icons.check_circle_outline),
      ],
    );
  }
}

class _WalletPage extends StatelessWidget {
  const _WalletPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Wallet'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text('58.20 USD', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: _StatTile(label: 'Trips', value: '24')),
                  SizedBox(width: 12),
                  Expanded(child: _StatTile(label: 'Saved', value: '7.80')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _RideCard(title: 'Visa **** 2214', subtitle: 'Default payment method', price: 'Card', icon: Icons.credit_card),
      ],
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'Profile'),
        const SizedBox(height: 12),
        const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
        const SizedBox(height: 12),
        Text('Guest Rider', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('guest@ride.app', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        const _ProfileRow(icon: Icons.phone, label: 'Phone', value: '+970 59 000 0000'),
        const _ProfileRow(icon: Icons.language, label: 'Language', value: 'Arabic / English'),
        const _ProfileRow(icon: Icons.security, label: 'Security', value: 'PIN + OTP'),
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

class _LocationField extends StatelessWidget {
  const _LocationField({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.title, required this.subtitle, required this.price, required this.icon});

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(price, style: Theme.of(context).textTheme.titleSmall),
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
