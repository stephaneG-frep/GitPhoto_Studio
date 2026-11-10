import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitphoto_studio/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/destinations.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/migrations.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';

import '../support/fake_secret_store.dart';
import 'test_app.dart';

void main() {
  testWidgets('le tableau de bord affiche les compteurs réels de la base', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    for (var i = 0; i < 3; i++) {
      db.raw.execute(
        'INSERT INTO media(source_path, file_name, size_bytes, imported_at) '
        'VALUES(?, ?, 10, 0)',
        ['/x/$i.jpg', '$i.jpg'],
      );
    }
    const q =
        'INSERT INTO transfer_queue(idempotency_key, remote_path, '
        'strategy, status, created_at, updated_at) VALUES(?, ?, ?, ?, 0, 0)';
    db.raw.execute(q, ['a', 'a.jpg', 'githubApi', 'pending']);
    db.raw.execute(q, ['b', 'b.jpg', 'githubApi', 'done']);
    db.raw.execute(
      'INSERT INTO repositories(owner, name, is_active, added_at) '
      "VALUES('alice', 'portfolio', 1, 0)",
    );

    await pumpStudio(tester, size: desktopSize, database: db);

    expect(
      find.textContaining('alice/portfolio', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('3'), matching: find.byType(Card)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: find.text('1'), matching: find.byType(Card)),
      findsOneWidget,
    );
  });

  testWidgets('tableau de bord vide : aucun dépôt connecté', (tester) async {
    await pumpStudio(tester, size: desktopSize);
    expect(
      find.textContaining('Aucun dépôt connecté', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('plus aucun écran « en préparation » : les neuf sont réels', (
    tester,
  ) async {
    for (final d in AppDestination.values) {
      await pumpStudio(tester, size: desktopSize, location: d.path);
      expect(find.text('En préparation'), findsNothing, reason: d.path);
      expect(
        find.textContaining('Prévu en phase'),
        findsNothing,
        reason: d.path,
      );
      expect(tester.takeException(), isNull, reason: d.path);
    }
  });

  testWidgets('paramètres : le thème choisi est appliqué et enregistré', (
    tester,
  ) async {
    final db = await pumpStudio(
      tester,
      size: desktopSize,
      location: AppDestination.settings.path,
    );

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(PreferencesRepository(db).read(PreferenceKeys.themeMode), 'dark');
  });

  testWidgets('paramètres : passage en anglais', (tester) async {
    final db = await pumpStudio(
      tester,
      size: desktopSize,
      location: AppDestination.settings.path,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Gallery'), findsOneWidget);
    expect(PreferencesRepository(db).read(PreferenceKeys.locale), 'en');
  });

  testWidgets('les préférences enregistrées sont restaurées au démarrage', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    PreferencesRepository(db)
      ..write(PreferenceKeys.themeMode, 'light')
      ..write(PreferenceKeys.locale, 'en');

    await pumpStudio(tester, size: desktopSize, database: db);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Accueil'), findsNothing);
  });

  testWidgets('paramètres : IA désactivée par défaut, Mistral prioritaire', (
    tester,
  ) async {
    await pumpStudio(
      tester,
      size: desktopSize,
      location: AppDestination.settings.path,
    );
    final enable = find.widgetWithText(
      SwitchListTile,
      "Activer l'assistant IA",
    );
    await tester.scrollUntilVisible(
      enable,
      200,
      scrollable: contentScrollable(),
    );
    expect(tester.widget<SwitchListTile>(enable).value, isFalse);
    await tester.tap(enable);
    await tester.pumpAndSettle();
    // Mistral est sélectionné par défaut, avec la mention « Prioritaire ».
    expect(find.text('Mistral AI · Prioritaire'), findsOneWidget);
    expect(find.text('Aucune clé enregistrée'), findsOneWidget);
    await tester.tap(find.text('Mistral AI · Prioritaire'));
    await tester.pumpAndSettle();
    final mistral = tester.getTopLeft(
      find.text('Mistral AI · Prioritaire').last,
    );
    final openAi = tester.getTopLeft(find.text('OpenAI').last);
    expect(mistral.dy, lessThan(openAi.dy));
  });

  testWidgets('diagnostic : versions détectées affichées', (tester) async {
    await pumpStudio(
      tester,
      size: desktopSize,
      location: AppDestination.settings.path,
    );
    await tester.scrollUntilVisible(
      find.text('git version 2.34.1'),
      200,
      scrollable: contentScrollable(),
    );
    expect(find.text('git version 2.34.1'), findsOneWidget);
    // Git LFS et ffmpeg absents dans la détection simulée.
    expect(find.text('Non détecté'), findsNWidgets(2));
    expect(find.text('Schéma v$latestSchemaVersion'), findsOneWidget);
  });

  testWidgets('diagnostic : état d\'erreur avec bouton Réessayer', (
    tester,
  ) async {
    var attempts = 0;
    await pumpStudio(
      tester,
      size: desktopSize,
      location: AppDestination.settings.path,
      toolsOverride: toolAvailabilityProvider.overrideWith((ref) async {
        attempts++;
        throw Exception('sonde indisponible');
      }),
    );
    final retry = find.widgetWithText(TextButton, 'Réessayer');
    await tester.scrollUntilVisible(
      retry,
      200,
      scrollable: contentScrollable(),
    );
    expect(find.textContaining('sonde indisponible'), findsOneWidget);
    expect(attempts, 1);

    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('diagnostic : indicateur de chargement', (tester) async {
    final completer = Completer<ToolAvailability>();
    tester.view.physicalSize = desktopSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase.inMemory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          secretStoreProvider.overrideWithValue(FakeSecretStore()),
          toolAvailabilityProvider.overrideWith((ref) => completer.future),
        ],
        child: const GitPhotoStudioApp(initialLocation: '/settings'),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Chargement…'),
      200,
      scrollable: contentScrollable(),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const ToolAvailability(supportsExternalTools: false));
    await tester.pumpAndSettle();
    expect(find.text('Non applicable sur cette plateforme'), findsNWidgets(3));
  });
}
