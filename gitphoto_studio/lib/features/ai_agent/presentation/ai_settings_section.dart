import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/open_url.dart';
import '../application/agent_controller.dart';
import '../application/ai_settings.dart';
import '../domain/ai_provider.dart';
import 'agent_error_text.dart';

/// Paramètres de l'IA : activation, fournisseur, clé (trousseau du système),
/// modèle, test de connexion, accord d'envoi, conversations locales.
class AiSettingsSection extends ConsumerStatefulWidget {
  const AiSettingsSection({super.key});

  @override
  ConsumerState<AiSettingsSection> createState() => _AiSettingsSectionState();
}

class _AiSettingsSectionState extends ConsumerState<AiSettingsSection> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _baseUrl = TextEditingController();
  List<AiModelInfo>? _models;
  bool _working = false;
  String? _testMessage;
  bool? _testOk;
  AiProviderId? _shownProvider;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  AiSettingsController get _ctrl => ref.read(aiSettingsProvider.notifier);

  /// Remet le formulaire à jour quand le fournisseur change.
  void _sync(AiSettings s) {
    if (_shownProvider == s.provider) return;
    _shownProvider = s.provider;
    _model.text = s.model ?? '';
    _baseUrl.text = s.baseUrl;
    _models = null;
    _testMessage = null;
    _testOk = null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _test() => _run(() async {
    final l10n = AppLocalizations.of(context);
    try {
      final provider = await _ctrl.buildProvider();
      final status = await provider.testConnection();
      if (!mounted) return;
      setState(() {
        _testOk = status.availability == AiAvailability.available;
        _testMessage = _testOk!
            ? l10n.aiTestOk(status.message ?? '')
            : '${l10n.aiTestFailed}\n'
                  '${status.error == null ? status.message ?? '' : describeAgentError(context, status.error!)}';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage =
            '${l10n.aiTestFailed}\n${describeAgentError(context, e)}';
      });
    }
  });

  Future<void> _loadModels() => _run(() async {
    final l10n = AppLocalizations.of(context);
    try {
      final provider = await _ctrl.buildProvider();
      final models = await provider.listModels();
      if (mounted) setState(() => _models = models);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage =
            '${l10n.aiTestFailed}\n${describeAgentError(context, e)}';
      });
    }
  });

  Future<void> _deleteConversations() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiDeleteConversations),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.aiDeleteConversations),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(conversationRepositoryProvider).deleteAll();
    ref.read(agentControllerProvider.notifier).newConversation();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.aiDeleteConversationsDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(aiSettingsProvider);
    final s = settings.value;
    if (s == null) {
      return Card(
        child: settings.hasError
            ? ListTile(
                title: Text(describeAgentError(context, settings.error!)),
              )
            : const LinearProgressIndicator(),
      );
    }
    _sync(s);
    final d = s.descriptor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(l10n.aiEnable),
              subtitle: Text(l10n.aiEnableHelp),
              value: s.enabled,
              onChanged: _ctrl.setEnabled,
            ),
            if (s.enabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<AiProviderId>(
                  initialValue: s.provider,
                  decoration: InputDecoration(labelText: l10n.aiProvider),
                  items: [
                    for (final p in aiProviderCatalog)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          [
                            p.displayName,
                            if (p.id == defaultAiProvider)
                              l10n.aiProviderPriority,
                            if (p.isLocal) l10n.aiProviderLocal,
                          ].join(' · '),
                        ),
                      ),
                  ],
                  onChanged: _working
                      ? null
                      : (id) {
                          if (id != null) _ctrl.setProvider(id);
                        },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      d.verifiedForReal
                          ? Icons.verified
                          : Icons.science_outlined,
                      size: 18,
                      color: d.verifiedForReal
                          ? StudioColors.of(context).success
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        d.verifiedForReal
                            ? l10n.aiVerifiedReal
                            : l10n.aiNotVerifiedReal,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (d.requiresApiKey) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aiApiKey, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      if (s.storeUnavailable)
                        Text(
                          l10n.aiKeyStoreUnavailable,
                          style: TextStyle(color: theme.colorScheme.error),
                        )
                      else ...[
                        Text(
                          s.hasKey ? l10n.aiKeySaved : l10n.aiKeyMissing,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _key,
                          obscureText: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          enableIMEPersonalizedLearning: false,
                          decoration: InputDecoration(
                            hintText: l10n.aiKeyHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                      await _ctrl.saveKey(_key.text);
                                      _key.clear();
                                    }),
                              child: Text(l10n.aiKeySave),
                            ),
                            if (s.hasKey)
                              TextButton(
                                onPressed: _working
                                    ? null
                                    : () => _run(_ctrl.deleteKey),
                                child: Text(l10n.aiKeyDelete),
                              ),
                            TextButton.icon(
                              onPressed: () => openUrl(context, d.keyUrl),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: Text(l10n.aiKeyGet),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (d.isLocal) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _baseUrl,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.aiBaseUrl,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l10n.aiBaseUrlSave,
                        icon: const Icon(Icons.save_outlined),
                        onPressed: () {
                          if (!_ctrl.setBaseUrl(_baseUrl.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.aiBaseUrlInvalid)),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _model,
                        decoration: InputDecoration(
                          labelText: l10n.aiModel,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: _ctrl.setModel,
                        onTapOutside: (_) {
                          if (_model.text.trim() != (s.model ?? '')) {
                            _ctrl.setModel(_model.text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.aiModelLoad,
                      icon: const Icon(Icons.list_alt),
                      onPressed: _working || s.needsKey ? null : _loadModels,
                    ),
                  ],
                ),
              ),
              if (_models case final models? when models.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: models.any((m) => m.id == s.model)
                        ? s.model
                        : null,
                    decoration: InputDecoration(labelText: l10n.aiModel),
                    items: [
                      for (final m in models)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            m.capabilities == null
                                ? m.id
                                : '${m.id} · ${m.capabilities!.structuredToolCalls ? l10n.aiModelTools : l10n.aiModelNoTools}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _model.text = v;
                      _ctrl.setModel(v);
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _working || s.needsKey ? null : _test,
                      icon: const Icon(Icons.network_check),
                      label: Text(l10n.aiTest),
                    ),
                    if (_working)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              if (_testMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _testMessage!,
                    style: TextStyle(
                      color: _testOk == true
                          ? StudioColors.of(context).success
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  l10n.aiCapabilities,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              SwitchListTile(
                title: Text(l10n.aiConsent),
                subtitle: Text(l10n.aiConsentHelp),
                value: s.consent,
                onChanged: _ctrl.setConsent,
              ),
              SwitchListTile(
                title: Text(l10n.aiSaveConversations),
                subtitle: Text(l10n.aiSaveConversationsHelp),
                value: s.saveConversations,
                onChanged: _ctrl.setSaveConversations,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: _deleteConversations,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(l10n.aiDeleteConversations),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.settingsAiProvidersNote,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
