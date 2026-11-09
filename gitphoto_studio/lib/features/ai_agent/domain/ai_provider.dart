/// Contrat commun des fournisseurs IA (Mistral en priorité, puis OpenAI,
/// Anthropic, Gemini, Ollama). Les fonctionnalités classiques de
/// l'application n'en dépendent jamais.
library;

enum AiProviderId { mistral, openAi, anthropic, gemini, ollama }

/// Capacités déclarées par un adaptateur. Elles ne sont présentées comme
/// disponibles qu'après un test de connexion réussi.
class AiCapabilities {
  const AiCapabilities({
    this.chat = false,
    this.vision = false,
    this.metadataAnalysis = false,
    this.structuredToolCalls = false,
  });

  final bool chat;

  /// Le fournisseur sait analyser des images. L'application n'envoie
  /// cependant **aucun média** à une IA externe dans cette version.
  final bool vision;
  final bool metadataAnalysis;
  final bool structuredToolCalls;
}

enum AiAvailability { notConfigured, available, unavailable, disabled }

class AiConnectionStatus {
  const AiConnectionStatus(this.availability, {this.message, this.error});

  final AiAvailability availability;

  /// Message destiné à l'utilisateur, déjà expurgé de tout secret.
  final String? message;
  final AiException? error;
}

class AiModelInfo {
  const AiModelInfo({required this.id, this.capabilities});

  final String id;

  /// Capacités annoncées par le fournisseur pour ce modèle, quand il les
  /// publie (Mistral). `null` : inconnues.
  final AiCapabilities? capabilities;
}

enum AiRole { system, user, assistant, tool }

/// Appel d'outil demandé par le modèle. Les arguments ne sont jamais
/// exécutés tels quels : ils sont validés par l'application.
class AiToolCall {
  const AiToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.argumentsError,
    this.providerPart,
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;

  /// Arguments illisibles (JSON invalide) : l'appel sera refusé.
  final String? argumentsError;

  /// Fragment d'origine à renvoyer tel quel au fournisseur (Gemini : la
  /// signature de raisonnement accompagne l'appel).
  final Map<String, Object?>? providerPart;
}

class AiMessage {
  const AiMessage(
    this.role,
    this.content, {
    this.toolCalls = const [],
    this.toolCallId,
    this.toolName,
  });

  const AiMessage.system(String content) : this(AiRole.system, content);

  const AiMessage.user(String content) : this(AiRole.user, content);

  const AiMessage.assistant(
    String content, {
    List<AiToolCall> toolCalls = const [],
  }) : this(AiRole.assistant, content, toolCalls: toolCalls);

  const AiMessage.toolResult({
    required String callId,
    required String name,
    required String content,
  }) : this(AiRole.tool, content, toolCallId: callId, toolName: name);

  final AiRole role;
  final String content;
  final List<AiToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;
}

/// Description d'un outil proposé au modèle (schéma JSON des arguments).
class AiToolSpec {
  const AiToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, Object?> parameters;
}

class AiChatRequest {
  const AiChatRequest({
    required this.model,
    required this.messages,
    this.tools = const [],
    this.temperature = 0.2,
    this.maxTokens = 2048,
  });

  final String model;
  final List<AiMessage> messages;
  final List<AiToolSpec> tools;
  final double temperature;
  final int maxTokens;
}

class AiChatResponse {
  const AiChatResponse(this.message, {this.finishReason});

  final AiMessage message;
  final String? finishReason;
}

enum AiErrorKind {
  /// Clé absente, invalide ou révoquée.
  unauthorized,
  forbidden,

  /// Modèle ou point d'accès inconnu.
  notFound,

  /// Trop de requêtes ou quota épuisé.
  rateLimited,

  /// Requête refusée par le fournisseur (paramètres, modèle incompatible…).
  badRequest,

  /// Le modèle choisi ne sait pas appeler d'outils.
  toolsUnsupported,
  network,
  timeout,
  server,

  /// Réponse inattendue du fournisseur.
  invalidResponse,
  notConfigured,
}

class AiException implements Exception {
  const AiException(this.kind, this.message, {this.statusCode});

  final AiErrorKind kind;

  /// Déjà expurgé de tout secret.
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'AiException(${kind.name}${statusCode == null ? '' : ', $statusCode'}): '
      '$message';
}

abstract interface class AiProvider {
  AiProviderId get id;
  AiCapabilities get capabilities;
  Future<AiConnectionStatus> testConnection();
  Future<List<AiModelInfo>> listModels();
  Future<AiChatResponse> chat(AiChatRequest request);
}

/// Informations statiques sur les fournisseurs proposés.
class AiProviderDescriptor {
  const AiProviderDescriptor({
    required this.id,
    required this.displayName,
    required this.isLocal,
    required this.requiresApiKey,
    required this.defaultBaseUrl,
    required this.suggestedModel,
    required this.keyUrl,
    this.verifiedForReal = false,
  });

  final AiProviderId id;
  final String displayName;
  final bool isLocal;
  final bool requiresApiKey;
  final String defaultBaseUrl;

  /// Modèle proposé par défaut ; l'utilisateur peut en choisir un autre
  /// dans la liste renvoyée par le fournisseur.
  final String? suggestedModel;

  /// Page où créer une clé (ou documentation pour Ollama).
  final String keyUrl;

  /// Adaptateur vérifié contre le vrai service (et non seulement contre un
  /// serveur simulé de test). Affiché dans les paramètres.
  final bool verifiedForReal;
}

/// Ordre de présentation : Mistral est le fournisseur prioritaire.
const List<AiProviderDescriptor> aiProviderCatalog = [
  AiProviderDescriptor(
    id: AiProviderId.mistral,
    displayName: 'Mistral AI',
    isLocal: false,
    requiresApiKey: true,
    defaultBaseUrl: 'https://api.mistral.ai/v1',
    suggestedModel: 'mistral-small-latest',
    keyUrl: 'https://console.mistral.ai/api-keys',
    // integration_test/mistral_real_test.dart, 2026-11-09.
    verifiedForReal: true,
  ),
  AiProviderDescriptor(
    id: AiProviderId.openAi,
    displayName: 'OpenAI',
    isLocal: false,
    requiresApiKey: true,
    defaultBaseUrl: 'https://api.openai.com/v1',
    suggestedModel: 'gpt-4o-mini',
    keyUrl: 'https://platform.openai.com/api-keys',
  ),
  AiProviderDescriptor(
    id: AiProviderId.anthropic,
    displayName: 'Anthropic Claude',
    isLocal: false,
    requiresApiKey: true,
    defaultBaseUrl: 'https://api.anthropic.com/v1',
    suggestedModel: null,
    keyUrl: 'https://console.anthropic.com/settings/keys',
  ),
  AiProviderDescriptor(
    id: AiProviderId.gemini,
    displayName: 'Google Gemini',
    isLocal: false,
    requiresApiKey: true,
    defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    suggestedModel: 'gemini-2.5-flash',
    keyUrl: 'https://aistudio.google.com/app/apikey',
  ),
  AiProviderDescriptor(
    id: AiProviderId.ollama,
    displayName: 'Ollama (local)',
    isLocal: true,
    requiresApiKey: false,
    defaultBaseUrl: 'http://localhost:11434/v1',
    suggestedModel: null,
    keyUrl: 'https://ollama.com/search?c=tools',
  ),
];

AiProviderDescriptor descriptorOf(AiProviderId id) =>
    aiProviderCatalog.firstWhere((d) => d.id == id);

AiProviderId get defaultAiProvider => aiProviderCatalog.first.id;

/// Identifiant de modèle accepté : évite toute injection dans une URL.
final RegExp validModelId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:/@-]{0,127}$');
