// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Widget Test - Test de base Flutter', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test Widget')),
          ),
        ),
      ),
    );

    // Verify that the widget loads correctly
    expect(find.text('Test Widget'), findsOneWidget);
  });

  testWidgets('Widget Test - Boutons et interactions', (WidgetTester tester) async {
    bool tapped = false;
    
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    
    // Tap the button
    await tester.tap(find.text('Tap Me'));
    await tester.pump();
    
    expect(tapped, true);
  });
}
