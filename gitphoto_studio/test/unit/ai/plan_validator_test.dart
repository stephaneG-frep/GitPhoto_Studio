import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_validator.dart';
import 'package:gitphoto_studio/features/ai_agent/application/tool_args.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/media_editor/domain/optimization.dart';

import '../../support/fake_agent_environment.dart';

void main() {
  late FakeAgentEnvironment env;
  late PlanValidator validator;

  setUp(() {
    env = FakeAgentEnvironment(
      media: [
        fakeMedia(1, gps: true),
        fakeMedia(2),
        fakeMedia(3, kind: MediaKind.video, name: 'clip.mp4'),
      ],
      repos: [publicRepo, readOnlyRepo],
    );
    validator = PlanValidator(env);
  });

  Future<PlanValidation> validate(List<Map<String, Object?>> steps) =>
      validator.validate({'summary': 'Résumé', 'steps': steps});

  List<String> errorsOf(PlanValidation v) => (v as InvalidPlan).errors;

  test(
    'plan complet valide : optimisation puis publication des copies',
    () async {
      final v = await validate([
        {
          'type': 'optimize_images',
          'media_ids': [1, '2'],
          'preset': 'light',
        },
        {
          'type': 'publish',
          'from_steps': [1],
          'repository': 'TESTEUR/portfolio',
          'folder': '/voyage/2025/',
          'message': 'Ajout du voyage',
          'readme': '# Voyage',
        },
      ]);
      final plan = (v as ValidPlan).plan;
      final opt = plan.actions[0] as OptimizeImagesAction;
      expect(opt.mediaIds, [1, 2]);
      expect(opt.preset, ImagePreset.light);
      final pub = plan.actions[1] as PublishAction;
      // Dépôt résolu parmi les dépôts réellement accessibles (casse ignorée).
      expect(pub.repo.fullName, 'testeur/Portfolio');
      expect(pub.branch, 'main');
      expect(pub.folder, 'voyage/2025');
      expect(pub.refs.fromSteps, [0]);
      expect(pub.readme, '# Voyage');
      // Les copies optimisées n'ont plus de GPS : seul « dépôt public » reste.
      expect(plan.warnings.map((w) => w.kind), [
        PlanWarningKind.publicRepository,
      ]);
    },
  );

  test(
    'originaux avec GPS publiés : avertissement calculé par l’application',
    () async {
      final v = await validate([
        {
          'type': 'publish',
          'media_ids': [1, 2],
          'repository': 'testeur/Portfolio',
          'message': 'm',
        },
      ]);
      final w = (v as ValidPlan).plan.warnings.firstWhere(
        (w) => w.kind == PlanWarningKind.gpsInPublishedFiles,
      );
      expect(w.count, 1);
    },
  );

  test('identifiants inventés par le modèle : refusés', () async {
    final v = await validate([
      {
        'type': 'move_to_album',
        'media_ids': [1, 999],
        'album': 'Voyage',
      },
    ]);
    expect(errorsOf(v).single, contains('999'));
  });

  test('dépôt inconnu ou sans droit d’écriture : refusé', () async {
    final unknown = await validate([
      {
        'type': 'publish',
        'media_ids': [2],
        'repository': 'pirate/depot',
        'message': 'm',
      },
    ]);
    expect(errorsOf(unknown).single, contains('inconnu'));
    final readOnly = await validate([
      {
        'type': 'publish',
        'media_ids': [2],
        'repository': 'autre/lecture',
        'message': 'm',
      },
    ]);
    expect(errorsOf(readOnly).single, contains('écriture'));
  });

  test('chemins dangereux et branches invalides : refusés', () async {
    for (final folder in ['../hors', 'a/../../b', r'a\b', 'a//b', 'x/./y']) {
      final v = await validate([
        {
          'type': 'publish',
          'media_ids': [2],
          'repository': 'testeur/Portfolio',
          'folder': folder,
          'message': 'm',
        },
      ]);
      expect(v, isA<InvalidPlan>(), reason: folder);
    }
    for (final branch in [
      '../main',
      'a..b',
      '-x',
      'feat.lock',
      'a b',
      'HEAD',
    ]) {
      final v = await validate([
        {
          'type': 'publish',
          'media_ids': [2],
          'repository': 'testeur/Portfolio',
          'branch': branch,
          'message': 'm',
        },
      ]);
      expect(v, isA<InvalidPlan>(), reason: branch);
    }
  });

  test('types d’étape inconnus (suppression, commande…) : refusés', () async {
    for (final type in ['delete_media', 'run_shell', 'force_push', '']) {
      final v = await validate([
        {
          'type': type,
          'media_ids': [1],
        },
      ]);
      expect(v, isA<InvalidPlan>(), reason: type);
    }
  });

  test('mauvais types de média et valeurs hors liste', () async {
    final v1 = await validate([
      {
        'type': 'optimize_images',
        'media_ids': [3],
      },
    ]);
    expect(errorsOf(v1).single, contains('vidéos : 3'));
    final v2 = await validate([
      {
        'type': 'convert_videos',
        'media_ids': [1],
      },
    ]);
    expect(errorsOf(v2).single, contains('images : 1'));
    final v3 = await validate([
      {
        'type': 'optimize_images',
        'media_ids': [1],
        'preset': 'ultra',
      },
    ]);
    expect(errorsOf(v3).single, contains('preset'));
  });

  test(
    'références entre étapes : seulement vers une étape précédente qui produit des copies',
    () async {
      final forward = await validate([
        {
          'type': 'move_to_album',
          'from_steps': [2],
          'album': 'A',
        },
        {
          'type': 'optimize_images',
          'media_ids': [1],
        },
      ]);
      expect(errorsOf(forward).single, contains('ne précède pas'));
      final noCopies = await validate([
        {
          'type': 'move_to_album',
          'media_ids': [1],
          'album': 'A',
        },
        {
          'type': 'organize_by_date',
          'from_steps': [1],
        },
      ]);
      expect(errorsOf(noCopies).single, contains('ne produit pas'));
    },
  );

  test('structure invalide : messages précis pour corriger', () async {
    expect(
      errorsOf(await validator.validate({'summary': 'x'})).single,
      contains('steps'),
    );
    expect(
      errorsOf(
        await validator.validate({
          'summary': 'x',
          'steps': List.filled(11, {'type': 'organize_by_date'}),
        }),
      ).single,
      contains('10'),
    );
    final v = await validator.validate({
      'summary': 'x',
      'steps': <Object>[
        'pas un objet',
        {'type': 'move_to_album', 'media_ids': 'tout', 'album': 'A'},
        {
          'type': 'move_to_album',
          'media_ids': [1],
          'album': 'x' * 61,
        },
      ],
    });
    expect(errorsOf(v), hasLength(3));
  });

  test(
    'GitHub hors connexion : publication refusée avec explication',
    () async {
      final offline = PlanValidator(
        FakeAgentEnvironment(media: [fakeMedia(1)], login: null),
      );
      final v = await offline.validate({
        'summary': 's',
        'steps': [
          {
            'type': 'publish',
            'media_ids': [1],
            'repository': 'a/b',
            'message': 'm',
          },
        ],
      });
      expect(errorsOf(v).single, contains('GitHub indisponible'));
    },
  );

  test('conversion vidéo indisponible : avertissement', () async {
    final v =
        await PlanValidator(
          FakeAgentEnvironment(
            media: [fakeMedia(3, kind: MediaKind.video)],
            videoSupported: false,
          ),
        ).validate({
          'summary': 's',
          'steps': [
            {
              'type': 'convert_videos',
              'media_ids': [3],
              'preset': 'light',
            },
          ],
        });
    expect(
      (v as ValidPlan).plan.warnings.single.kind,
      PlanWarningKind.videoConversionUnavailable,
    );
  });

  group('lecture stricte des arguments', () {
    test('entiers : nombres, chaînes de chiffres ; refus du reste', () {
      expect(
        optIds({
          'x': [1, '2', 2.0, 1],
        }, 'x'),
        [1, 2],
      );
      for (final bad in [
        [0],
        [-1],
        ['abc'],
        [1.5],
        'tout',
      ]) {
        expect(
          () => optIds({'x': bad}, 'x'),
          throwsA(isA<ToolArgException>()),
          reason: '$bad',
        );
      }
    });

    test('textes : caractères de contrôle et longueur', () {
      expect(
        () => optString({'s': 'a\u0000b'}, 's'),
        throwsA(isA<ToolArgException>()),
      );
      expect(
        () => optString({'s': 'abc'}, 's', max: 2),
        throwsA(isA<ToolArgException>()),
      );
      expect(optString({'s': '  ok \n suite '}, 's'), 'ok \n suite');
    });

    test('dates', () {
      expect(optDate({'d': '2024-02-29'}, 'd'), DateTime(2024, 2, 29));
      for (final bad in ['2023-02-29', '2024-13-01', '24-01-01', 'hier']) {
        expect(
          () => optDate({'d': bad}, 'd'),
          throwsA(isA<ToolArgException>()),
          reason: bad,
        );
      }
    });
  });
}
