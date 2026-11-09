import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../domain/github_models.dart';
import 'github_exception.dart';

/// Client de l'API REST GitHub.
///
/// Toutes les réponses sont vérifiées et converties en [GithubException]
/// typées ; l'en-tête d'autorisation n'est jamais journalisé.
class GithubApi {
  GithubApi({required String token, Dio? dio})
    : _dio = dio ?? Dio(),
      _token = token {
    _dio.options
      ..baseUrl = 'https://api.github.com'
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 60)
      ..validateStatus = ((_) => true)
      ..headers.addAll({
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'GitPhotoStudio',
      });
  }

  final Dio _dio;
  final String _token;

  Map<String, String> get _auth => {'Authorization': 'Bearer $_token'};

  Future<Response<Object?>> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: _auth),
      );
      _check(response);
      return response;
    } on DioException catch (e) {
      throw GithubException(GithubErrorKind.network, e.message ?? e.type.name);
    }
  }

  static void _check(Response<Object?> r) {
    final status = r.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final body = r.data;
    var message = 'HTTP $status';
    if (body is Map && body['message'] is String) {
      message = body['message'] as String;
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        final details = errors
            .map((e) => e is Map ? (e['message'] ?? e['code']) : e)
            .whereType<Object>()
            .join(', ');
        if (details.isNotEmpty) message = '$message ($details)';
      }
    }

    DateTime? resetAt;
    final reset = int.tryParse(r.headers.value('x-ratelimit-reset') ?? '');
    final retryAfter = int.tryParse(r.headers.value('retry-after') ?? '');
    if (retryAfter != null) {
      resetAt = DateTime.now().add(Duration(seconds: retryAfter));
    } else if (reset != null) {
      resetAt = DateTime.fromMillisecondsSinceEpoch(reset * 1000);
    }
    final exhausted = r.headers.value('x-ratelimit-remaining') == '0';

    final kind = switch (status) {
      401 => GithubErrorKind.unauthorized,
      403 ||
      429 when exhausted || retryAfter != null => GithubErrorKind.rateLimited,
      403 when message.toLowerCase().contains('rate limit') =>
        GithubErrorKind.rateLimited,
      403 => GithubErrorKind.forbidden,
      429 => GithubErrorKind.rateLimited,
      404 => GithubErrorKind.notFound,
      409 when message.toLowerCase().contains('empty') =>
        GithubErrorKind.emptyRepository,
      409 => GithubErrorKind.conflict,
      422 when message.toLowerCase().contains('fast forward') =>
        GithubErrorKind.conflict,
      422 => GithubErrorKind.validation,
      >= 500 => GithubErrorKind.server,
      _ => GithubErrorKind.unknown,
    };
    throw GithubException(
      kind,
      message,
      statusCode: status,
      resetAt: kind == GithubErrorKind.rateLimited ? resetAt : null,
    );
  }

  static Map<String, Object?> _map(Response<Object?> r) =>
      (r.data! as Map).cast<String, Object?>();

  static List<Map<String, Object?>> _list(Response<Object?> r) => [
    for (final e in r.data! as List) (e as Map).cast<String, Object?>(),
  ];

  static String _seg(String s) => Uri.encodeComponent(s);

  static String _repoPath(String owner, String repo) =>
      '/repos/${_seg(owner)}/${_seg(repo)}';

  static String _encodePath(String path) =>
      path.split('/').where((s) => s.isNotEmpty).map(_seg).join('/');

  // --- Compte et dépôts ---------------------------------------------------

  Future<GithubUser> getUser() async {
    final r = await _send('GET', '/user');
    final scopes = r.headers.value('x-oauth-scopes');
    return GithubUser.fromJson(
      _map(r),
      scopes: scopes
          ?.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      tokenExpiration: r.headers.value(
        'github-authentication-token-expiration',
      ),
    );
  }

  /// Dépôts accessibles, toutes pages confondues (limite de sécurité).
  Future<List<GithubRepo>> listRepos({int maxPages = 10}) async {
    final repos = <GithubRepo>[];
    for (var page = 1; page <= maxPages; page++) {
      final r = await _send(
        'GET',
        '/user/repos',
        query: {'per_page': 100, 'page': page, 'sort': 'updated'},
      );
      final items = _list(r);
      repos.addAll(items.map(GithubRepo.fromJson));
      final link = r.headers.value('link') ?? '';
      if (items.length < 100 || !link.contains('rel="next"')) break;
    }
    return repos;
  }

  /// Crée un dépôt avec un premier commit (README) afin que la publication
  /// par l'API Git soit immédiatement possible.
  Future<GithubRepo> createRepo({
    required String name,
    required bool isPrivate,
    String? description,
  }) async {
    final r = await _send(
      'POST',
      '/user/repos',
      body: {
        'name': name,
        'private': isPrivate,
        'description': ?description,
        'auto_init': true,
      },
    );
    return GithubRepo.fromJson(_map(r));
  }

  Future<GithubRepo> getRepo(String owner, String repo) async =>
      GithubRepo.fromJson(_map(await _send('GET', _repoPath(owner, repo))));

  Future<List<String>> listBranches(String owner, String repo) async {
    final r = await _send(
      'GET',
      '${_repoPath(owner, repo)}/branches',
      query: {'per_page': 100},
    );
    return _list(r).map((b) => b['name']! as String).toList();
  }

  /// Contenu d'un dossier (ou d'un fichier, renvoyé seul dans la liste).
  Future<List<GithubContentEntry>> getContents(
    String owner,
    String repo, {
    String path = '',
    String? ref,
  }) async {
    final p = _encodePath(path);
    final r = await _send(
      'GET',
      '${_repoPath(owner, repo)}/contents${p.isEmpty ? '' : '/$p'}',
      query: {'ref': ?ref},
    );
    final data = r.data;
    if (data is List) {
      final entries = _list(r).map(GithubContentEntry.fromJson).toList()
        ..sort((a, b) {
          if (a.type != b.type) return a.type == ContentType.dir ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return entries;
    }
    return [GithubContentEntry.fromJson(_map(r))];
  }

  Future<List<GithubCommitSummary>> listCommits(
    String owner,
    String repo, {
    String? branch,
    int perPage = 10,
  }) async {
    final r = await _send(
      'GET',
      '${_repoPath(owner, repo)}/commits',
      query: {'per_page': perPage, 'sha': ?branch},
    );
    return _list(r).map(GithubCommitSummary.fromJson).toList();
  }

  // --- API Git (publication en un seul commit) ----------------------------

  /// Empreinte du dernier commit de la branche.
  Future<String> getBranchHead(String owner, String repo, String branch) async {
    final r = await _send(
      'GET',
      '${_repoPath(owner, repo)}/git/ref/heads/${_encodePath(branch)}',
    );
    return (_map(r)['object']! as Map)['sha']! as String;
  }

  Future<String> getCommitTree(String owner, String repo, String sha) async {
    final r = await _send('GET', '${_repoPath(owner, repo)}/git/commits/$sha');
    return (_map(r)['tree']! as Map)['sha']! as String;
  }

  Future<RemoteTree> getTree(String owner, String repo, String treeSha) async {
    final r = await _send(
      'GET',
      '${_repoPath(owner, repo)}/git/trees/$treeSha',
      query: {'recursive': '1'},
    );
    final json = _map(r);
    return RemoteTree({
      for (final e in json['tree']! as List)
        if ((e as Map)['type'] == 'blob')
          e['path']! as String: e['sha']! as String,
    }, truncated: json['truncated'] == true);
  }

  /// Contenu d'un blob (petits fichiers texte, ex. `.gitattributes`).
  Future<Uint8List> getBlob(String owner, String repo, String sha) async {
    final r = await _send('GET', '${_repoPath(owner, repo)}/git/blobs/$sha');
    final json = _map(r);
    final content = (json['content'] as String? ?? '').replaceAll('\n', '');
    return json['encoding'] == 'base64'
        ? base64Decode(content)
        : Uint8List.fromList(utf8.encode(content));
  }

  Future<String> createBlob(String owner, String repo, Uint8List bytes) async {
    final r = await _send(
      'POST',
      '${_repoPath(owner, repo)}/git/blobs',
      body: {'content': base64Encode(bytes), 'encoding': 'base64'},
    );
    return _map(r)['sha']! as String;
  }

  Future<String> createTree(
    String owner,
    String repo, {
    required String baseTree,
    required Map<String, String> blobsByPath,
  }) async {
    final r = await _send(
      'POST',
      '${_repoPath(owner, repo)}/git/trees',
      body: {
        'base_tree': baseTree,
        'tree': [
          for (final e in blobsByPath.entries)
            {'path': e.key, 'mode': '100644', 'type': 'blob', 'sha': e.value},
        ],
      },
    );
    return _map(r)['sha']! as String;
  }

  Future<String> createCommit(
    String owner,
    String repo, {
    required String message,
    required String tree,
    required List<String> parents,
  }) async {
    final r = await _send(
      'POST',
      '${_repoPath(owner, repo)}/git/commits',
      body: {'message': message, 'tree': tree, 'parents': parents},
    );
    return _map(r)['sha']! as String;
  }

  /// Avance la branche sans jamais forcer : si elle a évolué entre-temps,
  /// GitHub refuse et une [GithubException] de type `conflict` est levée.
  Future<void> updateBranch(
    String owner,
    String repo,
    String branch,
    String sha,
  ) async {
    await _send(
      'PATCH',
      '${_repoPath(owner, repo)}/git/refs/heads/${_encodePath(branch)}',
      body: {'sha': sha, 'force': false},
    );
  }

  /// API Contents : un commit par fichier. Utilisée uniquement pour un dépôt
  /// vide, que l'API Git ne sait pas initialiser.
  Future<String> putFile(
    String owner,
    String repo, {
    required String path,
    required Uint8List bytes,
    required String message,
    String? branch,
  }) async {
    final r = await _send(
      'PUT',
      '${_repoPath(owner, repo)}/contents/${_encodePath(path)}',
      body: {
        'message': message,
        'content': base64Encode(bytes),
        'branch': ?branch,
      },
    );
    return (_map(r)['commit']! as Map)['sha']! as String;
  }
}
