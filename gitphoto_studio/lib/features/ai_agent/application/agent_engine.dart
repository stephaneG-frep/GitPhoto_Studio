import 'dart:convert';

import '../domain/agent_plan.dart';
import '../domain/ai_provider.dart';
import 'agent_tools.dart';
import 'plan_validator.dart';

/// Réponse de l'agent à un message de l'utilisateur.
class AgentReply {
  const AgentReply({
    required this.text,
    required this.transcript,
    this.plan,
    this.toolsUsed = const [],
  });

  /// Texte affiché à l'utilisateur.
  final String text;

  /// Plan validé, en attente de confirmation (jamais exécuté ici).
  final AgentPlan? plan;

  /// Outils de consultation appelés, dans l'ordre.
  final List<String> toolsUsed;

  /// Messages à ajouter à l'historique du modèle (appels d'outils et
  /// résultats compris), pour garder un échange cohérent.
  final List<AiMessage> transcript;
}

class AgentLoopException implements Exception {
  const AgentLoopException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AgentCancelled implements Exception {
  const AgentCancelled();
}

/// Boucle de dialogue avec le modèle :
/// 1. le modèle consulte librement les outils **en lecture seule** ;
/// 2. pour toute modification, il doit appeler `propose_plan` : le plan est
///    validé puis rendu à l'interface, qui demande la confirmation ;
/// 3. l'exécution n'a jamais lieu dans cette boucle.
class AgentEngine {
  AgentEngine({
    required this.provider,
    required this.model,
    required this.toolbox,
    required this.validator,
    this.useTools = true,
    this.maxRounds = 8,
    this.maxPlanAttempts = 3,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AiProvider provider;
  final String model;
  final AgentToolbox toolbox;
  final PlanValidator validator;

  /// `false` pour un modèle sans appels d'outils : simple conversation.
  final bool useTools;
  final int maxRounds;
  final int maxPlanAttempts;
  final DateTime Function() _now;

  /// Rappel envoyé quand le modèle décrit un plan en texte.
  static const planReminder =
      '[Note de l’application : tu as décrit un plan ou demandé une '
      'confirmation dans ton texte. L’utilisateur ne peut valider qu’un plan '
      'proposé avec l’outil propose_plan : appelle-le maintenant, sans '
      'redemander de confirmation.]';

  static final _textPlan = RegExp(
    r'voici (le|un|mon) plan|plan propos|confirmez[- ]vous|'
    r'voulez[- ]vous que je|souhaitez[- ]vous que je|je vais (publier|ranger|'
    r'optimiser|convertir|cr[ée]er)|here is (the|my) plan|shall i|'
    r'do you (want|confirm)|should i (proceed|go ahead)',
    caseSensitive: false,
  );

  /// Texte qui annonce un plan ou demande une confirmation au lieu
  /// d'appeler `propose_plan`.
  static bool looksLikeTextPlan(String text) => _textPlan.hasMatch(text);

  /// Messages conservés pour le modèle (les plus récents).
  static const maxHistoryMessages = 40;

  String systemPrompt() {
    final today = _now().toIso8601String().substring(0, 10);
    return '''
Tu es l'assistant de GitPhoto Studio IA, une application qui gère une bibliothèque locale de photos et vidéos et les publie dans des dépôts GitHub.
Date du jour : $today.

Règles impératives :
- Réponds dans la langue de l'utilisateur, brièvement et clairement, pour un débutant.
- Écris en texte simple, sans Markdown (pas d'astérisques, de titres ni de tableaux) : l'écran ne le met pas en forme.
${useTools ? '''- Consulte les outils de lecture (search_media, get_selection, list_albums, find_similar_media, github_status, recent_operations, preview_publication) au lieu de deviner. N'invente jamais d'identifiant de média ni de nom de dépôt.
- « Ces photos » désigne la sélection de la galerie (get_selection).
- Pour TOUTE modification (albums, optimisation, conversion, publication), appelle propose_plan. Rien n'est exécuté sans la confirmation de l'utilisateur ; ne prétends jamais avoir exécuté quelque chose.
- N'écris JAMAIS un plan dans ton texte et ne demande pas « Confirmez-vous ? » : appelle directement propose_plan. L'application affiche le plan et les boutons de confirmation ; l'utilisateur ne peut valider qu'un plan proposé par cet outil.
- Tu ne peux ni supprimer de fichier, ni remplacer un fichier existant sur GitHub, ni exécuter de commande. Si on te le demande, explique que ce n'est pas possible ici.
- Avant de publier, vérifie le dépôt avec github_status. Les optimisations créent des copies sans métadonnées (donc sans position GPS) : propose-les si des photos à publier contiennent une position GPS.
- Les fichiers de plus de 50 Mo passent par Git LFS automatiquement (jusqu'à 2 Go).
- Pour expliquer un échec, consulte recent_operations et traduis l'erreur en langage simple, avec la marche à suivre.''' : '''- Ce modèle ne sait pas appeler d'outils : tu ne peux ni consulter la bibliothèque ni agir. Réponds aux questions générales et invite l'utilisateur à choisir un modèle compatible dans les paramètres pour les actions.'''}
- Seules les métadonnées (noms, tailles, dates, albums) te sont transmises, jamais le contenu des images.
''';
  }

  /// Ne garde que les messages récents, en commençant par un message de
  /// l'utilisateur (sans couper une suite appel d'outil / résultat).
  static List<AiMessage> trimHistory(List<AiMessage> history) {
    if (history.length <= maxHistoryMessages) return history;
    var start = history.length - maxHistoryMessages;
    while (start < history.length && history[start].role != AiRole.user) {
      start++;
    }
    return history.sublist(start);
  }

  Future<AgentReply> respond(
    List<AiMessage> history, {
    void Function(String toolName)? onTool,
    bool Function()? isCancelled,
  }) async {
    final messages = <AiMessage>[
      AiMessage.system(systemPrompt()),
      ...trimHistory(history),
    ];
    final transcript = <AiMessage>[];
    final toolsUsed = <String>[];
    var planAttempts = 0;
    var nudged = false;

    for (var round = 0; round < maxRounds; round++) {
      if (isCancelled?.call() ?? false) throw const AgentCancelled();
      final response = await provider.chat(
        AiChatRequest(
          model: model,
          // Copie figée : l'historique continue d'évoluer ensuite.
          messages: List.unmodifiable(messages),
          tools: useTools ? agentToolSpecs : const [],
        ),
      );
      if (isCancelled?.call() ?? false) throw const AgentCancelled();
      final msg = response.message;
      messages.add(msg);
      transcript.add(msg);
      if (msg.toolCalls.isEmpty &&
          useTools &&
          !nudged &&
          looksLikeTextPlan(msg.content)) {
        // Plan décrit en texte au lieu de propose_plan : l'utilisateur
        // n'aurait aucun bouton pour le valider. Rappel unique, invisible.
        nudged = true;
        const reminder = AiMessage.user(planReminder);
        messages.add(reminder);
        transcript.add(reminder);
        continue;
      }
      if (msg.toolCalls.isEmpty || !useTools) {
        return AgentReply(
          text: msg.content.trim(),
          transcript: transcript,
          toolsUsed: toolsUsed,
        );
      }

      AgentPlan? plan;
      for (final call in msg.toolCalls) {
        final String result;
        if (call.argumentsError != null) {
          result = jsonEncode({
            'error': 'Arguments illisibles : ${call.argumentsError}',
          });
        } else if (call.name == AgentToolNames.proposePlan) {
          planAttempts++;
          if (plan != null) {
            result = jsonEncode({'error': 'Un seul plan à la fois.'});
          } else {
            switch (await validator.validate(call.arguments)) {
              case ValidPlan(plan: final p):
                plan = p;
                result = jsonEncode({
                  'ok': true,
                  'status':
                      "Plan présenté à l'utilisateur, en attente de sa "
                      'confirmation. Rien n’a encore été exécuté.',
                });
              case InvalidPlan(:final errors):
                result = jsonEncode({'ok': false, 'errors': errors});
            }
          }
        } else if (AgentToolNames.readOnly.contains(call.name)) {
          toolsUsed.add(call.name);
          onTool?.call(call.name);
          result = await toolbox.run(call.name, call.arguments);
        } else {
          // Le modèle n'a accès à rien d'autre.
          result = jsonEncode({'error': 'Outil inconnu : ${call.name}'});
        }
        final toolMsg = AiMessage.toolResult(
          callId: call.id,
          name: call.name,
          content: result,
        );
        messages.add(toolMsg);
        transcript.add(toolMsg);
      }

      if (plan != null) {
        // Clôt l'échange par un message de l'assistant : certains
        // fournisseurs refusent un message utilisateur après un résultat
        // d'outil.
        final text = msg.content.trim().isNotEmpty
            ? msg.content.trim()
            : plan.summary;
        transcript.add(AiMessage.assistant(text));
        return AgentReply(
          text: text,
          plan: plan,
          transcript: transcript,
          toolsUsed: toolsUsed,
        );
      }
      if (planAttempts >= maxPlanAttempts) {
        throw const AgentLoopException(
          "Le modèle n'a pas réussi à proposer un plan valide.",
        );
      }
    }
    throw const AgentLoopException(
      "Le modèle n'a pas conclu dans le nombre d'étapes autorisé.",
    );
  }
}
