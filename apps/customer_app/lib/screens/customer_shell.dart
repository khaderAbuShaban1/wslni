import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trip_history_screen.dart';
import 'wallet_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({required this.user, super.key});

  final AppUser user;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late AppUser _user = widget.user;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(user: _user, onOpenTrips: () => setState(() => _index = 1)),
      TripHistoryScreen(user: _user, showBack: false),
      const WalletScreen(showBack: false),
      ProfileScreen(
        user: _user,
        showBack: false,
        onUserChanged: (user) => setState(() => _user = user),
      ),
    ];

    return Scaffold(
      body: pages[_index],
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
            selectedItemColor: emerald,
            unselectedItemColor: mutedText,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'الرحلات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'المحفظة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'الحساب',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
