import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/database/preferences_repository.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';

import '../support/fake_github_server.dart';
import '../support/fake_secret_store.dart';
import 'test_app.dart';

Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Opération interrompue (application fermée pendant l'envoi).
int interruptedOperation(AppDatabase db, LibraryPaths paths, String content) {
  final f = File('${paths.mediaDir}/a.jpg')..writeAsStringSync(content);
  final mediaId = MediaRepository(db).insert(
    NewMedia(
      fileName: 'a.jpg',
      storedPath: f.path,
      sourcePath: f.path,
      kind: MediaKind.image,
      sizeBytes: content.length,
      sha256: sha256.convert(utf8.encode(content)).toString(),
      importedAt: DateTime(2025),
    ),
  );
  final ops = OperationsRepository(db);
  final repoId = ops.upsertRepository(owner: 'testeur', name: 'album');
  final id = ops.enqueue(
    repositoryId: repoId,
    branch: 'main',
    commitMessage: 'Envoi interrompu',
    entries: [
      QueueEntryInput(
        mediaId: mediaId,
        remotePath: 'p/a.jpg',
        strategy: 'githubApi',
        gitBlobSha: gitBlobSha(utf8.encode(content)),
        sizeBytes: content.length,
      ),
    ],
  );
  ops.setStatus(id, OperationStatus.running);
  ops.markInterrupted();
  return id;
}

void main() {
  late AppDatabase db;
  late FakeGithubServer server;
  late FakeSecretStore store;

  setUp(() {
    db = AppDatabase.inMemory();
    server = FakeGithubServer();
    store = FakeSecretStore()
      ..values[SecretKeys.githubToken] = server.validToken;
  });

  testWidgets('historique : reprise d\'une publication interrompue', (
    tester,
  ) async {
    final repo = server.addRepo('testeur', 'album');
    final paths = createTestLibraryPaths();
    final id = interruptedOperation(db, paths, 'AAA');
    await pumpStudio(
      tester,
      size: desktopSize,
      location: '/history',
      database: db,
      libraryPaths: paths,
      secretStore: store,
      github: server,
    );

    expect(find.textContaining('Interrompue'), findsOneWidget);
    await tester.tap(find.text('Envoi interrompu'));
    await tester.pumpAndSettle();
    expect(find.textContaining('relit d\'abord GitHub'), findsOneWidget);
    await tester.tap(find.text('Reprendre'));
    await settleUntil(
      tester,
      () =>
          OperationsRepository(db).find(id)!.status == OperationStatus.success,
    );
    expect(utf8.decode(repo.filesOf('main')['p/a.jpg']!), 'AAA');
    expect(find.textContaining('Réussie'), findsOneWidget);
    expect(find.textContaining('Publié · API'), findsOneWidget);
  });

  testWidgets('historique : annulation confirmée', (tester) async {
    server.addRepo('testeur', 'album');
    final paths = createTestLibraryPaths();
    final id = interruptedOperation(db, paths, 'BBB');
    await pumpStudio(
      tester,
      size: desktopSize,
      location: '/history',
      database: db,
      libraryPaths: paths,
      secretStore: store,
      github: server,
    );

    await tester.tap(find.text('Envoi interrompu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Annuler cette publication ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(
      OperationsRepository(db).find(id)!.status,
      OperationStatus.cancelled,
    );
    expect(find.textContaining('Annulée'), findsOneWidget);
  });

  testWidgets('paramètres : options de publication mémorisées', (tester) async {
    await pumpStudio(
      tester,
      size: desktopSize,
      location: '/settings',
      database: db,
      secretStore: store,
      github: server,
    );
    await tester.scrollUntilVisible(
      find.text('Git LFS pour les fichiers de plus de 50 Mio'),
      200,
      scrollable: contentScrollable(),
    );
    final lfs = find.widgetWithText(
      SwitchListTile,
      'Git LFS pour les fichiers de plus de 50 Mio',
    );
    expect(tester.widget<SwitchListTile>(lfs).value, isTrue);
    await tester.tap(lfs);
    await tester.pumpAndSettle();
    expect(PreferencesRepository(db).read('publish.lfs_enabled'), 'false');

    final git = find.widgetWithText(
      SwitchListTile,
      'Publier avec le Git de l\'ordinateur',
    );
    await tester.scrollUntilVisible(git, 200, scrollable: contentScrollable());
    await tester.tap(git);
    await tester.pumpAndSettle();
    expect(PreferencesRepository(db).read('publish.prefer_native_git'), 'true');
  });
}
