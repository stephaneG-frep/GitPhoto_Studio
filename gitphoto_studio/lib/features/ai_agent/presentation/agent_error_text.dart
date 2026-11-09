import 'package:flutter/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../github/presentation/github_error_text.dart';
import '../application/agent_engine.dart';
import '../domain/ai_provider.dart';

/// Message compréhensible pour une erreur de l'agent ou d'un fournisseur.
String describeAgentError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AgentLoopException) return l10n.aiErrLoop;
  if (error is! AiException) return describeError(context, error);
  final base = switch (error.kind) {
    AiErrorKind.unauthorized => l10n.aiErrUnauthorized,
    AiErrorKind.forbidden => l10n.aiErrForbidden,
    AiErrorKind.notFound => l10n.aiErrNotFound,
    AiErrorKind.rateLimited => l10n.aiErrRateLimited,
    AiErrorKind.badRequest => l10n.aiErrBadRequest,
    AiErrorKind.toolsUnsupported => l10n.aiErrToolsUnsupported,
    AiErrorKind.network => l10n.aiErrNetwork,
    AiErrorKind.timeout => l10n.aiErrTimeout,
    AiErrorKind.server => l10n.aiErrServer,
    AiErrorKind.invalidResponse => l10n.aiErrInvalid,
    AiErrorKind.notConfigured => l10n.aiErrNotConfigured,
  };
  // Le détail renvoyé par le fournisseur (déjà expurgé) aide à corriger.
  final showDetail = switch (error.kind) {
    AiErrorKind.badRequest ||
    AiErrorKind.forbidden ||
    AiErrorKind.notFound ||
    AiErrorKind.network ||
    AiErrorKind.toolsUnsupported => error.message.isNotEmpty,
    _ => false,
  };
  return showDetail ? '$base\n${l10n.aiErrDetail(error.message)}' : base;
}
