part of '../main.dart';

class _TripsPage extends StatelessWidget {
  const _TripsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: _EmptyStateCard(
          icon: Icons.route_outlined,
          title: 'لا توجد رحلات بعد',
          message: 'الرحلات المقبولة ستظهر هنا.',
        ),
      ),
    );
  }
}
