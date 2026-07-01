import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('renders customer ride home', (WidgetTester tester) async {
    await tester.pumpWidget(const CustomerRideApp());

    expect(find.text('Ride Customer'), findsOneWidget);
    expect(find.text('Book a ride'), findsOneWidget);
    expect(find.text('Request Ride'), findsOneWidget);
  });
}
