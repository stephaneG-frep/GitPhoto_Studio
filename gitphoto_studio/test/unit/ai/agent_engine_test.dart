import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_engine.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_validator.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';

import '../../support/fake_agent_environment.dart';
import '../../support/fake_ai.dart';

void main() {
  late FakeAgentEnvironment env;

  setUp(() {
    env = FakeAgentEnvironment(
      media: [
        fakeMedia(1, taken: DateTime(2024, 7, 14), gps: true),
        fakeMedia(2, taken: DateTime(2025, 3, 2), albumId: 7),
        fakeMedia(3, kind: MediaKind.video, name: 'clip.mp4'),
      ],
      repos: [publicRepo],
    )..albumList.add(const Album(id: 7, name: 'Voyage', count: 1));
  });

  AgentEngine engine(ScriptedProvider p) => AgentEngine(
    provider: p,
    model: 'mistral-small-latest',
    toolbox: AgentToolbox(env),
    validator: PlanValidator(env),
    now: () => DateTime(2026, 11, 9),
  );

  test('consultation puis plan : rien n’est exécuté, le plan attend', () async {
    env.selected = {1, 2};
    final p = ScriptedProvider([
      calls(AgentToolNames.getSelection, {}),
      calls(AgentToolNames.proposePlan, {
        'summary': 'Publier la sélection',
        'steps': [
          {
            'type': 'publish',
            'media_ids': [1, 2],
            'repository': 'testeur/Portfolio',
            'message': 'Ajout',
          },
        ],
      }, id: 'c2'),
    ]);
    final reply = await engine(
      p,
    ).respond([const AiMessage.user('Publie ces photos dans Portfolio')]);

    expect(reply.plan, isNotNull);
    expect(reply.plan!.actions.single, isA<PublishAction>());
    expect(reply.toolsUsed, [AgentToolNames.getSelection]);
    // Aucune action réelle pendant la conversation.
    expect(env.actions, isEmpty);

    // Le modèle a reçu les outils et le contenu réel de la sélection.
    final firstReq = p.requests.first;
    expect(firstReq.tools.map((t) => t.name), contains('propose_plan'));
    expect(firstReq.messages.first.role, AiRole.system);
    expect(firstReq.messages.first.content, contains('2026-11-09'));
    final sel = jsonDecode(p.requests[1].messages.last.content) as Map;
    expect(sel['count'], 2);
    expect((sel['items'] as List).first['gps'], isTrue);

    // L'échange se termine par un message de l'assistant (contrainte Mistral).
    expect(reply.transcript.last.role, AiRole.assistant);
    expect(reply.transcript.where((m) => m.role == AiRole.tool).length, 2);
  });

  test('plan invalide : erreurs renvoyées au modèle, qui corrige', () async {
    final p = ScriptedProvider([
      calls(AgentToolNames.proposePlan, {
        'summary': 'Ranger',
        'steps': [
          {
            'type': 'move_to_album',
            'media_ids': [42],
            'album': 'Été',
          },
        ],
      }),
      calls(AgentToolNames.proposePlan, {
        'summary': 'Ranger',
        'steps': [
          {
            'type': 'move_to_album',
            'media_ids': [1],
            'album': 'Été',
          },
        ],
      }, id: 'c2'),
    ]);
    final reply = await engine(p).respond([const AiMessage.user('Range')]);
    final firstResult =
        jsonDecode(p.requests[1].messages.last.content) as Map<String, Object?>;
    expect(firstResult['ok'], false);
    expect((firstResult['errors']! as List).single, contains('42'));
    expect((reply.plan!.actions.single as MoveToAlbumAction).album, 'Été');
  });

  test('trois plans invalides de suite : abandon explicite', () async {
    final bad = {
      'summary': 's',
      'steps': [
        {'type': 'delete_everything'},
      ],
    };
    final p = ScriptedProvider([
      for (var i = 0; i < 3; i++)
        calls(AgentToolNames.proposePlan, bad, id: 'c$i'),
    ]);
    await expectLater(
      engine(p).respond([const AiMessage.user('Supprime tout')]),
      throwsA(isA<AgentLoopException>()),
    );
    expect(env.actions, isEmpty);
  });

  test(
    'outil inexistant demandé par le modèle : refusé, aucune exécution',
    () async {
      final p = ScriptedProvider([
        calls('run_shell', {'cmd': 'rm -rf ~'}),
        says('Je ne peux pas faire cela.'),
      ]);
      final reply = await engine(p).respond([const AiMessage.user('x')]);
      expect(reply.text, 'Je ne peux pas faire cela.');
      final refused = jsonDecode(p.requests[1].messages.last.content) as Map;
      expect(refused['error'], contains('Outil inconnu'));
      expect(reply.toolsUsed, isEmpty);
      expect(env.actions, isEmpty);
    },
  );

  test('boucle sans fin : arrêtée au nombre maximal d’étapes', () async {
    final p = ScriptedProvider([
      for (var i = 0; i < 20; i++)
        calls(AgentToolNames.listAlbums, {}, id: 'c$i'),
    ]);
    await expectLater(
      engine(p).respond([const AiMessage.user('x')]),
      throwsA(isA<AgentLoopException>()),
    );
    expect(p.requests.length, 8);
  });

  test(
    'modèle sans outils : simple conversation, aucun outil proposé',
    () async {
      final p = ScriptedProvider([says('Bonjour !')], tools: false);
      final reply = await AgentEngine(
        provider: p,
        model: 'm',
        toolbox: AgentToolbox(env),
        validator: PlanValidator(env),
        useTools: false,
      ).respond([const AiMessage.user('Salut')]);
      expect(reply.text, 'Bonjour !');
      expect(p.requests.single.tools, isEmpty);
      expect(p.requests.single.messages.first.content, contains('ne sait pas'));
    },
  );

  test('annulation : la réponse arrivée après coup est ignorée', () async {
    var cancelled = false;
    final p = ScriptedProvider([
      (r) {
        cancelled = true;
        return const AiChatResponse(AiMessage.assistant('trop tard'));
      },
    ]);
    await expectLater(
      engine(
        p,
      ).respond([const AiMessage.user('x')], isCancelled: () => cancelled),
      throwsA(isA<AgentCancelled>()),
    );
  });

  test('historique tronqué sans couper une paire appel / résultat', () {
    final history = <AiMessage>[
      for (var i = 0; i < 30; i++) ...[
        AiMessage.user('q$i'),
        const AiMessage.assistant(
          '',
          toolCalls: [AiToolCall(id: 'x', name: 'list_albums', arguments: {})],
        ),
        const AiMessage.toolResult(
          callId: 'x',
          name: 'list_albums',
          content: '{}',
        ),
        AiMessage.assistant('r$i'),
      ],
    ];
    final trimmed = AgentEngine.trimHistory(history);
    expect(trimmed.length, lessThanOrEqualTo(AgentEngine.maxHistoryMessages));
    expect(trimmed.first.role, AiRole.user);
    expect(trimmed.last.content, 'r29');
  });

  group('outils de consultation', () {
    test('recherche : filtres type, album, dates, texte, pagination', () async {
      final tb = AgentToolbox(env);
      Future<Map<String, Object?>> run(Map<String, Object?> a) async =>
          jsonDecode(await tb.run(AgentToolNames.searchMedia, a))
              as Map<String, Object?>;

      expect((await run({'type': 'video'}))['total'], 1);
      expect((await run({'album': 'voyage'}))['total'], 1);
      expect((await run({'album': ''}))['total'], 2);
      expect((await run({'album': 'Inconnu'}))['note'], contains('inconnu'));
      expect(
        (await run({
          'taken_from': '2025-01-01',
          'taken_to': '2025-03-02',
        }))['total'],
        // Photo 2 (prise le 2 mars 2025) et la vidéo (importée le 1er janvier).
        2,
      );
      expect((await run({'text': 'CLIP'}))['total'], 1);
      final page = await run({'limit': 1, 'offset': 1});
      expect((page['items']! as List).length, 1);
      expect(page['total'], 3);
      expect((await run({'limit': 500}))['error'], contains('limit'));
    });

    test(
      'aperçu de publication : dépôt inconnu signalé, sans appel réseau',
      () async {
        final tb = AgentToolbox(env);
        final r =
            jsonDecode(
                  await tb.run(AgentToolNames.previewPublication, {
                    'media_ids': [1],
                    'repository': 'inconnu/x',
                  }),
                )
                as Map;
        expect(r['error'], contains('inconnu'));
        expect(env.actions, isEmpty);
      },
    );

    test('GitHub déconnecté : état clair', () async {
      final tb = AgentToolbox(FakeAgentEnvironment(login: null));
      final r =
          jsonDecode(await tb.run(AgentToolNames.githubStatus, {})) as Map;
      expect(r['connected'], false);
    });

    test('résultat trop long : tronqué avec consigne', () {
      final s = AgentToolbox.encodeResult({'x': 'a' * 20000});
      expect(s.length, lessThan(AgentToolbox.maxResultChars + 200));
      expect(jsonDecode(s)['truncated'], true);
    });

    test('secrets éventuels expurgés des résultats', () {
      final s = AgentToolbox.encodeResult({
        'error': 'token ghp_abcdefghijklmnopqrstuvwxyz0123456789 refusé',
      });
      expect(s, isNot(contains('ghp_abcdefghij')));
    });
  });

  test('chaque outil de consultation a un schéma, propose_plan en plus', () {
    expect(agentToolSpecs.map((t) => t.name).toSet(), {
      ...AgentToolNames.readOnly,
      AgentToolNames.proposePlan,
    });
  });
}
