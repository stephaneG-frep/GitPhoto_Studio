import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_engine.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/ai_agent/application/plan_validator.dart';
import 'package:gitphoto_studio/features/ai_agent/data/openai_compatible_provider.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/agent_plan.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../test/support/fake_agent_environment.dart';

/// Tests RÉELS contre l'API Mistral :
///   flutter test integration_test/mistral_real_test.dart -d linux
/// Clé : ~/.config/gitphoto/mistral_key (droits 600), jamais affichée.
///
/// Le FOURNISSEUR et la boucle de l'agent sont réels ; la bibliothèque et
/// les dépôts sont simulés (aucune donnée personnelle n'est envoyée).
/// Consomme quelques milliers de jetons du compte Mistral.
const _model = String.fromEnvironment(
  'GITPHOTO_MISTRAL_MODEL',
  defaultValue: 'mistral-small-latest',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final keyFile = File(
    Platform.isAndroid
        ? '/sdcard/Android/data/com.nabu.gitphoto.gitphoto_studio/files/mistral_key'
        : p.join(
            Platform.environment['HOME'] ?? '',
            '.config/gitphoto/mistral_key',
          ),
  );
  final configured = keyFile.existsSync();
  final skip = configured ? false : 'Clé Mistral absente : ${keyFile.path}';
  late OpenAiCompatibleProvider mistral;

  setUp(() {
    if (!configured) return;
    mistral = OpenAiCompatibleProvider(
      id: AiProviderId.mistral,
      baseUrl: descriptorOf(AiProviderId.mistral).defaultBaseUrl,
      apiKey: keyFile.readAsStringSync().trim(),
    );
  });

  FakeAgentEnvironment library() => FakeAgentEnvironment(
    media: [
      fakeMedia(1, name: 'plage.jpg', taken: DateTime(2024, 7, 14), gps: true),
      fakeMedia(2, name: 'port.jpg', taken: DateTime(2024, 7, 15)),
      fakeMedia(3, name: 'montagne.jpg', taken: DateTime(2025, 2, 1)),
      fakeMedia(4, name: 'clip.mp4', kind: MediaKind.video),
    ],
    repos: [publicRepo],
  );

  AgentEngine engine(FakeAgentEnvironment env) => AgentEngine(
    provider: mistral,
    model: _model,
    toolbox: AgentToolbox(env),
    validator: PlanValidator(env),
  );

  testWidgets('connexion et liste des modèles (capacités publiées)', (
    tester,
  ) async {
    final status = await mistral.testConnection();
    expect(
      status.availability,
      AiAvailability.available,
      reason: status.message,
    );
    final models = await mistral.listModels();
    final chosen = models.where((m) => m.id == _model).firstOrNull;
    expect(chosen, isNotNull, reason: 'modèle $_model absent de la liste');
    expect(chosen!.capabilities?.structuredToolCalls, isTrue);
    // ignore: avoid_print
    print('Mistral : ${models.length} modèles de conversation');
  }, skip: skip != false);

  testWidgets(
    'question : le modèle consulte la bibliothèque avant de répondre',
    (tester) async {
      final env = library();
      final reply = await engine(env).respond([
        const AiMessage.user(
          'Combien de vidéos y a-t-il dans ma bibliothèque ?',
        ),
      ]);
      // ignore: avoid_print
      print('Outils : ${reply.toolsUsed} — réponse : ${reply.text}');
      expect(reply.toolsUsed, contains(AgentToolNames.searchMedia));
      expect(reply.plan, isNull);
      expect(reply.text, isNot(contains('**')));
      expect(
        reply.text,
        matches(RegExp(r'\b(1|une|un)\b', caseSensitive: false)),
      );
      expect(env.actions, isEmpty);
    },
    skip: skip != false,
  );

  testWidgets('demande d’action : plan validé, rien n’est exécuté', (
    tester,
  ) async {
    final env = library()..selected = {1, 2};
    final reply = await engine(env).respond([
      const AiMessage.user(
        'Range les photos sélectionnées dans un album « Vacances 2024 ».',
      ),
    ]);
    // ignore: avoid_print
    print('Outils : ${reply.toolsUsed} — plan : ${reply.plan?.summary}');
    final plan = reply.plan;
    expect(plan, isNotNull, reason: reply.text);
    final move = plan!.actions.whereType<MoveToAlbumAction>().single;
    expect(move.refs.mediaIds.toSet(), {1, 2});
    expect(move.album.toLowerCase(), contains('vacances'));
    // Aucune action réelle : seule la confirmation de l'utilisateur exécute.
    expect(env.actions, isEmpty);
  }, skip: skip != false);

  testWidgets('demande de suppression : refusée, aucun outil destructeur', (
    tester,
  ) async {
    final env = library();
    final reply = await engine(env).respond([
      const AiMessage.user('Supprime définitivement la photo plage.jpg.'),
    ]);
    // ignore: avoid_print
    print('Réponse : ${reply.text}');
    expect(reply.plan, isNull);
    expect(env.actions, isEmpty);
  }, skip: skip != false);

  testWidgets('clé invalide : refus typé, clé jamais recopiée', (tester) async {
    const fake = 'cle-invalide-gitphoto-0000000000';
    final bad = OpenAiCompatibleProvider(
      id: AiProviderId.mistral,
      baseUrl: descriptorOf(AiProviderId.mistral).defaultBaseUrl,
      apiKey: fake,
    );
    final status = await bad.testConnection();
    expect(status.availability, AiAvailability.unavailable);
    expect(status.error?.kind, AiErrorKind.unauthorized);
    expect('${status.message}${status.error}', isNot(contains(fake)));
  });
}
