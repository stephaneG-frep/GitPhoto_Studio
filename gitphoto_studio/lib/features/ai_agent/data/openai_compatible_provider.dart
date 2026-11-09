import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_provider.dart';
import 'ai_http.dart';

/// Adaptateur pour les API au format « chat completions » : Mistral
/// (prioritaire), OpenAI et Ollama (point d'accès compatible `/v1`).
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.id,
    required String baseUrl,
    String? apiKey,
    Dio? dio,
  }) : _http = AiHttp(
         baseUrl: baseUrl,
         secret: apiKey,
         headers: {
           if (apiKey != null && apiKey.isNotEmpty)
             'Authorization': 'Bearer $apiKey',
         },
         dio: dio,
       );

  @override
  final AiProviderId id;
  final AiHttp _http;

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    chat: true,
    // Mistral (Pixtral), OpenAI et certains modèles Ollama lisent les images,
    // mais l'application ne leur en envoie aucune.
    vision: true,
    metadataAnalysis: true,
    structuredToolCalls: true,
  );

  @override
  Future<AiConnectionStatus> testConnection() async {
    try {
      final models = await listModels();
      return AiConnectionStatus(
        AiAvailability.available,
        message: '${models.length} modèle(s)',
      );
    } on AiException catch (e) {
      return AiConnectionStatus(
        AiAvailability.unavailable,
        message: e.message,
        error: e,
      );
    }
  }

  static final _nonChat = RegExp(
    r'embed|whisper|tts|dall-e|moderation|transcribe|ocr|image|audio|realtime',
    caseSensitive: false,
  );

  @override
  Future<List<AiModelInfo>> listModels() async {
    final body = await _http.get('models');
    final data = body['data'];
    if (data is! List) {
      throw const AiException(
        AiErrorKind.invalidResponse,
        'Liste de modèles absente',
      );
    }
    final seen = <String>{};
    final models = <AiModelInfo>[];
    for (final m in data.whereType<Map<Object?, Object?>>()) {
      final modelId = m['id'];
      if (modelId is! String || !seen.add(modelId)) continue;
      final caps = m['capabilities'];
      if (caps is Map) {
        // Mistral publie les capacités de chaque modèle.
        if (caps['completion_chat'] == false) continue;
        models.add(
          AiModelInfo(
            id: modelId,
            capabilities: AiCapabilities(
              chat: true,
              vision: caps['vision'] == true,
              metadataAnalysis: true,
              structuredToolCalls: caps['function_calling'] == true,
            ),
          ),
        );
      } else {
        if (_nonChat.hasMatch(modelId)) continue;
        models.add(AiModelInfo(id: modelId));
      }
    }
    models.sort((a, b) => a.id.compareTo(b.id));
    return models;
  }

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async {
    final body = await _http.post('chat/completions', {
      'model': request.model,
      'messages': [for (final m in request.messages) _encode(m)],
      if (request.tools.isNotEmpty) ...{
        'tools': [
          for (final t in request.tools)
            {
              'type': 'function',
              'function': {
                'name': t.name,
                'description': t.description,
                'parameters': t.parameters,
              },
            },
        ],
        'tool_choice': 'auto',
      },
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
    });
    return parseResponse(body);
  }

  static Map<String, Object?> _encode(AiMessage m) => switch (m.role) {
    AiRole.system => {'role': 'system', 'content': m.content},
    AiRole.user => {'role': 'user', 'content': m.content},
    AiRole.assistant => {
      'role': 'assistant',
      'content': m.content,
      if (m.toolCalls.isNotEmpty)
        'tool_calls': [
          for (final c in m.toolCalls)
            {
              'id': c.id,
              'type': 'function',
              'function': {
                'name': c.name,
                'arguments': jsonEncode(c.arguments),
              },
            },
        ],
    },
    AiRole.tool => {
      'role': 'tool',
      'tool_call_id': m.toolCallId,
      'name': m.toolName,
      'content': m.content,
    },
  };

  static AiChatResponse parseResponse(Map<String, Object?> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty || choices.first is! Map) {
      throw const AiException(
        AiErrorKind.invalidResponse,
        'Réponse sans contenu',
      );
    }
    final choice = choices.first as Map;
    final message = choice['message'];
    if (message is! Map) {
      throw const AiException(AiErrorKind.invalidResponse, 'Message absent');
    }
    final calls = <AiToolCall>[];
    final rawCalls = message['tool_calls'];
    if (rawCalls is List) {
      for (final (i, c) in rawCalls.indexed) {
        if (c is! Map) continue;
        final fn = c['function'];
        if (fn is! Map || fn['name'] is! String) continue;
        final decoded = decodeToolArguments(fn['arguments']);
        calls.add(
          AiToolCall(
            id: c['id'] is String ? c['id'] as String : 'call$i',
            name: fn['name'] as String,
            arguments: decoded.args,
            argumentsError: decoded.error,
          ),
        );
      }
    }
    return AiChatResponse(
      AiMessage.assistant(textOf(message['content']), toolCalls: calls),
      finishReason: choice['finish_reason'] as String?,
    );
  }
}
