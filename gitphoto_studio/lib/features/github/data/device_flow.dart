import 'package:dio/dio.dart';

import 'github_exception.dart';

/// Code à saisir par l'utilisateur sur [verificationUri].
class DeviceCode {
  const DeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.interval,
    required this.expiresAt,
  });

  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final Duration interval;
  final DateTime expiresAt;
}

enum DeviceFlowError { denied, expired, misconfigured }

class DeviceFlowException implements Exception {
  const DeviceFlowException(this.error, [this.detail]);

  final DeviceFlowError error;
  final String? detail;

  @override
  String toString() => 'DeviceFlowException(${error.name}): ${detail ?? ''}';
}

/// Flux « Device Flow » de GitHub (OAuth 2.0 Device Authorization Grant).
///
/// Ne nécessite qu'un identifiant client public (application OAuth ou
/// GitHub App avec le Device Flow activé) : aucun secret n'est embarqué.
class GithubDeviceFlow {
  GithubDeviceFlow({required this.clientId, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = 'https://github.com'
      ..connectTimeout = const Duration(seconds: 20)
      ..validateStatus = ((_) => true)
      ..headers['Accept'] = 'application/json';
  }

  final String clientId;
  final Dio _dio;

  /// Délai d'attente injectable (tests).
  Future<void> Function(Duration) wait = Future<void>.delayed;

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final r = await _dio.post<Object?>(path, data: body);
      final data = r.data;
      if (data is! Map) {
        throw GithubException(
          GithubErrorKind.unknown,
          'Réponse inattendue (HTTP ${r.statusCode})',
          statusCode: r.statusCode,
        );
      }
      return data.cast<String, Object?>();
    } on DioException catch (e) {
      throw GithubException(GithubErrorKind.network, e.message ?? e.type.name);
    }
  }

  /// [scope] : ignoré par les GitHub Apps (permissions définies par l'app).
  Future<DeviceCode> start({String scope = 'repo'}) async {
    final json = await _post('/login/device/code', {
      'client_id': clientId,
      'scope': scope,
    });
    if (json['error'] != null) {
      throw DeviceFlowException(
        DeviceFlowError.misconfigured,
        json['error_description'] as String? ?? json['error'] as String,
      );
    }
    return DeviceCode(
      deviceCode: json['device_code']! as String,
      userCode: json['user_code']! as String,
      verificationUri: json['verification_uri']! as String,
      interval: Duration(seconds: (json['interval'] as num?)?.toInt() ?? 5),
      expiresAt: DateTime.now().add(
        Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 900),
      ),
    );
  }

  /// Attend que l'utilisateur ait autorisé l'application et renvoie le jeton.
  Future<String> poll(DeviceCode code, {bool Function()? isCancelled}) async {
    var interval = code.interval;
    while (true) {
      await wait(interval);
      if (isCancelled?.call() ?? false) {
        throw const DeviceFlowException(DeviceFlowError.denied, 'annulé');
      }
      if (DateTime.now().isAfter(code.expiresAt)) {
        throw const DeviceFlowException(DeviceFlowError.expired);
      }
      final json = await _post('/login/oauth/access_token', {
        'client_id': clientId,
        'device_code': code.deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      });
      final token = json['access_token'];
      if (token is String && token.isNotEmpty) return token;
      switch (json['error']) {
        case 'authorization_pending':
          continue;
        case 'slow_down':
          interval += const Duration(seconds: 5);
          continue;
        case 'expired_token':
          throw const DeviceFlowException(DeviceFlowError.expired);
        case 'access_denied':
          throw const DeviceFlowException(DeviceFlowError.denied);
        default:
          throw DeviceFlowException(
            DeviceFlowError.misconfigured,
            json['error_description'] as String? ?? '${json['error']}',
          );
      }
    }
  }
}
