import 'package:driver_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders driver dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const DriverRideApp());

    expect(find.text('Ride Driver'), findsOneWidget);
    expect(find.text('Incoming request'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
  });
}
