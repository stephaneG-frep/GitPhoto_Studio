import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_info.dart';
import '../../../app/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/secrets/secret_store.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../ai_agent/application/ai_settings.dart';
import '../../gallery/application/gallery_providers.dart';
import '../../github/application/github_session.dart';
import '../../publishing/application/publish_controller.dart';
import '../application/diagnostics.dart';

/// Rapport de diagnostic, journal technique et export des paramètres.
class DiagnosticTools extends ConsumerWidget {
  const DiagnosticTools({super.key});

  static String versionLabel() => '${AppInfo.version}+${AppInfo.buildNumber}';

  Future<String> _report(WidgetRef ref, String locale) async {
    final db = ref.read(appDatabaseProvider);
    final ops = ref.read(operationsProvider);
    final byStatus = <String, int>{};
    for (final o in ops) {
      byStatus[o.status.name] = (byStatus[o.status.name] ?? 0) + 1;
    }
    final ai = await ref.read(aiSettingsProvider.future);
    final storeOk =
        await ref.read(secretStoreProvider).status() ==
        SecretStoreStatus.available;
    return buildDiagnosticReport(
      DiagnosticInput(
        appVersion: versionLabel(),
        platform: defaultTargetPlatform.name,
        osVersion: kIsWeb ? 'web' : Platform.operatingSystemVersion,
        locale: locale,
        schemaVersion: db.schemaVersion,
        mediaCount: db.count('media'),
        libraryBytes: ref.read(mediaRepositoryProvider).librarySizeBytes(),
        operationsByStatus: byStatus,
        queuedEntries: db.count(
          'transfer_queue',
          where: "status IN ('pending', 'uploaded')",
        ),
        tools: ref.read(toolAvailabilityProvider).value,
        githubConnected:
            ref.read(githubSessionProvider).value is GithubConnected,
        secretStoreAvailable: storeOk,
        aiEnabled: ai.enabled,
        aiProvider: ai.descriptor.displayName,
        aiModel: ai.model,
        aiHasKey: ai.hasKey,
        aiConsent: ai.consent,
        log: ref.read(loggerProvider).entries,
      ),
    );
  }

  String _export(WidgetRef ref) => exportSettings(
    ref.read(preferencesProvider).readAll(),
    appVersion: versionLabel(),
  );

  static Future<void> _copy(BuildContext context, String text) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(l10n.diagCopied)));
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final location = await getSaveLocation(
      suggestedName: 'gitphoto_parametres.json',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return;
    await File(location.path).writeAsString(_export(ref), flush: true);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsExportSaved(location.path))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final desktop =
        !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(l10n.diagReport),
            subtitle: Text(l10n.diagReportHelp),
            trailing: TextButton(
              onPressed: () async {
                final text = await _report(ref, locale);
                if (context.mounted) await _copy(context, text);
              },
              child: Text(l10n.diagReportCopy),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.diagLog),
            subtitle: Text(l10n.diagLogHelp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _LogDialog(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l10n.settingsExport),
            subtitle: Text(l10n.settingsExportHelp),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(context, _export(ref)),
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.settingsExportCopy),
                ),
                if (desktop)
                  OutlinedButton.icon(
                    onPressed: () => _save(context, ref),
                    icon: const Icon(Icons.save_alt),
                    label: Text(l10n.settingsExportSave),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogDialog extends ConsumerWidget {
  const _LogDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entries = ref.read(loggerProvider).entries.reversed.toList();
    final time = DateFormat.Hms();
    String line(LogEntry e) =>
        '${time.format(e.time)} [${e.level.name}] ${e.message}';
    return AlertDialog(
      title: Text(l10n.diagLog),
      content: SizedBox(
        width: 640,
        height: 420,
        child: entries.isEmpty
            ? Center(child: Text(l10n.diagLogEmpty))
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      line(e),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: switch (e.level) {
                          LogLevel.error => theme.colorScheme.error,
                          LogLevel.warning => theme.colorScheme.tertiary,
                          _ => null,
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: entries.isEmpty
              ? null
              : () => DiagnosticTools._copy(
                  context,
                  entries.reversed.map(line).join('\n'),
                ),
          child: Text(l10n.diagLogCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonBack),
        ),
      ],
    );
  }
}
