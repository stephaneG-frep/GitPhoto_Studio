import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/core/platform/tool_probe.dart';
import 'package:gitphoto_studio/core/secrets/secret_store.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_environment.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_executor.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_validator.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/gallery/application/gallery_providers.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/library_paths.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_queue.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:path/path.dart' as p;

import '../../support/fake_github_server.dart';
import '../../support/fake_secret_store.dart';
import '../../support/media_fixtures.dart';

/// Exécution d'un plan avec les VRAIS services de l'application (albums,
/// optimisation d'images, file de publication) ; seul GitHub est simulé.
void main() {
  late Directory root;
  late AppDatabase db;
  late FakeGithubServer server;
  late FakeRepo repo;
  late ProviderContainer container;
  late AgentEnvironment env;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('gitphoto_agent_');
    db = AppDatabase.inMemory();
    server = FakeGithubServer();
    repo = server.addRepo('testeur', 'album');
    final store = FakeSecretStore()
      ..values[SecretKeys.githubToken] = server.validToken;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        libraryPathsProvider.overrideWithValue(
          LibraryPaths(
            root: p.join(root.path, 'support'),
            temporaryDir: p.join(root.path, 'cache'),
          )..ensureCreated(),
        ),
        toolAvailabilityProvider.overrideWith(
          (ref) async => const ToolAvailability(supportsExternalTools: false),
        ),
        secretStoreProvider.overrideWithValue(store),
        githubApiFactoryProvider.overrideWithValue(server.api),
        lfsClientFactoryProvider.overrideWithValue(server.lfs),
        agentEnvironmentProvider.overrideWith(
          (ref) => AppAgentEnvironment(
            ref,
            documentsDir: () async => p.join(root.path, 'docs'),
          ),
        ),
      ],
    );
    container.listen(publishQueueProvider, (_, _) {});
    await container.read(toolAvailabilityProvider.future);
    await container.read(githubSessionProvider.future);
    env = container.read(agentEnvironmentProvider);
  });

  tearDown(() {
    container.dispose();
    db.close();
    root.deleteSync(recursive: true);
  });

  Future<int> importJpeg(String name, {bool gps = false, String? date}) async {
    final src = writeFile(
      Directory(p.join(root.path, 'src')),
      name,
      makeJpeg(
        width: 900,
        height: 600,
        seed: name.length,
        gps: gps,
        dateTimeOriginal: date,
      ),
    );
    final r = await container
        .read(mediaImporterProvider)
        .importOne(ImportCandidate(src.path));
    expect(r.outcome, ImportOutcome.imported, reason: r.error);
    return r.mediaId!;
  }

  Future<AgentPlan> validPlan(List<Map<String, Object?>> steps) async {
    final v = await PlanValidator(
      env,
    ).validate({'summary': 'Plan de test', 'steps': steps});
    if (v is InvalidPlan) fail('Plan refusé : ${v.errors}');
    return (v as ValidPlan).plan;
  }

  test(
    'optimiser, ranger par date puis publier copies + README : vérifié',
    () async {
      final a = await importJpeg(
        'plage.jpg',
        gps: true,
        date: '2024:07:14 10:00:00',
      );
      final b = await importJpeg('port.jpg', date: '2024:08:01 09:00:00');
      expect(env.media(a)!.hasGps, isTrue);

      final plan = await validPlan([
        {
          'type': 'optimize_images',
          'media_ids': [a, b],
          'preset': 'thumbnail',
        },
        {
          'type': 'organize_by_date',
          'media_ids': [a, b],
          'granularity': 'month',
        },
        {
          'type': 'publish',
          'from_steps': [1],
          'repository': 'testeur/album',
          'folder': 'voyage',
          'message': 'Album de voyage',
          'readme': '# Voyage\n\nDeux photos.',
        },
      ]);
      final progress = <int>[];
      final report = await PlanExecutor(
        env,
      ).run(plan, onProgress: (step, _, _, _) => progress.add(step));

      expect(report.succeeded, isTrue, reason: report.describeForModel());
      expect(progress.toSet(), {0, 1, 2});

      // 1. Deux copies réelles, plus petites, sans position GPS, liées
      //    à leur original.
      final copies = report.steps[0].produced;
      expect(copies, hasLength(2));
      for (final id in copies) {
        final m = env.media(id)!;
        expect(m.hasGps, isFalse);
        expect(m.derivedFrom, anyOf(a, b));
        expect(m.width! <= 400 && m.height! <= 400, isTrue);
        expect(File(m.storedPath).existsSync(), isTrue);
      }
      // Les originaux sont conservés.
      expect(File(env.media(a)!.storedPath).existsSync(), isTrue);

      // 2. Albums par mois de prise de vue.
      final albums = {for (final x in env.albums()) x.id: x.name};
      expect(albums[env.media(a)!.albumId], '2024-07');
      expect(albums[env.media(b)!.albumId], '2024-08');
      expect(report.steps[1].albums, containsAll(['2024-07', '2024-08']));

      // 3. Un seul commit, vérifié, contenant les copies et le README.
      final pub = report.steps[2];
      expect(pub.publishResult!.verified, isTrue);
      expect(pub.publishResult!.commitCount, 1);
      final files = repo.filesOf('main');
      expect(
        utf8.decode(files['voyage/README.md']!),
        '# Voyage\n\nDeux photos.',
      );
      for (final id in copies) {
        final m = env.media(id)!;
        expect(
          files['voyage/${m.fileName}'],
          File(m.storedPath).readAsBytesSync(),
        );
      }
      // Le README du dépôt (racine) n'est pas touché.
      expect(utf8.decode(files['README.md']!), '# album\n');

      // Historique : l'opération figure avec ses trois fichiers.
      final op = OperationsRepository(db).list().first;
      expect(op.status, OperationStatus.success);
      expect(op.entries, hasLength(3));
      expect(
        op.entries.firstWhere((e) => e.mediaId == null).remotePath,
        'voyage/README.md',
      );

      // Rejouer le même plan : copies identiques réutilisées, rien à
      // republier, aucun nouveau commit.
      final head = repo.branches['main'];
      final again = await PlanExecutor(env).run(plan);
      expect(again.succeeded, isTrue);
      expect(again.steps[0].produced.toSet(), copies.toSet());
      expect(again.steps[2].alreadyPublished, isTrue);
      expect(repo.branches['main'], head);
    },
  );

  test(
    'README à la racine : renommé, l’existant n’est jamais remplacé',
    () async {
      final plan = await validPlan([
        {
          'type': 'publish',
          'repository': 'testeur/album',
          'message': 'Nouveau README',
          'readme': '# Autre contenu',
        },
      ]);
      final report = await PlanExecutor(env).run(plan);
      expect(report.succeeded, isTrue, reason: report.describeForModel());
      expect(report.steps.single.renamed, 1);
      final files = repo.filesOf('main');
      expect(utf8.decode(files['README.md']!), '# album\n');
      expect(
        files.entries.where((e) => utf8.decode(e.value) == '# Autre contenu'),
        hasLength(1),
      );
    },
  );

  test('échec d’une étape : les suivantes ne sont pas exécutées', () async {
    final a = await importJpeg('a.jpg');
    final plan = await validPlan([
      {
        'type': 'publish',
        'media_ids': [a],
        'repository': 'testeur/album',
        'branch': 'branche-inexistante',
        'message': 'm',
      },
      {
        'type': 'move_to_album',
        'media_ids': [a],
        'album': 'Après',
      },
    ]);
    final report = await PlanExecutor(env).run(plan);
    expect(report.succeeded, isFalse);
    expect(report.steps[0].status, StepStatus.failed);
    expect(report.steps[0].error, isNotNull);
    expect(report.steps[1].status, StepStatus.skipped);
    expect(env.media(a)!.albumId, isNull);
    expect(env.albums(), isEmpty);
  });

  test('arrêt demandé : rien n’est lancé après', () async {
    final a = await importJpeg('a.jpg');
    final plan = await validPlan([
      {
        'type': 'move_to_album',
        'media_ids': [a],
        'album': 'Un',
      },
      {
        'type': 'move_to_album',
        'media_ids': [a],
        'album': 'Deux',
      },
    ]);
    var calls = 0;
    final report = await PlanExecutor(
      env,
    ).run(plan, isCancelled: () => ++calls > 1);
    expect(report.cancelled, isTrue);
    expect(report.steps.map((s) => s.status), [
      StepStatus.done,
      StepStatus.cancelled,
    ]);
    final albums = {for (final x in env.albums()) x.id: x.name};
    expect(albums[env.media(a)!.albumId], 'Un');
  });

  test(
    'média retiré entre la proposition et la confirmation : échec net',
    () async {
      final a = await importJpeg('a.jpg');
      final plan = await validPlan([
        {
          'type': 'move_to_album',
          'media_ids': [a],
          'album': 'X',
        },
      ]);
      container.read(importControllerProvider.notifier).removeMedia([a]);
      final report = await PlanExecutor(env).run(plan);
      expect(report.steps.single.status, StepStatus.failed);
      expect('${report.steps.single.error}', contains('retiré'));
    },
  );
}
