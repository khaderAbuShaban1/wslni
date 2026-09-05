import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trip_history_screen.dart';
import 'wallet_screen.dart';
import 'login_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({required this.user, super.key});

  final AppUser user;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late AppUser _user = widget.user;
  int _index = 0;
  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(user: _user, onOpenTrips: () => setState(() => _index = 1)),
      TripHistoryScreen(user: _user, showBack: false),
      WalletScreen(user: _user, showBack: false),
      ProfileScreen(
        user: _user,
        showBack: false,
        onUserChanged: (user) => setState(() => _user = user),
        onSignOut: _signOut,
      ),
    ];
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'الرحلات',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'المحفظة',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
