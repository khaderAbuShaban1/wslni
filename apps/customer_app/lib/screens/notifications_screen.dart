import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/empty_state_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'الإشعارات',
      child: EmptyStateCard(
        icon: Icons.notifications_none_rounded,
        title: 'لا توجد إشعارات',
        message: 'ستظهر تحديثات الرحلات والتنبيهات هنا.',
      ),
    );
  }
}
