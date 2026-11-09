import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/lfs_client.dart';
import 'package:gitphoto_studio/features/publishing/domain/git_blob_hash.dart';

/// FAUX SERVEUR GITHUB EN MÉMOIRE — RÉSERVÉ AUX TESTS.
///
/// Reproduit le sous-ensemble de l'API utilisé par l'application pour tester
/// le client et le publieur réels sans réseau. Il ne prouve en rien le
/// fonctionnement face au vrai GitHub (voir les tests d'intégration réels).
class FakeGithubServer implements HttpClientAdapter {
  FakeGithubServer({
    this.validToken = 'ghp_valid_token_for_tests_000000000000',
  });

  final String validToken;
  final requests = <String>[];

  /// Stockage Git LFS simulé : oid → contenu.
  final lfsObjects = <String, List<int>>{};

  LfsClient lfs([String? token]) => LfsClient(
    token: token ?? validToken,
    dio: Dio()..httpClientAdapter = this,
  );
  final Map<String, FakeRepo> repos = {};

  /// Réponse forcée pour la prochaine requête correspondant au motif.
  final overrides = <RegExp, ResponseBody Function()>{};

  /// Appelé après chaque création de blob (simulation de concurrence).
  void Function(FakeRepo repo)? afterBlob;

  /// Appelé juste avant l'avancée d'une branche (commit concurrent).
  void Function(FakeRepo repo)? beforeRefUpdate;

  int _counter = 0;
  String newSha() => sha1.convert(utf8.encode('fake-${_counter++}')).toString();

  FakeRepo addRepo(
    String owner,
    String name, {
    bool isPrivate = true,
    bool empty = false,
    bool canPush = true,
    Map<String, List<int>> files = const {},
  }) {
    final repo = FakeRepo(this, owner, name, isPrivate, canPush);
    repos['$owner/$name'] = repo;
    if (!empty) {
      repo.commitFiles({
        'README.md': utf8.encode('# $name\n'),
        ...files,
      }, 'Initial commit');
    }
    return repo;
  }

  GithubApi api([String? token]) => GithubApi(
    token: token ?? validToken,
    dio: Dio()..httpClientAdapter = this,
  );

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method;
    final path = options.uri.path;
    requests.add('$method $path');
    if (options.uri.host != 'api.github.com') {
      return _lfs(options, requestStream);
    }
    for (final e in overrides.entries) {
      if (e.key.hasMatch('$method $path')) {
        overrides.remove(e.key);
        return e.value();
      }
    }
    if (options.headers['Authorization'] != 'Bearer $validToken') {
      return json(401, {'message': 'Bad credentials'});
    }
    final body = options.data is Map
        ? (options.data as Map).cast<String, Object?>()
        : <String, Object?>{};
    final q = options.uri.queryParameters;
    final segments = options.uri.pathSegments;

    if (method == 'GET' && path == '/user') {
      return json(
        200,
        {
          'login': 'testeur',
          'name': 'Testeur',
          'html_url': 'https://github.com/testeur',
          'avatar_url': null,
        },
        headers: {
          'x-oauth-scopes': ['repo'],
        },
      );
    }
    if (path == '/user/repos' && method == 'GET') {
      final page = int.parse(q['page'] ?? '1');
      final all = repos.values.toList();
      final perPage = int.parse(q['per_page'] ?? '30');
      final slice = all.skip((page - 1) * perPage).take(perPage).toList();
      final hasNext = page * perPage < all.length;
      return json(
        200,
        [for (final r in slice) r.toJson()],
        headers: {
          if (hasNext) 'link': ['<x?page=${page + 1}>; rel="next"'],
        },
      );
    }
    if (path == '/user/repos' && method == 'POST') {
      final name = body['name']! as String;
      if (repos.containsKey('testeur/$name')) {
        return json(422, {
          'message': 'Repository creation failed.',
          'errors': [
            {'message': 'name already exists on this account'},
          ],
        });
      }
      final r = addRepo(
        'testeur',
        name,
        isPrivate: body['private'] == true,
        empty: body['auto_init'] != true,
      );
      return json(201, r.toJson());
    }

    if (segments.length >= 3 && segments[0] == 'repos') {
      final repo = repos['${segments[1]}/${segments[2]}'];
      if (repo == null) return json(404, {'message': 'Not Found'});
      return repo.handle(method, segments.sublist(3), q, body);
    }
    return json(404, {'message': 'Not Found'});
  }

  Future<ResponseBody> _lfs(
    RequestOptions options,
    Stream<Uint8List>? body,
  ) async {
    final expected =
        'Basic ${base64Encode(utf8.encode('x-access-token:$validToken'))}';
    final path = options.uri.path;
    if (options.uri.host == 'lfs.fake') {
      final oid = path.split('/').last;
      if (path.startsWith('/upload/')) {
        final bytes = <int>[];
        if (body != null) {
          await for (final chunk in body) {
            bytes.addAll(chunk);
          }
        }
        if (sha256.convert(bytes).toString() != oid) {
          return json(422, {'message': 'oid mismatch'});
        }
        lfsObjects[oid] = bytes;
        return json(200, {});
      }
      if (path.startsWith('/verify/')) {
        return lfsObjects.containsKey(oid)
            ? json(200, {})
            : json(404, {'message': 'missing'});
      }
    }
    if (!path.endsWith('/info/lfs/objects/batch')) {
      return json(404, {'message': 'Not Found'});
    }
    if (options.headers['Authorization'] != expected) {
      return json(401, {'message': 'Credentials needed'});
    }
    final request = jsonDecode(options.data as String) as Map<String, Object?>;
    final operation = request['operation'];
    return json(200, {
      'transfer': 'basic',
      'objects': [
        for (final o
            in (request['objects']! as List).cast<Map<String, Object?>>())
          if (operation == 'upload')
            lfsObjects.containsKey(o['oid'])
                ? {'oid': o['oid'], 'size': o['size']}
                : {
                    'oid': o['oid'],
                    'size': o['size'],
                    'actions': {
                      'upload': {'href': 'https://lfs.fake/upload/${o['oid']}'},
                      'verify': {'href': 'https://lfs.fake/verify/${o['oid']}'},
                    },
                  }
          else
            lfsObjects.containsKey(o['oid'])
                ? {
                    'oid': o['oid'],
                    'size': o['size'],
                    'actions': {
                      'download': {'href': 'https://lfs.fake/get/${o['oid']}'},
                    },
                  }
                : {
                    'oid': o['oid'],
                    'size': o['size'],
                    'error': {'code': 404, 'message': 'Object does not exist'},
                  },
      ],
    });
  }

  static ResponseBody json(
    int status,
    Object body, {
    Map<String, List<String>> headers = const {},
  }) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        ...headers,
      },
    );
  }
}

class FakeCommit {
  FakeCommit(this.sha, this.tree, this.parents, this.message);

  final String sha;
  final String tree;
  final List<String> parents;
  final String message;
}

class FakeRepo {
  FakeRepo(this.server, this.owner, this.name, this.isPrivate, this.canPush);

  final FakeGithubServer server;
  final String owner;
  final String name;
  final bool isPrivate;
  final bool canPush;
  final Map<String, String> branches = {};
  final Map<String, FakeCommit> commits = {};
  final Map<String, Map<String, String>> trees = {};
  final Map<String, List<int>> blobs = {};

  bool get isEmpty => branches.isEmpty;

  Map<String, Object?> toJson() => {
    'name': name,
    'owner': {'login': owner},
    'private': isPrivate,
    'html_url': 'https://github.com/$owner/$name',
    'default_branch': 'main',
    'description': null,
    'permissions': {'push': canPush, 'pull': true},
  };

  /// Fichiers de la branche (chemin → contenu).
  Map<String, List<int>> filesOf(String branch) {
    final head = branches[branch];
    if (head == null) return {};
    final tree = trees[commits[head]!.tree]!;
    return {for (final e in tree.entries) e.key: blobs[e.value]!};
  }

  String commitFiles(
    Map<String, List<int>> files,
    String message, {
    String branch = 'main',
  }) {
    final parent = branches[branch];
    final base = parent == null
        ? <String, String>{}
        : trees[commits[parent]!.tree]!;
    final tree = {...base};
    for (final f in files.entries) {
      final sha = gitBlobSha(f.value);
      blobs[sha] = f.value;
      tree[f.key] = sha;
    }
    final treeSha = server.newSha();
    trees[treeSha] = tree;
    final sha = server.newSha();
    commits[sha] = FakeCommit(sha, treeSha, [?parent], message);
    branches[branch] = sha;
    return sha;
  }

  ResponseBody handle(
    String method,
    List<String> s,
    Map<String, String> q,
    Map<String, Object?> body,
  ) {
    ResponseBody j(int status, Object b) => FakeGithubServer.json(status, b);
    final empty = j(409, {'message': 'Git Repository is empty.'});

    if (s.isEmpty) return j(200, toJson());
    if (method != 'GET' && !canPush) {
      return j(403, {
        'message': 'Resource not accessible by personal access token',
      });
    }
    switch (s) {
      case ['branches']:
        return j(200, [
          for (final b in branches.keys) {'name': b},
        ]);
      case ['contents', ...final rest] when method == 'GET':
        if (isEmpty) return j(404, {'message': 'This repository is empty.'});
        final path = rest.join('/');
        final files = filesOf(q['ref'] ?? 'main');
        if (files.containsKey(path)) {
          return j(200, _entry(path, files[path]!.length, 'file'));
        }
        final prefix = path.isEmpty ? '' : '$path/';
        final children = <String, Map<String, Object?>>{};
        for (final f in files.entries.where((f) => f.key.startsWith(prefix))) {
          final rel = f.key.substring(prefix.length);
          final first = rel.split('/').first;
          final isDir = rel.contains('/');
          children[first] = _entry(
            '$prefix$first',
            isDir ? 0 : f.value.length,
            isDir ? 'dir' : 'file',
          );
        }
        if (children.isEmpty) return j(404, {'message': 'Not Found'});
        return j(200, children.values.toList());
      case ['contents', ...final rest] when method == 'PUT':
        final branch = (body['branch'] as String?) ?? 'main';
        final sha = commitFiles(
          {rest.join('/'): base64Decode(body['content']! as String)},
          body['message']! as String,
          branch: branch,
        );
        return j(201, {
          'commit': {'sha': sha},
        });
      case ['commits']:
        if (isEmpty) return empty;
        final out = <Map<String, Object?>>[];
        String? cur = branches[q['sha'] ?? 'main'];
        while (cur != null && out.length < 10) {
          final c = commits[cur]!;
          out.add({
            'sha': c.sha,
            'html_url': 'https://github.com/$owner/$name/commit/${c.sha}',
            'commit': {
              'message': c.message,
              'author': {'name': 'Testeur', 'date': '2025-01-01T10:00:00Z'},
            },
          });
          cur = c.parents.firstOrNull;
        }
        return j(200, out);
      case ['git', 'ref', 'heads', ...final b]:
        if (isEmpty) return empty;
        final sha = branches[b.join('/')];
        if (sha == null) return j(404, {'message': 'Not Found'});
        return j(200, {
          'object': {'sha': sha},
        });
      case ['git', 'commits', final sha] when method == 'GET':
        final c = commits[sha];
        if (c == null) return j(404, {'message': 'Not Found'});
        return j(200, {
          'sha': sha,
          'tree': {'sha': c.tree},
        });
      case ['git', 'trees', final sha] when method == 'GET':
        final t = trees[sha];
        if (t == null) return j(404, {'message': 'Not Found'});
        return j(200, {
          'sha': sha,
          'truncated': false,
          'tree': [
            for (final e in t.entries)
              {'path': e.key, 'type': 'blob', 'sha': e.value, 'mode': '100644'},
          ],
        });
      case ['git', 'blobs', final sha] when method == 'GET':
        final bytes = blobs[sha];
        if (bytes == null) return j(404, {'message': 'Not Found'});
        return j(200, {
          'sha': sha,
          'encoding': 'base64',
          'content': base64Encode(bytes),
        });
      case ['git', 'blobs'] when method == 'POST':
        if (isEmpty) return empty;
        final bytes = base64Decode(body['content']! as String);
        final sha = gitBlobSha(bytes);
        blobs[sha] = bytes;
        server.afterBlob?.call(this);
        return j(201, {'sha': sha});
      case ['git', 'trees'] when method == 'POST':
        final base = trees[body['base_tree']]!;
        final t = {...base};
        for (final e in body['tree']! as List) {
          final m = e as Map;
          if (!blobs.containsKey(m['sha'])) {
            return j(422, {'message': 'Invalid tree info'});
          }
          t[m['path'] as String] = m['sha'] as String;
        }
        final sha = server.newSha();
        trees[sha] = t;
        return j(201, {'sha': sha});
      case ['git', 'commits'] when method == 'POST':
        final sha = server.newSha();
        commits[sha] = FakeCommit(
          sha,
          body['tree']! as String,
          (body['parents']! as List).cast<String>(),
          body['message']! as String,
        );
        return j(201, {'sha': sha});
      case ['git', 'refs', 'heads', ...final b] when method == 'PATCH':
        server.beforeRefUpdate?.call(this);
        final branch = b.join('/');
        final newSha = body['sha']! as String;
        final current = branches[branch];
        final commit = commits[newSha];
        if (commit == null) return j(422, {'message': 'Object does not exist'});
        if (body['force'] != true && !commit.parents.contains(current)) {
          return j(422, {'message': 'Update is not a fast forward'});
        }
        branches[branch] = newSha;
        return j(200, {
          'object': {'sha': newSha},
        });
    }
    return j(404, {'message': 'Not Found'});
  }

  Map<String, Object?> _entry(String path, int size, String type) => {
    'name': path.split('/').last,
    'path': path,
    'type': type,
    'size': size,
    'sha': 'x',
    'html_url': 'https://github.com/$owner/$name/blob/main/$path',
  };
}
