import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/main.dart';

void main() {
  testWidgets('NutriCheck app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NutriCheckApp());

    // The native splash is complete before Flutter renders HomeScreen.
    expect(find.text('nutricheck'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
