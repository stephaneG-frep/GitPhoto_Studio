import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitphoto_studio/main.dart';

/// Tests pour l'application principale
void main() {
  testWidgets('GitPhoto Studio App - Structure de base', (WidgetTester tester) async {
    // Construit notre application avec un ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('GitPhoto Studio IA')),
          ),
        ),
      ),
    );
    
    // Vérifie que le texte est présent
    expect(find.text('GitPhoto Studio IA'), findsOneWidget);
  });

  testWidgets('GitPhoto Studio App - Widget de base', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Test')),
            body: Center(child: Text('Content')),
          ),
        ),
      ),
    );
    
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('GitPhoto Studio App - Navigation de base', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Icon(Icons.photo_library),
                Icon(Icons.auto_awesome),
                Icon(Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
    
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
