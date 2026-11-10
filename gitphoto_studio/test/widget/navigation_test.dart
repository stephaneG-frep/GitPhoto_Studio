import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/shared/widgets/pixel_mascot.dart';

import 'test_app.dart';

void main() {
  testWidgets('téléphone : barre inférieure et navigation principale', (
    tester,
  ) async {
    await pumpStudio(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('GitPhoto Studio IA'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byType(PixelMascot),
      300,
      scrollable: contentScrollable(),
    );
    expect(find.byType(PixelMascot), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Galerie'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Votre bibliothèque est vide'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Galerie')),
      findsOneWidget,
    );
  });

  testWidgets('téléphone : « Plus » ouvre le menu complet', (tester) async {
    await pumpStudio(tester);

    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    final drawer = find.byType(NavigationDrawer);
    expect(drawer, findsOneWidget);

    await tester.tap(
      find.descendant(of: drawer, matching: find.text('Historique')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Historique'),
      ),
      findsOneWidget,
    );
    // L'écran secondaire sélectionne l'entrée « Plus ».
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppDestination.primary.length);
  });

  testWidgets('ordinateur : menu latéral permanent avec les neuf écrans', (
    tester,
  ) async {
    await pumpStudio(tester, size: desktopSize);

    expect(find.byType(NavigationBar), findsNothing);
    final drawer = find.byType(NavigationDrawer);
    expect(drawer, findsOneWidget);
    expect(
      find.descendant(
        of: drawer,
        matching: find.byType(NavigationDrawerDestination),
      ),
      findsNWidgets(9),
    );

    await tester.tap(
      find.descendant(of: drawer, matching: find.text('GitHub')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connexion par le navigateur'), findsOneWidget);
  });

  testWidgets('chaque écran s\'ouvre depuis son URL sans erreur', (
    tester,
  ) async {
    for (final d in AppDestination.values) {
      await pumpStudio(tester, size: desktopSize, location: d.path);
      expect(tester.takeException(), isNull, reason: d.path);
      final drawer = tester.widget<NavigationDrawer>(
        find.byType(NavigationDrawer),
      );
      expect(drawer.selectedIndex, d.index, reason: d.path);
    }
  });

  testWidgets('les raccourcis du tableau de bord naviguent', (tester) async {
    await pumpStudio(tester, size: desktopSize);
    await tester.scrollUntilVisible(
      find.widgetWithText(ActionChip, 'Mode d\'emploi'),
      200,
      scrollable: contentScrollable(),
    );
    await tester.tap(find.widgetWithText(ActionChip, 'Mode d\'emploi'));
    await tester.pumpAndSettle();
    expect(find.text('Parcours guidé'), findsOneWidget);
  });
}
