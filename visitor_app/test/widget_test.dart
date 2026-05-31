import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Sign In'), findsOneWidget);
  });
}
