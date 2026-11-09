import 'package:dio/dio.dart';

import '../domain/ai_provider.dart';
import 'ai_http.dart';

/// Adaptateur Anthropic (API « Messages »).
class AnthropicProvider implements AiProvider {
  AnthropicProvider({required String baseUrl, required String apiKey, Dio? dio})
    : _http = AiHttp(
        baseUrl: baseUrl,
        secret: apiKey,
        headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
        dio: dio,
      );

  final AiHttp _http;

  @override
  AiProviderId get id => AiProviderId.anthropic;

  @override
  AiCapabilities get capabilities => const AiCapabilities(
    chat: true,
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

  @override
  Future<List<AiModelInfo>> listModels() async {
    final body = await _http.get('models?limit=100');
    final data = body['data'];
    if (data is! List) {
      throw const AiException(
        AiErrorKind.invalidResponse,
        'Liste de modèles absente',
      );
    }
    return [
      for (final m in data.whereType<Map<Object?, Object?>>())
        if (m['id'] is String) AiModelInfo(id: m['id']! as String),
    ];
  }

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async {
    final system = request.messages
        .where((m) => m.role == AiRole.system)
        .map((m) => m.content)
        .join('\n\n');
    final body = await _http.post('messages', {
      'model': request.model,
      'max_tokens': request.maxTokens,
      'temperature': request.temperature,
      if (system.isNotEmpty) 'system': system,
      'messages': encodeMessages(request.messages),
      if (request.tools.isNotEmpty)
        'tools': [
          for (final t in request.tools)
            {
              'name': t.name,
              'description': t.description,
              'input_schema': t.parameters,
            },
        ],
    });
    return parseResponse(body);
  }

  /// Convertit l'historique : les résultats d'outils deviennent des blocs
  /// `tool_result` d'un message utilisateur et les messages consécutifs de
  /// même rôle sont fusionnés (alternance exigée par l'API).
  static List<Map<String, Object?>> encodeMessages(List<AiMessage> messages) {
    final out = <Map<String, Object?>>[];
    void add(String role, List<Map<String, Object?>> blocks) {
      if (blocks.isEmpty) return;
      if (out.isNotEmpty && out.last['role'] == role) {
        (out.last['content']! as List<Map<String, Object?>>).addAll(blocks);
      } else {
        out.add({'role': role, 'content': blocks});
      }
    }

    for (final m in messages) {
      switch (m.role) {
        case AiRole.system:
          break;
        case AiRole.user:
          add('user', [
            {'type': 'text', 'text': m.content},
          ]);
        case AiRole.assistant:
          add('assistant', [
            if (m.content.isNotEmpty) {'type': 'text', 'text': m.content},
            for (final c in m.toolCalls)
              {
                'type': 'tool_use',
                'id': c.id,
                'name': c.name,
                'input': c.arguments,
              },
          ]);
        case AiRole.tool:
          add('user', [
            {
              'type': 'tool_result',
              'tool_use_id': m.toolCallId,
              'content': m.content,
            },
          ]);
      }
    }
    return out;
  }

  static AiChatResponse parseResponse(Map<String, Object?> body) {
    final content = body['content'];
    if (content is! List) {
      throw const AiException(
        AiErrorKind.invalidResponse,
        'Réponse sans contenu',
      );
    }
    final text = StringBuffer();
    final calls = <AiToolCall>[];
    for (final block in content.whereType<Map<Object?, Object?>>()) {
      switch (block['type']) {
        case 'text':
          text.write(block['text'] ?? '');
        case 'tool_use':
          final decoded = decodeToolArguments(block['input']);
          calls.add(
            AiToolCall(
              id: '${block['id']}',
              name: '${block['name']}',
              arguments: decoded.args,
              argumentsError: decoded.error,
            ),
          );
      }
    }
    return AiChatResponse(
      AiMessage.assistant(text.toString(), toolCalls: calls),
      finishReason: body['stop_reason'] as String?,
    );
  }
}
