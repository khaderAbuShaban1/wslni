import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_card.dart';
import 'trip_completed_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({required this.draft, super.key});

  final RideDraft draft;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الدفع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            child: Column(
              children: [
                SummaryRow(label: 'أجرة الرحلة', value: draft.price),
                const SummaryRow(label: 'طريقة الدفع', value: 'نقدًا'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(
            label: 'تأكيد الدفع النقدي',
            icon: Icons.payments_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TripCompletedScreen(draft: draft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
