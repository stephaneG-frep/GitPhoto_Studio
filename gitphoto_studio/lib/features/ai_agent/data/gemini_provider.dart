import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_provider.dart';
import 'ai_http.dart';

/// Adaptateur Google Gemini (`generateContent`). La clé passe par l'en-tête
/// `x-goog-api-key`, jamais dans l'URL.
class GeminiProvider implements AiProvider {
  GeminiProvider({required String baseUrl, required String apiKey, Dio? dio})
    : _http = AiHttp(
        baseUrl: baseUrl,
        secret: apiKey,
        headers: {'x-goog-api-key': apiKey},
        dio: dio,
      );

  final AiHttp _http;

  @override
  AiProviderId get id => AiProviderId.gemini;

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
    final body = await _http.get('models?pageSize=200');
    final data = body['models'];
    if (data is! List) {
      throw const AiException(
        AiErrorKind.invalidResponse,
        'Liste de modèles absente',
      );
    }
    final models = <AiModelInfo>[];
    for (final m in data.whereType<Map<Object?, Object?>>()) {
      final name = m['name'];
      final methods = m['supportedGenerationMethods'];
      if (name is! String) continue;
      if (methods is List && !methods.contains('generateContent')) continue;
      models.add(
        AiModelInfo(id: name.startsWith('models/') ? name.substring(7) : name),
      );
    }
    return models;
  }

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async {
    if (!validModelId.hasMatch(request.model)) {
      throw const AiException(AiErrorKind.badRequest, 'Modèle invalide');
    }
    final system = request.messages
        .where((m) => m.role == AiRole.system)
        .map((m) => m.content)
        .join('\n\n');
    final body = await _http.post('models/${request.model}:generateContent', {
      if (system.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
      'contents': encodeContents(request.messages),
      if (request.tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': [
              for (final t in request.tools)
                {
                  'name': t.name,
                  'description': t.description,
                  'parameters': geminiSchema(t.parameters),
                },
            ],
          },
        ],
      'generationConfig': {
        'temperature': request.temperature,
        'maxOutputTokens': request.maxTokens,
      },
    });
    return parseResponse(body);
  }

  /// Gemini n'accepte qu'un sous-ensemble d'OpenAPI : les mots-clés non
  /// reconnus (`additionalProperties`…) sont retirés.
  static Object? geminiSchema(Object? schema) {
    const allowed = {
      'type',
      'description',
      'enum',
      'items',
      'properties',
      'required',
      'minimum',
      'maximum',
      'minItems',
      'maxItems',
      'nullable',
      'format',
    };
    if (schema is Map) {
      return {
        for (final e in schema.entries)
          if (allowed.contains(e.key))
            e.key as String: e.key == 'properties' && e.value is Map
                ? {
                    for (final p in (e.value as Map).entries)
                      p.key as String: geminiSchema(p.value),
                  }
                : geminiSchema(e.value),
      };
    }
    if (schema is List) return [for (final s in schema) geminiSchema(s)];
    return schema;
  }

  static List<Map<String, Object?>> encodeContents(List<AiMessage> messages) {
    final out = <Map<String, Object?>>[];
    void add(String role, List<Map<String, Object?>> parts) {
      if (parts.isEmpty) return;
      if (out.isNotEmpty && out.last['role'] == role) {
        (out.last['parts']! as List<Map<String, Object?>>).addAll(parts);
      } else {
        out.add({'role': role, 'parts': parts});
      }
    }

    for (final m in messages) {
      switch (m.role) {
        case AiRole.system:
          break;
        case AiRole.user:
          add('user', [
            {'text': m.content},
          ]);
        case AiRole.assistant:
          add('model', [
            if (m.content.isNotEmpty) {'text': m.content},
            for (final c in m.toolCalls)
              c.providerPart ??
                  {
                    'functionCall': {'name': c.name, 'args': c.arguments},
                  },
          ]);
        case AiRole.tool:
          Object? result;
          try {
            result = jsonDecode(m.content);
          } on FormatException {
            result = m.content;
          }
          add('user', [
            {
              'functionResponse': {
                'name': m.toolName,
                // La réponse doit être un objet.
                'response': result is Map ? result : {'result': result},
              },
            },
          ]);
      }
    }
    return out;
  }

  static AiChatResponse parseResponse(Map<String, Object?> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final feedback = body['promptFeedback'];
      final reason = feedback is Map ? feedback['blockReason'] : null;
      throw AiException(
        AiErrorKind.badRequest,
        reason == null
            ? 'Réponse vide'
            : 'Demande bloquée par Gemini ($reason)',
      );
    }
    final first = candidates.first;
    final content = first is Map ? first['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    final text = StringBuffer();
    final calls = <AiToolCall>[];
    if (parts is List) {
      for (final (i, part) in parts.indexed) {
        if (part is! Map) continue;
        if (part['text'] is String) text.write(part['text']);
        final fc = part['functionCall'];
        if (fc is Map && fc['name'] is String) {
          final decoded = decodeToolArguments(fc['args']);
          calls.add(
            AiToolCall(
              // Gemini n'identifie pas toujours ses appels.
              id: fc['id'] is String ? fc['id'] as String : 'gemini-$i',
              name: fc['name'] as String,
              arguments: decoded.args,
              argumentsError: decoded.error,
              providerPart: part.cast<String, Object?>(),
            ),
          );
        }
      }
    }
    return AiChatResponse(
      AiMessage.assistant(text.toString(), toolCalls: calls),
      finishReason: first is Map ? first['finishReason'] as String? : null,
    );
  }
}
