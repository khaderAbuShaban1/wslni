import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/empty_state_card.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({this.showBack = true, super.key});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'سجل الرحلات',
      showBack: showBack,
      child: const EmptyStateCard(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد رحلات بعد',
        message: 'ستظهر رحلاتك السابقة هنا بعد إكمال أول طلب.',
      ),
    );
  }
}
