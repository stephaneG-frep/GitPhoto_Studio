import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/secrets/secret_store.dart';
import '../../github/application/github_session.dart';
import '../data/anthropic_provider.dart';
import '../data/gemini_provider.dart';
import '../data/openai_compatible_provider.dart';
import '../domain/ai_provider.dart';

/// Préférences IA non sensibles (SQLite). La clé d'API n'est jamais ici :
/// elle reste dans le stockage sécurisé du système.
abstract final class AiPreferenceKeys {
  static const enabled = 'ai.enabled';
  static const provider = 'ai.provider';
  static const saveConversations = 'ai.save_conversations';
  static String model(AiProviderId id) => 'ai.${id.name}.model';
  static String baseUrl(AiProviderId id) => 'ai.${id.name}.base_url';

  /// Accord de l'utilisateur pour l'envoi de métadonnées à ce fournisseur.
  static String consent(AiProviderId id) => 'ai.${id.name}.consent';
}

class AiSettings {
  const AiSettings({
    required this.enabled,
    required this.provider,
    required this.model,
    required this.baseUrl,
    required this.hasKey,
    required this.consent,
    required this.saveConversations,
    this.storeUnavailable = false,
  });

  /// L'IA est désactivée par défaut : l'application fonctionne sans elle.
  final bool enabled;
  final AiProviderId provider;
  final String? model;
  final String baseUrl;
  final bool hasKey;
  final bool consent;
  final bool saveConversations;

  /// Trousseau du système inaccessible : aucune clé ne peut être enregistrée.
  final bool storeUnavailable;

  AiProviderDescriptor get descriptor => descriptorOf(provider);

  bool get needsKey => descriptor.requiresApiKey && !hasKey;

  /// Prêt à dialoguer (l'accord est demandé dans l'écran de l'agent).
  bool get isConfigured => enabled && !needsKey && (model?.isNotEmpty ?? false);
}

/// Adresse de serveur acceptée : HTTPS, ou HTTP pour un serveur local
/// (Ollama). Évite d'envoyer une clé en clair sur le réseau.
bool isAcceptableBaseUrl(String url, {required bool allowHttp}) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return false;
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) return false;
  if (uri.scheme == 'https') return true;
  return allowHttp && uri.scheme == 'http';
}

typedef AiProviderFactory =
    AiProvider Function(AiProviderId id, String baseUrl, String? apiKey);

AiProvider createAiProvider(AiProviderId id, String baseUrl, String? apiKey) =>
    switch (id) {
      AiProviderId.mistral || AiProviderId.openAi || AiProviderId.ollama =>
        OpenAiCompatibleProvider(id: id, baseUrl: baseUrl, apiKey: apiKey),
      AiProviderId.anthropic => AnthropicProvider(
        baseUrl: baseUrl,
        apiKey: apiKey ?? '',
      ),
      AiProviderId.gemini => GeminiProvider(
        baseUrl: baseUrl,
        apiKey: apiKey ?? '',
      ),
    };

/// Fabrique des adaptateurs (remplacée dans les tests par un serveur local).
final aiProviderFactoryProvider = Provider<AiProviderFactory>(
  (ref) => createAiProvider,
);

class AiSettingsController extends AsyncNotifier<AiSettings> {
  SecretStore get _store => ref.read(secretStoreProvider);

  @override
  Future<AiSettings> build() async {
    final prefs = ref.watch(preferencesProvider);
    final provider =
        AiProviderId.values.asNameMap()[prefs.read(
          AiPreferenceKeys.provider,
        )] ??
        defaultAiProvider;
    final d = descriptorOf(provider);
    final storeOk = await _store.status() == SecretStoreStatus.available;
    final key = storeOk
        ? await _store.read(SecretKeys.aiProviderKey(provider.name))
        : null;
    return AiSettings(
      enabled: prefs.read(AiPreferenceKeys.enabled) == 'true',
      provider: provider,
      model: prefs.read(AiPreferenceKeys.model(provider)) ?? d.suggestedModel,
      baseUrl: d.isLocal
          ? prefs.read(AiPreferenceKeys.baseUrl(provider)) ?? d.defaultBaseUrl
          : d.defaultBaseUrl,
      hasKey: key != null && key.isNotEmpty,
      consent: prefs.read(AiPreferenceKeys.consent(provider)) == 'true',
      saveConversations:
          prefs.read(AiPreferenceKeys.saveConversations) == 'true',
      storeUnavailable: !storeOk,
    );
  }

  void _write(String key, String value) {
    ref.read(preferencesProvider).write(key, value);
    ref.invalidateSelf();
  }

  void setEnabled(bool v) => _write(AiPreferenceKeys.enabled, '$v');

  void setProvider(AiProviderId id) =>
      _write(AiPreferenceKeys.provider, id.name);

  void setModel(String model) {
    final m = model.trim();
    if (!validModelId.hasMatch(m)) return;
    _write(AiPreferenceKeys.model(state.requireValue.provider), m);
  }

  /// Renvoie `false` si l'adresse est refusée.
  bool setBaseUrl(String url) {
    final s = state.requireValue;
    if (!s.descriptor.isLocal || !isAcceptableBaseUrl(url, allowHttp: true)) {
      return false;
    }
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    _write(AiPreferenceKeys.baseUrl(s.provider), u);
    return true;
  }

  void setConsent(bool v) =>
      _write(AiPreferenceKeys.consent(state.requireValue.provider), '$v');

  void setSaveConversations(bool v) =>
      _write(AiPreferenceKeys.saveConversations, '$v');

  Future<void> saveKey(String key) async {
    final k = key.trim();
    if (k.isEmpty) return;
    await _store.write(
      SecretKeys.aiProviderKey(state.requireValue.provider.name),
      k,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteKey() async {
    await _store.delete(
      SecretKeys.aiProviderKey(state.requireValue.provider.name),
    );
    ref.invalidateSelf();
  }

  /// Construit l'adaptateur du fournisseur choisi. La clé n'est lue qu'à
  /// ce moment et ne vit qu'en mémoire.
  Future<AiProvider> buildProvider() async {
    final s = await future;
    String? key;
    if (s.descriptor.requiresApiKey) {
      key = await _store.read(SecretKeys.aiProviderKey(s.provider.name));
      if (key == null || key.isEmpty) {
        throw const AiException(
          AiErrorKind.notConfigured,
          'Aucune clé enregistrée',
        );
      }
    }
    return ref.read(aiProviderFactoryProvider)(s.provider, s.baseUrl, key);
  }
}

final aiSettingsProvider =
    AsyncNotifierProvider<AiSettingsController, AiSettings>(
      AiSettingsController.new,
      retry: (_, _) => null,
    );
