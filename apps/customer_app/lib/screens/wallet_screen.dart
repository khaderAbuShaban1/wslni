import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/empty_state_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({this.showBack = true, super.key});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'المحفظة',
      showBack: showBack,
      child: const EmptyStateCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'لا توجد بيانات محفظة',
        message: 'عند إضافة نظام الدفع ستظهر بيانات المحفظة هنا.',
      ),
    );
  }
}
