// ADAPTATEURS IA SIMULÉS — RÉSERVÉS AUX TESTS.
//
// Ils vérifient le format des requêtes et le traitement des réponses, mais ne
// prouvent en aucun cas qu'un fournisseur réel fonctionne : seuls les tests
// d'intégration contre le vrai service (integration_test/) le peuvent.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gitphoto_studio/features/ai_agent/domain/ai_provider.dart';

class RecordedRequest {
  RecordedRequest(this.method, this.uri, this.headers, this.body);

  final String method;
  final Uri uri;
  final Map<String, dynamic> headers;
  final Map<String, Object?>? body;
}

/// Serveur HTTP simulé (adaptateur Dio) : chaque requête reçoit la réponse
/// suivante de [responses].
class FakeAiHttp implements HttpClientAdapter {
  final requests = <RecordedRequest>[];
  final responses = <(int, Object)>[];

  Dio dio() => Dio()..httpClientAdapter = this;

  void reply(int status, Object body) => responses.add((status, body));

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Map<String, Object?>? body;
    if (options.data is String && (options.data as String).isNotEmpty) {
      body = (jsonDecode(options.data as String) as Map)
          .cast<String, Object?>();
    }
    requests.add(
      RecordedRequest(options.method, options.uri, options.headers, body),
    );
    if (responses.isEmpty) {
      return ResponseBody.fromString('{"error":"no scripted response"}', 500);
    }
    final (status, payload) = responses.removeAt(0);
    return ResponseBody.fromString(
      payload is String ? payload : jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

/// Fournisseur simulé : renvoie des réponses écrites à l'avance et garde
/// les requêtes reçues.
class ScriptedProvider implements AiProvider {
  ScriptedProvider(this.script, {this.tools = true});

  final List<AiChatResponse Function(AiChatRequest request)> script;
  final bool tools;
  final requests = <AiChatRequest>[];

  @override
  AiProviderId get id => AiProviderId.mistral;

  @override
  AiCapabilities get capabilities =>
      AiCapabilities(chat: true, structuredToolCalls: tools);

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async {
    requests.add(request);
    if (script.isEmpty) {
      throw const AiException(AiErrorKind.server, 'script épuisé');
    }
    return script.removeAt(0)(request);
  }

  @override
  Future<List<AiModelInfo>> listModels() async => const [
    AiModelInfo(id: 'mistral-small-latest'),
  ];

  @override
  Future<AiConnectionStatus> testConnection() async =>
      const AiConnectionStatus(AiAvailability.available, message: '1 modèle');
}

AiChatResponse Function(AiChatRequest) says(String text) =>
    (_) => AiChatResponse(AiMessage.assistant(text));

AiChatResponse Function(AiChatRequest) calls(
  String name,
  Map<String, Object?> args, {
  String id = 'c1',
  String text = '',
}) =>
    (_) => AiChatResponse(
      AiMessage.assistant(
        text,
        toolCalls: [AiToolCall(id: id, name: name, arguments: args)],
      ),
    );
