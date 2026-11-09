import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';

import '../support/fake_github_server.dart';
import '../support/fake_secret_store.dart';
import 'test_app.dart';

/// Laisse s'exécuter les entrées-sorties réelles (fichiers, isolats) puis
/// reconstruit l'interface, jusqu'à ce que [done] soit vrai.
Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

int addMedia(
  AppDatabase db,
  LibraryPaths paths,
  String name,
  String content, {
  bool gps = false,
}) {
  final f = File('${paths.mediaDir}/$name')..writeAsStringSync(content);
  return MediaRepository(db).insert(
    NewMedia(
      fileName: name,
      storedPath: f.path,
      sourcePath: '/src/$name',
      kind: MediaKind.image,
      mimeType: 'image/jpeg',
      sizeBytes: content.length,
      sha256: 'sha-$name',
      importedAt: DateTime(2025),
      hasGps: gps,
    ),
  );
}

void main() {
  late FakeGithubServer server;
  late FakeSecretStore store;
  late AppDatabase db;

  setUp(() {
    server = FakeGithubServer();
    store = FakeSecretStore();
    db = AppDatabase.inMemory();
  });

  Future<LibraryPaths> launch(
    WidgetTester tester,
    String location, {
    LibraryPaths? paths,
  }) async {
    final p = paths ?? createTestLibraryPaths();
    await pumpStudio(
      tester,
      size: desktopSize,
      location: location,
      database: db,
      libraryPaths: p,
      secretStore: store,
      github: server,
    );
    return p;
  }

  testWidgets('connexion par jeton : refus explicite puis succès', (
    tester,
  ) async {
    server.addRepo('testeur', 'portfolio');
    await launch(tester, '/github');

    await tester.enterText(find.byType(TextField).first, 'ghp_faux');
    await tester.tap(find.text('Vérifier et se connecter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GitHub refuse le jeton'), findsOneWidget);
    expect(store.values, isEmpty);

    await tester.enterText(find.byType(TextField).first, server.validToken);
    await tester.tap(find.text('Vérifier et se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connecté en tant que testeur'), findsOneWidget);
    expect(find.text('testeur/portfolio'), findsOneWidget);
    expect(store.values[SecretKeys.githubToken], server.validToken);
    // Le jeton n'apparaît nulle part à l'écran.
    expect(find.textContaining(server.validToken), findsNothing);
  });

  testWidgets('création d\'un dépôt public : double confirmation', (
    tester,
  ) async {
    store.values[SecretKeys.githubToken] = server.validToken;
    await launch(tester, '/github');

    await tester.tap(find.text('Nouveau dépôt'));
    await tester.pumpAndSettle();
    final create = find.widgetWithText(FilledButton, 'Créer');
    await tester.enterText(
      find.byType(TextField).last.evaluate().isEmpty
          ? find.byType(TextField).first
          : find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(TextField),
                )
                .first,
      'mauvais nom !',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    expect(find.textContaining('Lettres, chiffres'), findsOneWidget);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      'vacances',
    );
    await tester.tap(find.text('Public'));
    await tester.pump();
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Créer un dépôt public ?'), findsOneWidget);
    await tester.tap(find.text('Annuler').last);
    await tester.pumpAndSettle();
    expect(server.repos.containsKey('testeur/vacances'), isFalse);

    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui, créer un dépôt public'));
    await tester.pumpAndSettle();
    expect(server.repos['testeur/vacances']!.isPrivate, isFalse);
    expect(find.text('Dépôt testeur/vacances créé.'), findsOneWidget);
  });

  testWidgets('navigation dans un dépôt, dépôt actif', (tester) async {
    store.values[SecretKeys.githubToken] = server.validToken;
    server.addRepo(
      'testeur',
      'album',
      files: {
        'photos/2024/a.jpg': [1, 2, 3],
      },
    );
    await launch(tester, '/github');

    await tester.tap(find.text('testeur/album'));
    await tester.pumpAndSettle();
    expect(find.text('README.md'), findsOneWidget);
    await tester.tap(find.text('photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();
    expect(find.text('a.jpg'), findsOneWidget);
    expect(find.text('Initial commit'), findsOneWidget);

    await tester.tap(find.text('Définir comme dépôt actif'));
    await tester.pumpAndSettle();
    expect(OperationsRepository(db).activeRepository()!.name, 'album');
  });

  testWidgets('publication de bout en bout, historique et tableau de bord', (
    tester,
  ) async {
    store.values[SecretKeys.githubToken] = server.validToken;
    final repo = server.addRepo('testeur', 'album', isPrivate: false);
    final paths = createTestLibraryPaths();
    addMedia(db, paths, 'plage.jpg', 'PLAGE', gps: true);
    addMedia(db, paths, 'montagne.jpg', 'MONTAGNE');
    await launch(tester, '/publish', paths: paths);

    // 1. Médias.
    await tester.tap(find.text('Tout sélectionner').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('2 médias sélectionnés'), findsOneWidget);
    await tester.tap(find.text('Continuer').hitTestable());
    await tester.pumpAndSettle();

    // 2. Destination.
    await tester.tap(find.text('Choisir un dépôt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('testeur/album').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Dossier dans le dépôt'),
      '../x',
    );
    await tester.pump();
    expect(find.textContaining('Chemin invalide'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Dossier dans le dépôt'),
      'photos/2025',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer').hitTestable());
    await settleUntil(
      tester,
      () => find.textContaining('à envoyer').evaluate().isNotEmpty,
    );

    // 3. Analyse.
    expect(find.textContaining('2 à envoyer'), findsOneWidget);
    expect(find.textContaining('dépôt est public'), findsOneWidget);
    await tester.tap(find.text('Continuer').hitTestable());
    await tester.pumpAndSettle();

    // 4. Message.
    expect(find.text('Ajout de 2 médias via GitPhoto Studio'), findsOneWidget);
    await tester.tap(find.text('Continuer').hitTestable());
    await tester.pumpAndSettle();

    // 5. Vérification puis confirmation.
    expect(
      find.text('Tous les fichiers seront ajoutés en un seul commit.'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Publier sur GitHub').hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la publication ?'), findsOneWidget);
    expect(find.textContaining('(Public)'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Publier sur GitHub'),
      ),
    );
    await settleUntil(
      tester,
      () => find.text('Publication réussie').evaluate().isNotEmpty,
    );

    // 6. Résultat vérifié.
    expect(find.text('Publication réussie'), findsOneWidget);
    expect(find.textContaining('Vérifié'), findsOneWidget);
    final files = repo.filesOf('main');
    expect(utf8.decode(files['photos/2025/plage.jpg']!), 'PLAGE');
    expect(utf8.decode(files['photos/2025/montagne.jpg']!), 'MONTAGNE');

    final history = OperationsRepository(db).list();
    expect(history.single.status, OperationStatus.success);
    expect(history.single.commitSha, repo.branches['main']);
    expect(history.single.files, hasLength(2));

    // Historique affiché.
    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('Ajout de 2 médias via GitPhoto Studio'), findsOneWidget);
    expect(find.textContaining('testeur/album · main'), findsOneWidget);
  });

  testWidgets(
    'publication refusée (permission) : erreur expliquée et historisée',
    (tester) async {
      store.values[SecretKeys.githubToken] = server.validToken;
      final repo = server.addRepo('testeur', 'album');
      final paths = createTestLibraryPaths();
      addMedia(db, paths, 'a.jpg', 'A');
      await launch(
        tester,
        '/publish?owner=testeur&repo=album&branch=main&folder=p',
        paths: paths,
      );

      await tester.tap(find.text('Tout sélectionner').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer').hitTestable());
      await settleUntil(
        tester,
        () => find.textContaining('à envoyer').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Continuer').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer').hitTestable());
      await tester.pumpAndSettle();

      // Le jeton perd son droit d'écriture entre l'analyse et l'envoi.
      server.overrides[RegExp(r'^POST .*/git/blobs$')] = () =>
          FakeGithubServer.json(403, {
            'message': 'Resource not accessible by personal access token',
          });
      await tester.tap(
        find.widgetWithText(FilledButton, 'Publier sur GitHub').hitTestable(),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Publier sur GitHub'),
        ),
      );
      await settleUntil(
        tester,
        () => find.text('La publication a échoué').evaluate().isNotEmpty,
      );

      expect(find.textContaining('Permission insuffisante'), findsOneWidget);
      expect(repo.filesOf('main').containsKey('p/a.jpg'), isFalse);
      final op = OperationsRepository(db).list().single;
      expect(op.status, OperationStatus.failed);
      expect(op.error, contains('not accessible'));
    },
  );

  testWidgets('publication sans connexion : renvoi vers GitHub', (
    tester,
  ) async {
    await launch(tester, '/publish');
    expect(find.text('Connectez-vous à GitHub pour publier.'), findsOneWidget);
    await tester.tap(find.text('Aller à l\'écran GitHub'));
    await tester.pumpAndSettle();
    expect(find.text('Jeton d\'accès personnel (recommandé)'), findsOneWidget);
  });
}
