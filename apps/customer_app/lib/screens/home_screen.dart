import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/ride_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import 'driver_offers_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, required this.onOpenTrips, super.key});

  final AppUser user;
  final VoidCallback onOpenTrips;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rideService = RideService();
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  bool _requesting = false;

  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _requestRide([String? destination]) async {
    final pickup = _pickup.text.trim();
    final dropoff = destination ?? _destination.text.trim();
    if (pickup.isEmpty) {
      _showMessage('اكتب مكان الانطلاق أولًا');
      return;
    }
    if (dropoff.isEmpty) {
      _showMessage('اكتب الوجهة أولًا');
      return;
    }

    setState(() => _requesting = true);
    try {
      final draft = await _rideService.createRide(
        customerId: widget.user.id,
        pickup: pickup,
        destination: dropoff,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DriverOffersScreen(draft: draft)),
      );
    } catch (_) {
      _showMessage('تعذر إرسال الطلب. تأكد أن الخادم يعمل على 8000.');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحبا 👋',
                        style: TextStyle(color: mutedText, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اطلب رحلتك بسهولة',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            PremiumCard(
              child: Column(
                children: [
                  CustomTextField(
                    controller: _pickup,
                    label: 'من وين؟',
                    icon: Icons.my_location_rounded,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _destination,
                    label: 'وين رايح؟',
                    icon: Icons.search_rounded,
                    onSubmitted: _requestRide,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: _requesting ? 'جاري إرسال الطلب...' : 'طلب رحلة',
                    icon: Icons.local_taxi_rounded,
                    onPressed: _requesting ? null : _requestRide,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'آخر الرحلات'),
            const SizedBox(height: 12),
            const EmptyStateCard(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد رحلات بعد',
              message: 'بعد أول رحلة، ستظهر آخر رحلاتك هنا.',
            ),
          ],
        ),
      ),
    );
  }
}
