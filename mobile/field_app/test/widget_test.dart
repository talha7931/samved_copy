import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Road Nirman Field')),
      ),
    );
    expect(find.text('Road Nirman Field'), findsOneWidget);
  });
}
