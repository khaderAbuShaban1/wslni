import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('renders premium customer app splash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CustomerRideApp());

    expect(find.text('وصلني'), findsOneWidget);
    expect(find.text('رحلات فاخرة بدون خرائط معقدة'), findsOneWidget);
  });
}
