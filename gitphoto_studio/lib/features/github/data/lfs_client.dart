import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../publishing/domain/git_blob_hash.dart';
import 'github_exception.dart';

/// Objet LFS : empreinte SHA-256 et taille du contenu réel.
class LfsObject {
  const LfsObject(this.oid, this.size);

  final String oid;
  final int size;

  /// Fichier pointeur versionné dans Git à la place du contenu.
  String get pointer =>
      'version https://git-lfs.github.com/spec/v1\noid sha256:$oid\n'
      'size $size\n';

  /// Empreinte Git du pointeur : c'est elle que l'arborescence contiendra.
  String get pointerBlobSha => gitBlobSha(utf8.encode(pointer));

  static Future<LfsObject> ofFile(String path) async {
    final file = File(path);
    final size = await file.length();
    final oid = await Isolate.run(
      () async => (await sha256.bind(File(path).openRead()).first).toString(),
    );
    return LfsObject(oid, size);
  }
}

/// Client du protocole Git LFS (API « batch », transfert « basic »).
///
/// Fonctionne sans l'outil `git-lfs`, donc aussi sous Android. Les fichiers
/// sont envoyés en flux depuis le disque (jamais chargés en mémoire). Un
/// envoi interrompu doit être recommencé depuis le début du fichier : le
/// transfert « basic » ne permet pas de reprise partielle.
class LfsClient {
  LfsClient({required String token, Dio? dio})
    : _dio = dio ?? Dio(),
      _auth = 'Basic ${base64Encode(utf8.encode('x-access-token:$token'))}' {
    _dio.options
      ..connectTimeout = const Duration(seconds: 30)
      ..validateStatus = ((_) => true);
  }

  final Dio _dio;
  final String _auth;

  static const _mediaType = 'application/vnd.git-lfs+json';

  static String batchUrl(String owner, String repo) =>
      'https://github.com/${Uri.encodeComponent(owner)}/'
      '${Uri.encodeComponent(repo)}.git/info/lfs/objects/batch';

  Future<Map<String, Object?>> _batch(
    String owner,
    String repo,
    String operation,
    List<LfsObject> objects,
  ) async {
    try {
      final r = await _dio.post<Object?>(
        batchUrl(owner, repo),
        data: jsonEncode({
          'operation': operation,
          'transfers': ['basic'],
          'objects': [
            for (final o in objects) {'oid': o.oid, 'size': o.size},
          ],
          'hash_algo': 'sha256',
        }),
        options: Options(
          headers: {
            'Authorization': _auth,
            'Accept': _mediaType,
            'Content-Type': _mediaType,
          },
          // Octets bruts : décodés ici, pour garder le code HTTP même si le
          // corps annoncé JSON est illisible.
          responseType: ResponseType.bytes,
        ),
      );
      final status = r.statusCode ?? 0;
      final body = _decode(r.data);
      if (status >= 200 && status < 300) return body;
      final message = body['message'] as String? ?? 'HTTP $status';
      throw GithubException(
        switch (status) {
          401 => GithubErrorKind.unauthorized,
          403 => GithubErrorKind.forbidden,
          404 => GithubErrorKind.notFound,
          // 422 : LFS désactivé ou objet refusé ; 507 : quota dépassé.
          422 || 507 => GithubErrorKind.validation,
          429 => GithubErrorKind.rateLimited,
          >= 500 => GithubErrorKind.server,
          _ => GithubErrorKind.unknown,
        },
        'Git LFS : $message',
        statusCode: status,
      );
    } on DioException catch (e) {
      throw _dioError(e);
    }
  }

  static Map<String, Object?> _decode(Object? data) {
    if (data is! List<int> || data.isEmpty) return const {};
    try {
      final v = jsonDecode(utf8.decode(data, allowMalformed: true));
      return v is Map ? v.cast<String, Object?>() : const {};
    } on FormatException {
      return const {};
    }
  }

  /// Une réponse déclarée JSON mais illisible n'est pas une panne réseau.
  static GithubException _dioError(DioException e) {
    final status = e.response?.statusCode;
    if (e.error is FormatException) {
      return GithubException(
        status != null && status >= 500
            ? GithubErrorKind.server
            : GithubErrorKind.unknown,
        'Git LFS : réponse illisible${status == null ? '' : ' (HTTP $status)'}',
        statusCode: status,
      );
    }
    return GithubException(GithubErrorKind.network, e.message ?? e.type.name);
  }

  static Map<String, Object?> _objectResult(
    Map<String, Object?> body,
    LfsObject object,
  ) {
    final objects = (body['objects'] as List? ?? const [])
        .cast<Map<String, Object?>>();
    final match = objects.firstWhere(
      (o) => o['oid'] == object.oid,
      orElse: () => const {},
    );
    final result = match.cast<String, Object?>();
    final error = result['error'];
    if (error is Map) {
      throw GithubException(
        GithubErrorKind.validation,
        'Git LFS : ${error['message'] ?? 'objet refusé'} '
        '(code ${error['code']})',
      );
    }
    return result;
  }

  /// Envoie le fichier s'il n'est pas déjà stocké sur GitHub. Renvoie `false`
  /// si l'objet existait déjà (aucun transfert).
  Future<bool> upload(
    String owner,
    String repo,
    String path,
    LfsObject object, {
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final body = await _batch(owner, repo, 'upload', [object]);
    final actions = _objectResult(body, object)['actions'] as Map?;
    if (actions == null) return false; // Déjà présent sur le serveur.

    final upload = (actions['upload'] as Map?)?.cast<String, Object?>();
    if (upload != null) {
      final headers = {
        ...((upload['header'] as Map?)?.cast<String, Object?>() ?? {}),
        Headers.contentLengthHeader: object.size,
        Headers.contentTypeHeader: 'application/octet-stream',
      };
      try {
        final r = await _dio.put<Object?>(
          upload['href']! as String,
          data: File(path).openRead(),
          options: Options(
            headers: headers,
            sendTimeout: null,
            receiveTimeout: const Duration(minutes: 5),
            responseType: ResponseType.bytes,
          ),
          onSendProgress: onProgress,
          cancelToken: cancelToken,
        );
        final status = r.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw GithubException(
            status >= 500 ? GithubErrorKind.server : GithubErrorKind.unknown,
            'Git LFS : envoi refusé (HTTP $status)',
            statusCode: status,
          );
        }
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;
        throw _dioError(e);
      }
    }

    final verify = (actions['verify'] as Map?)?.cast<String, Object?>();
    if (verify != null) {
      try {
        final r = await _dio.post<Object?>(
          verify['href']! as String,
          data: jsonEncode({'oid': object.oid, 'size': object.size}),
          options: Options(
            headers: {
              ...((verify['header'] as Map?)?.cast<String, Object?>() ?? {}),
              'Accept': _mediaType,
              'Content-Type': _mediaType,
            },
            responseType: ResponseType.bytes,
          ),
        );
        final status = r.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw GithubException(
            GithubErrorKind.unknown,
            'Git LFS : vérification refusée (HTTP $status)',
            statusCode: status,
          );
        }
      } on DioException catch (e) {
        throw _dioError(e);
      }
    }
    return true;
  }

  /// Vrai si GitHub détient bien l'objet (demande de téléchargement).
  Future<bool> exists(String owner, String repo, LfsObject object) async {
    final body = await _batch(owner, repo, 'download', [object]);
    try {
      final result = _objectResult(body, object);
      return (result['actions'] as Map?)?['download'] != null;
    } on GithubException {
      return false;
    }
  }
}

/// Ajoute à `.gitattributes` une règle LFS par chemin exact (motifs échappés).
/// Renvoie `null` si toutes les règles existent déjà.
String? withLfsRules(String? current, Iterable<String> paths) {
  final lines = (current ?? '').split('\n');
  final existing = lines.map((l) => l.trim()).toSet();
  final additions = <String>[];
  for (final path in paths) {
    final rule =
        '${escapeAttributesPattern(path)} filter=lfs diff=lfs '
        'merge=lfs -text';
    if (!existing.contains(rule) && !additions.contains(rule)) {
      additions.add(rule);
    }
  }
  if (additions.isEmpty) return null;
  final base = (current ?? '').isEmpty
      ? ''
      : (current!.endsWith('\n') ? current : '$current\n');
  return '$base${additions.join('\n')}\n';
}

/// Motif `.gitattributes` correspondant exactement à [path].
String escapeAttributesPattern(String path) {
  final buffer = StringBuffer();
  for (final ch in path.split('')) {
    if (ch == ' ') {
      buffer.write('[[:space:]]');
    } else if ('*?[]!#\\'.contains(ch)) {
      buffer.write('\\$ch');
    } else {
      buffer.write(ch);
    }
  }
  final escaped = buffer.toString();
  // Ancré à la racine du dépôt.
  return escaped.startsWith('/') ? escaped : '/$escaped';
}
