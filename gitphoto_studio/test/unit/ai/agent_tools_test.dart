import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_executor.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/gallery/application/media_importer.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';
import 'package:gitphoto_studio/features/publishing/data/operations_repository.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/features/publishing/domain/transport_selector.dart';

import '../../support/fake_agent_environment.dart';

void main() {
  late FakeAgentEnvironment env;
  late AgentToolbox tools;

  setUp(() {
    env = FakeAgentEnvironment(
      media: [
        fakeMedia(1, name: 'plage.jpg', gps: true, albumId: 3),
        fakeMedia(2, name: 'plage-copie.jpg'),
        fakeMedia(3, name: 'clip.mp4', kind: MediaKind.video),
      ],
      repos: [publicRepo, readOnlyRepo],
    )..albumList.add(const Album(id: 3, name: 'Voyage', count: 1));
    tools = AgentToolbox(env);
  });

  Future<Map<String, Object?>> run(
    String name, [
    Map<String, Object?>? a,
  ]) async =>
      jsonDecode(await tools.run(name, a ?? const {})) as Map<String, Object?>;

  test(
    'sélection : uniquement les médias existants, avec leurs métadonnées',
    () async {
      env.selected = {1, 99};
      final r = await run(AgentToolNames.getSelection);
      expect(r['count'], 1);
      final item = (r['items']! as List).single as Map;
      expect(item['name'], 'plage.jpg');
      expect(item['album'], 'Voyage');
      expect(item['gps'], isTrue);
      // Jamais de chemin local transmis au modèle.
      expect(jsonEncode(r), isNot(contains('/nulle-part')));
    },
  );

  test('albums et doublons probables (filtrés par identifiants)', () async {
    expect((await run(AgentToolNames.listAlbums))['albums'], [
      {'name': 'Voyage', 'count': 1},
    ]);
    env.similar = [
      [env.media(1)!, env.media(2)!],
    ];
    final all = await run(AgentToolNames.findSimilar);
    expect((all['groups']! as List).single, hasLength(2));
    final none = await run(AgentToolNames.findSimilar, {
      'ids': [3],
    });
    expect(none['groups'], isEmpty);
  });

  test('historique : échecs seulement, erreurs et fichiers', () async {
    env.ops = [
      OperationRecord(
        id: 2,
        kind: 'publish',
        status: OperationStatus.failed,
        createdAt: DateTime(2026, 11, 9),
        files: const [],
        repository: 'testeur/Portfolio',
        branch: 'main',
        error: 'GitHub refuse le jeton',
        entries: const [
          QueueEntry(
            id: 1,
            operationId: 2,
            remotePath: 'a.jpg',
            strategy: 'githubApi',
            status: EntryStatus.failed,
            overwrite: false,
            lastError: '401',
          ),
        ],
      ),
      OperationRecord(
        id: 1,
        kind: 'publish',
        status: OperationStatus.success,
        createdAt: DateTime(2026, 11, 8),
        files: const [],
        commitSha: 'abc',
      ),
    ];
    final failed = await run(AgentToolNames.recentOperations, {
      'failed_only': true,
    });
    final list = failed['operations']! as List;
    expect(list, hasLength(1));
    final op = list.single as Map;
    expect(op['error'], 'GitHub refuse le jeton');
    expect(((op['files'] as List).single as Map)['error'], '401');
    final all = await run(AgentToolNames.recentOperations, {'limit': 5});
    expect(all['operations'], hasLength(2));
    expect(
      (await run(AgentToolNames.recentOperations, {
        'limit': 'beaucoup',
      }))['error'],
      contains('entier'),
    );
  });

  test('aperçu de publication : transport, renommage, blocage, GPS', () async {
    PlannedFile file(
      int id,
      PlannedAction action, {
      PublishStrategy s = PublishStrategy.githubApi,
      BlockReason? block,
    }) => PlannedFile(
      candidate: PublishCandidate(
        mediaId: id,
        fileName: 'f$id',
        localPath: '/x/$id',
        sizeBytes: id * 1000,
        gitBlobSha: 'sha$id',
        hasGps: id == 1,
      ),
      remotePath: 'voyage/f$id',
      action: action,
      strategy: s,
      blockReason: block,
    );
    env.previewPlan = PublishPlan(
      files: [
        file(1, PlannedAction.add),
        file(2, PlannedAction.renamed, s: PublishStrategy.gitLfs),
        file(3, PlannedAction.blocked, block: BlockReason.tooLargeForLfs),
      ],
      folder: 'voyage',
      repositoryIsEmpty: false,
      remoteTreeTruncated: false,
    );
    final r = await run(AgentToolNames.previewPublication, {
      'media_ids': [1, 2, 3],
      'repository': 'testeur/portfolio',
      'folder': 'voyage',
    });
    expect(r['repository'], 'testeur/Portfolio');
    expect(r['branch'], 'main');
    final files = (r['files']! as List).cast<Map<String, Object?>>();
    expect(files[0]['gps'], isTrue);
    expect(files[1]['transport'], 'gitLfs');
    expect(files[1]['action'], 'renamed');
    expect(files[2]['blocked'], 'tooLargeForLfs');
    expect(env.actions.single, 'analyze testeur/Portfolio@main:voyage');

    // Dossier dangereux refusé avant tout appel à GitHub.
    env.actions.clear();
    final bad = await run(AgentToolNames.previewPublication, {
      'media_ids': [1],
      'repository': 'testeur/Portfolio',
      'folder': '../../etc',
    });
    expect(bad['error'], contains('dossier'));
    expect(env.actions, isEmpty);
    // Média inconnu.
    final missing = await run(AgentToolNames.previewPublication, {
      'media_ids': [42],
      'repository': 'testeur/Portfolio',
    });
    expect(missing['error'], contains('42'));
  });

  test('GitHub déconnecté pendant un aperçu : erreur expliquée', () async {
    final offline = AgentToolbox(
      FakeAgentEnvironment(media: [fakeMedia(1)], login: null),
    );
    final r =
        jsonDecode(
              await offline.run(AgentToolNames.previewPublication, {
                'media_ids': [1],
                'repository': 'a/b',
              }),
            )
            as Map;
    expect(r['error'], contains('GitHub'));
  });

  test('outil inconnu : refusé', () async {
    expect((await run('delete_everything'))['error'], contains('inconnu'));
  });

  group('exécution : conversion vidéo', () {
    AgentPlan plan(List<int> ids) => AgentPlan(
      summary: 's',
      actions: [ConvertVideosAction(mediaIds: ids, preset: VideoPreset.light)],
    );

    test('conversion indisponible : échec clair, rien lancé', () async {
      final e = FakeAgentEnvironment(
        media: [fakeMedia(3, kind: MediaKind.video)],
        videoSupported: false,
      );
      final r = await PlanExecutor(e).run(plan([3]));
      expect(r.steps.single.status, StepStatus.failed);
      expect('${r.steps.single.error}', contains('indisponible'));
      expect(e.actions, isEmpty);
    });

    test('réussite partielle : copies vérifiées, échecs listés', () async {
      final e =
          FakeAgentEnvironment(
              media: [
                fakeMedia(3, kind: MediaKind.video, name: 'a.mp4'),
                fakeMedia(4, kind: MediaKind.video, name: 'b.mp4'),
                fakeMedia(10, kind: MediaKind.video, name: 'a-leger.mp4'),
              ],
            )
            ..onConvert = (v) => v.id == 3
                ? ImportItemResult(
                    'a-leger.mp4',
                    ImportOutcome.imported,
                    mediaId: 10,
                  )
                : ImportItemResult(
                    'b.mp4',
                    ImportOutcome.failed,
                    error: 'pas plus petit',
                  );
      final r = await PlanExecutor(e).run(plan([3, 4]));
      final step = r.steps.single;
      expect(step.status, StepStatus.partial);
      expect(step.produced, [10]);
      expect(step.failures.single, contains('pas plus petit'));
      expect(r.succeeded, isTrue);
    });

    test('copie annoncée mais absente de la bibliothèque : signalée', () async {
      final e =
          FakeAgentEnvironment(media: [fakeMedia(3, kind: MediaKind.video)])
            ..onConvert = (_) =>
                ImportItemResult('x', ImportOutcome.imported, mediaId: 77);
      final r = await PlanExecutor(e).run(plan([3]));
      expect(r.steps.single.status, StepStatus.failed);
      expect(r.steps.single.failures.single, contains('introuvables'));
    });
  });
}
