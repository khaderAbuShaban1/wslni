import 'package:flutter/material.dart';

import '../models/ride_model.dart';
import '../utils/constants.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/ride_card.dart';
import 'payment_screen.dart';

class TripProgressScreen extends StatelessWidget {
  const TripProgressScreen({required this.draft, super.key});

  final RideDraft draft;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تقدم الرحلة',
      child: Column(
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرحلة قيد التنفيذ',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم تحديث حالة الرحلة عند توفر بيانات السائق.',
                  style: TextStyle(color: mutedText),
                ),
                const SizedBox(height: 24),
                const RideProgressIndicator(progress: 0),
                const SizedBox(height: 22),
                SummaryRow(label: 'من', value: draft.pickup),
                SummaryRow(label: 'إلى', value: draft.destination),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'إنهاء الرحلة والدفع',
            icon: Icons.payments_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PaymentScreen(draft: draft)),
            ),
          ),
        ],
      ),
    );
  }
}
