import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';

import '../../support/fake_github_server.dart';
import '../../support/fake_secret_store.dart';

void main() {
  group('historique', () {
    late AppDatabase db;
    late OperationsRepository ops;
    setUp(() {
      db = AppDatabase.inMemory();
      ops = OperationsRepository(db);
    });
    tearDown(() => db.close());

    test('dépôts : insertion idempotente et dépôt actif unique', () {
      final a = ops.upsertRepository(
        owner: 'o',
        name: 'a',
        defaultBranch: 'main',
      );
      final again = ops.upsertRepository(
        owner: 'o',
        name: 'a',
        isPrivate: false,
      );
      final b = ops.upsertRepository(owner: 'o', name: 'b');
      expect(again, a);
      expect(ops.activeRepository(), isNull);
      ops.setActiveRepository(a);
      ops.setActiveRepository(b);
      expect(ops.activeRepository()!.name, 'b');
      expect(db.count('repositories', where: 'is_active = 1'), 1);
    });

    test('cycle de vie d\'une opération et interruption', () {
      final repo = ops.upsertRepository(owner: 'o', name: 'a');
      final ok = ops.start(
        kind: 'publish',
        repositoryId: repo,
        branch: 'main',
        commitMessage: 'm1',
        files: const [OperationFile('p/a.jpg', mediaId: null)],
      );
      ops.finish(
        ok,
        status: OperationStatus.success,
        commitSha: 'abc',
        htmlUrl: 'u',
      );
      ops.start(
        kind: 'publish',
        repositoryId: repo,
        branch: 'main',
        commitMessage: 'm2',
        files: const [OperationFile('p/b.jpg'), OperationFile('p/c.jpg')],
      );
      expect(ops.markInterrupted(), 1);
      expect(ops.markInterrupted(), 0);
      final list = ops.list();
      expect(list.map((o) => o.status), [
        OperationStatus.interrupted,
        OperationStatus.success,
      ]);
      expect(list.first.files.map((f) => f.remotePath), ['p/b.jpg', 'p/c.jpg']);
      expect(list.last.commitSha, 'abc');
      expect(list.last.repository, 'o/a');
    });
  });

  group('session GitHub', () {
    late FakeGithubServer server;
    late FakeSecretStore store;
    late ProviderContainer container;

    ProviderContainer make() => ProviderContainer(
      overrides: [
        secretStoreProvider.overrideWithValue(store),
        githubApiFactoryProvider.overrideWithValue(server.api),
        appDatabaseProvider.overrideWithValue(AppDatabase.inMemory()),
      ],
    );

    setUp(() {
      server = FakeGithubServer();
      store = FakeSecretStore();
    });
    tearDown(() => container.dispose());

    test('jeton refusé : jamais enregistré', () async {
      container = make();
      expect(
        await container.read(githubSessionProvider.future),
        isA<GithubDisconnected>(),
      );
      await expectLater(
        container.read(githubSessionProvider.notifier).connect('ghp_mauvais'),
        throwsA(
          isA<GithubException>().having(
            (e) => e.kind,
            'kind',
            GithubErrorKind.unauthorized,
          ),
        ),
      );
      expect(store.values, isEmpty);
    });

    test(
      'jeton valide : vérifié, stocké dans le trousseau, restauré',
      () async {
        container = make();
        await container.read(githubSessionProvider.future);
        final user = await container
            .read(githubSessionProvider.notifier)
            .connect('  ${server.validToken}\n');
        expect(user.login, 'testeur');
        expect(store.values[SecretKeys.githubToken], server.validToken);
        container.dispose();

        container = make();
        final restored = await container.read(githubSessionProvider.future);
        expect(restored, isA<GithubConnected>());
        expect(container.read(githubApiProvider), isNotNull);
      },
    );

    test('déconnexion : jeton effacé', () async {
      store.values[SecretKeys.githubToken] = server.validToken;
      container = make();
      await container.read(githubSessionProvider.future);
      await container.read(githubSessionProvider.notifier).disconnect();
      expect(store.values, isEmpty);
      expect(container.read(githubApiProvider), isNull);
    });

    test('jeton révoqué : état d\'erreur explicite', () async {
      store.values[SecretKeys.githubToken] = 'ghp_revoque';
      container = make();
      final s = await container.read(githubSessionProvider.future);
      expect(s, isA<GithubSessionError>());
      expect(
        (s as GithubSessionError).error.kind,
        GithubErrorKind.unauthorized,
      );
    });

    test('trousseau indisponible : signalé', () async {
      store.available = false;
      container = make();
      final s = await container.read(githubSessionProvider.future);
      expect((s as GithubDisconnected).storeUnavailable, isTrue);
    });
  });
}
