import 'package:driver_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders driver login', (WidgetTester tester) async {
    await tester.pumpWidget(const DriverRideApp());

    expect(find.text('تسجيل دخول السائق'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
  });
}
