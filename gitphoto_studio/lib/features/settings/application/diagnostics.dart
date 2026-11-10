import 'dart:convert';

import '../../../core/logging/app_logger.dart';
import '../../../core/platform/tool_probe.dart';
import '../../../core/security/secret_redactor.dart';

/// Préfixes des préférences exportables : uniquement des choix d'affichage
/// et de fonctionnement. Les secrets ne sont de toute façon jamais dans
/// SQLite ; l'identifiant client OAuth (`github.*`) est exclu par prudence.
const exportablePrefixes = ['ui.', 'gallery.', 'publish.', 'ai.'];

final _sensitive = RegExp(
  r'token|secret|password|\.key$',
  caseSensitive: false,
);

/// Export JSON des paramètres non sensibles.
String exportSettings(Map<String, String> prefs, {required String appVersion}) {
  final kept = <String, String>{
    for (final e in prefs.entries)
      if (exportablePrefixes.any(e.key.startsWith) &&
          !_sensitive.hasMatch(e.key))
        e.key: e.value,
  };
  return const JsonEncoder.withIndent('  ').convert({
    'application': 'GitPhoto Studio IA',
    'version': appVersion,
    'settings': Map.fromEntries(
      kept.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
  });
}

class DiagnosticInput {
  const DiagnosticInput({
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.locale,
    required this.schemaVersion,
    required this.mediaCount,
    required this.libraryBytes,
    required this.operationsByStatus,
    required this.queuedEntries,
    required this.tools,
    required this.githubConnected,
    required this.secretStoreAvailable,
    required this.aiEnabled,
    required this.aiProvider,
    required this.aiModel,
    required this.aiHasKey,
    required this.aiConsent,
    required this.log,
  });

  final String appVersion;
  final String platform;
  final String osVersion;
  final String locale;
  final int schemaVersion;
  final int mediaCount;
  final int libraryBytes;
  final Map<String, int> operationsByStatus;
  final int queuedEntries;
  final ToolAvailability? tools;
  final bool githubConnected;
  final bool secretStoreAvailable;
  final bool aiEnabled;
  final String aiProvider;
  final String? aiModel;
  final bool aiHasKey;
  final bool aiConsent;
  final List<LogEntry> log;
}

/// Rapport texte à joindre à une demande d'aide. Il ne contient que des
/// compteurs et des états : aucun jeton, aucune clé, aucun nom de compte,
/// de dépôt ni de fichier (les messages du journal n'y figurent pas).
String buildDiagnosticReport(DiagnosticInput i) {
  String yes(bool v) => v ? 'oui' : 'non';
  String tool(String? version) => switch (i.tools) {
    null => 'détection en cours',
    ToolAvailability(supportsExternalTools: false) => 'non applicable',
    _ => version ?? 'non détecté',
  };
  final levels = <LogLevel, int>{};
  for (final e in i.log) {
    levels[e.level] = (levels[e.level] ?? 0) + 1;
  }
  final ops = i.operationsByStatus.entries.map((e) => '${e.key} ${e.value}');
  final report =
      '''
GitPhoto Studio IA — rapport de diagnostic
Version : ${i.appVersion}
Plateforme : ${i.platform} (${i.osVersion})
Langue : ${i.locale}
Base de données : schéma v${i.schemaVersion}
Bibliothèque : ${i.mediaCount} média(s), ${i.libraryBytes} octets
Publications : ${ops.isEmpty ? 'aucune' : ops.join(', ')}
Fichiers en file d'attente : ${i.queuedEntries}
Git : ${tool(i.tools?.gitVersion)}
Git LFS (outil) : ${tool(i.tools?.gitLfsVersion)}
ffmpeg : ${tool(i.tools?.ffmpegVersion)}
Trousseau sécurisé : ${i.secretStoreAvailable ? 'disponible' : 'indisponible'}
GitHub connecté : ${yes(i.githubConnected)}
IA activée : ${yes(i.aiEnabled)}
Fournisseur IA : ${i.aiProvider}
Modèle IA : ${i.aiModel ?? '-'}
Clé IA enregistrée : ${yes(i.aiHasKey)}
Accord d'envoi IA : ${yes(i.aiConsent)}
Journal (session) : ${LogLevel.values.map((l) => '${l.name} ${levels[l] ?? 0}').join(', ')}
''';
  // Défense en profondeur : rien ne doit ressembler à un secret.
  return SecretRedactor.redact(report);
}
