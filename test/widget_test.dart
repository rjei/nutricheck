import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SearchScreen(),
      ),
    );

    expect(find.text('nutricheck'), findsOneWidget);
    expect(find.text('Katalog & Hasil Pencarian'), findsOneWidget);
  });
}
