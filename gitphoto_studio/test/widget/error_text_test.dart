import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_engine.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';
import 'package:gitphoto_studio/features/ai_agent/presentation/agent_error_text.dart';
import 'package:gitphoto_studio/features/github/data/device_flow.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/presentation/github_error_text.dart';
import 'package:gitphoto_studio/features/publishing/application/publish_queue.dart';
import 'package:gitphoto_studio/features/publishing/application/publisher.dart';
import 'package:gitphoto_studio/features/publishing/domain/publish_plan.dart';
import 'package:gitphoto_studio/l10n/generated/app_localizations.dart';

/// Chaque erreur possible reçoit un message compréhensible, dans les deux
/// langues, sans détail technique brut quand ce n'est pas utile.
void main() {
  Future<List<String>> describeAll(
    WidgetTester tester,
    String lang,
    List<Object> errors, {
    bool agent = false,
  }) async {
    late List<String> out;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            out = [
              for (final e in errors)
                agent
                    ? describeAgentError(context, e)
                    : describeError(context, e),
            ];
            return const SizedBox();
          },
        ),
      ),
    );
    return out;
  }

  final githubErrors = <Object>[
    for (final k in GithubErrorKind.values) GithubException(k, 'détail-$k'),
    GithubException(
      GithubErrorKind.rateLimited,
      'x',
      resetAt: DateTime(2026, 1, 1, 14, 30),
    ),
    for (final e in DeviceFlowError.values) DeviceFlowException(e, 'cfg'),
    const PublishCancelled(),
    const DuplicatePublicationException('photos/a.jpg'),
    const PublishConflictException('photos/b.jpg'),
    StateError('imprévu'),
  ];

  for (final lang in ['fr', 'en']) {
    testWidgets('[$lang] erreurs GitHub et publication : messages distincts', (
      tester,
    ) async {
      final texts = await describeAll(tester, lang, githubErrors);
      for (final (i, t) in texts.indexed) {
        expect(t.trim(), isNotEmpty, reason: '${githubErrors[i]}');
      }
      // Chaque catégorie a son propre message.
      final byKind = texts.take(GithubErrorKind.values.length).toSet();
      expect(byKind.length, GithubErrorKind.values.length);
      // Les détails utiles sont repris, pas pour un jeton refusé.
      final unauthorized = texts[GithubErrorKind.unauthorized.index];
      expect(unauthorized, isNot(contains('détail')));
      expect(texts[GithubErrorKind.validation.index], contains('détail'));
      expect(texts.any((t) => t.contains('14:30')), isTrue);
      expect(texts.where((t) => t.contains('photos/a.jpg')), hasLength(1));
      expect(texts.where((t) => t.contains('photos/b.jpg')), hasLength(1));
    });

    testWidgets('[$lang] erreurs de l’agent IA : messages distincts', (
      tester,
    ) async {
      final errors = <Object>[
        for (final k in AiErrorKind.values) AiException(k, 'info-$k'),
        const AgentLoopException('boucle'),
        const GithubException(GithubErrorKind.notFound, 'x'),
      ];
      final texts = await describeAll(tester, lang, errors, agent: true);
      final byKind = texts.take(AiErrorKind.values.length).toSet();
      expect(byKind.length, AiErrorKind.values.length);
      // Détail du fournisseur montré quand il aide à corriger.
      expect(texts[AiErrorKind.badRequest.index], contains('info-'));
      expect(texts[AiErrorKind.unauthorized.index], isNot(contains('info-')));
      expect(texts[AiErrorKind.rateLimited.index], isNot(contains('info-')));
      // Une erreur GitHub passe par le traducteur GitHub.
      expect(texts.last, isNot(contains('GithubException')));
    });
  }
}
