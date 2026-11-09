import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/security/secret_redactor.dart';
import '../domain/ai_provider.dart';

/// Transport HTTP commun aux adaptateurs IA : délais, conversion des
/// erreurs en [AiException] typées et expurgation systématique de la clé.
class AiHttp {
  AiHttp({
    required String baseUrl,
    required Map<String, String> headers,
    String? secret,
    Dio? dio,
  }) : _dio = dio ?? Dio(),
       _secret = secret,
       _headers = headers {
    _dio.options
      ..baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'
      ..connectTimeout = const Duration(seconds: 20)
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 120)
      ..validateStatus = ((_) => true)
      ..responseType = ResponseType.plain;
  }

  final Dio _dio;
  final String? _secret;

  /// En-têtes d'authentification : jamais journalisés.
  final Map<String, String> _headers;

  Future<Map<String, Object?>> get(String path) => _send('GET', path, null);

  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) =>
      _send('POST', path, body);

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    final Response<String> r;
    try {
      r = await _dio.request<String>(
        path.startsWith('/') ? path.substring(1) : path,
        data: body == null ? null : jsonEncode(body),
        options: Options(
          method: method,
          headers: {
            ..._headers,
            'Accept': 'application/json',
            if (body != null) 'Content-Type': 'application/json',
            'User-Agent': 'GitPhotoStudio',
          },
        ),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => AiException(
          AiErrorKind.timeout,
          redact('Délai dépassé (${e.type.name})'),
        ),
        _ => AiException(
          AiErrorKind.network,
          redact(e.message ?? e.error?.toString() ?? e.type.name),
        ),
      };
    }
    final status = r.statusCode ?? 0;
    Object? decoded;
    try {
      decoded = (r.data == null || r.data!.isEmpty)
          ? null
          : jsonDecode(r.data!);
    } on FormatException {
      decoded = null;
    }
    if (status < 200 || status >= 300) {
      throw errorFor(status, decoded, r.data);
    }
    if (decoded is! Map<String, Object?>) {
      throw AiException(
        AiErrorKind.invalidResponse,
        'Réponse illisible (HTTP $status)',
        statusCode: status,
      );
    }
    return decoded;
  }

  /// Retire la clé (même sans motif reconnaissable) et les secrets connus.
  String redact(String input) {
    var s = input;
    final secret = _secret;
    if (secret != null && secret.length >= 6) {
      s = s.replaceAll(secret, SecretRedactor.mask);
    }
    return SecretRedactor.redact(s);
  }

  AiException errorFor(int status, Object? body, String? raw) {
    final detail = redact(
      _serverMessage(body) ?? _short(raw) ?? 'HTTP $status',
    );
    final lower = detail.toLowerCase();
    final kind = switch (status) {
      401 => AiErrorKind.unauthorized,
      403 => AiErrorKind.forbidden,
      404 => AiErrorKind.notFound,
      429 => AiErrorKind.rateLimited,
      _ when status >= 500 => AiErrorKind.server,
      _
          when lower.contains('does not support tools') ||
              lower.contains('function calling is not') ||
              lower.contains('tools are not supported') =>
        AiErrorKind.toolsUnsupported,
      _ => AiErrorKind.badRequest,
    };
    return AiException(kind, detail, statusCode: status);
  }

  static String? _short(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    // Page HTML d'un proxy : sans intérêt pour l'utilisateur.
    if (t.startsWith('<')) return null;
    return t.length > 300 ? '${t.substring(0, 300)}…' : t;
  }

  /// Formats rencontrés : `{"error":{"message":…}}` (OpenAI, Anthropic,
  /// Gemini), `{"message":…}` / `{"detail":…}` (Mistral), `{"error":"…"}`
  /// (Ollama).
  static String? _serverMessage(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    final candidates = [
      if (error is Map) error['message'],
      if (error is String) error,
      body['message'],
      body['detail'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return _short(c);
      if (c is List && c.isNotEmpty) {
        // Erreurs de validation détaillées (Mistral : liste d'objets).
        final first = c.first;
        if (first is Map && first['msg'] is String) {
          return _short(first['msg'] as String);
        }
        return _short(jsonEncode(first));
      }
    }
    return null;
  }
}

/// Décode des arguments d'outil (chaîne JSON ou objet déjà décodé).
({Map<String, Object?> args, String? error}) decodeToolArguments(Object? raw) {
  if (raw == null) return (args: const {}, error: null);
  if (raw is Map) return (args: raw.cast<String, Object?>(), error: null);
  if (raw is String) {
    if (raw.trim().isEmpty) return (args: const {}, error: null);
    try {
      final v = jsonDecode(raw);
      if (v is Map) return (args: v.cast<String, Object?>(), error: null);
      return (
        args: const {},
        error: 'Les arguments doivent être un objet JSON',
      );
    } on FormatException catch (e) {
      return (args: const {}, error: 'JSON invalide : ${e.message}');
    }
  }
  return (args: const {}, error: 'Arguments de type inattendu');
}

/// Texte d'un message : chaîne simple ou liste de fragments `{type, text}`.
String textOf(Object? content) {
  if (content is String) return content;
  if (content is List) {
    return content
        .whereType<Map<Object?, Object?>>()
        .where((c) => c['type'] == 'text' && c['text'] is String)
        .map((c) => c['text'] as String)
        .join();
  }
  return '';
}
