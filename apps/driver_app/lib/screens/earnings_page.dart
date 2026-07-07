part of '../main.dart';

class _EarningsPage extends StatelessWidget {
  const _EarningsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: _EmptyStateCard(
          icon: Icons.payments_outlined,
          title: 'لا توجد أرباح بعد',
          message: 'بعد إكمال الرحلات ستظهر أرباحك هنا.',
        ),
      ),
    );
  }
}
