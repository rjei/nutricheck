import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutricheck/data/repositories/additive_repository.dart';
import 'package:nutricheck/data/repositories/product_repository.dart';
import 'package:nutricheck/main.dart';
import 'package:nutricheck/screens/search_screen.dart';
import 'package:nutricheck/services/auth_service.dart';

import 'data/support/test_support.dart';

void main() {
  tearDown(() => AuthService().logout());

  testWidgets('NutriCheck app loads home screen when logged in', (WidgetTester tester) async {
    AuthService().login('budi.santoso@gmail.com', 'password123');
    await tester.pumpWidget(const NutriCheckApp());

    expect(find.text('nutricheck'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('SearchScreen renders properly', (WidgetTester tester) async {
    // Repository palsu agar test tidak menyentuh jaringan.
    final repository = ProductRepository(
      dataSource: FakeProductDataSource(),
      additives: AdditiveRepository(dataSource: FileAdditiveDataSource()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(productRepository: repository),
      ),
    );

    expect(find.text('nutricheck'), findsOneWidget);
    expect(find.text('Katalog & Hasil Pencarian'), findsOneWidget);
  });
}
