import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/github_api.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';

import '../../support/fake_github_server.dart';

class _OneShot implements HttpClientAdapter {
  _OneShot(this.response);

  final ResponseBody Function() response;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<dynamic>? s,
    Future<void>? c,
  ) async {
    last = o;
    return response();
  }

  @override
  void close({bool force = false}) {}
}

Future<GithubException> errorFor(
  int status,
  Map<String, Object?> body, {
  Map<String, List<String>> headers = const {},
}) async {
  final adapter = _OneShot(
    () => FakeGithubServer.json(status, body, headers: headers),
  );
  final api = GithubApi(token: 't', dio: Dio()..httpClientAdapter = adapter);
  try {
    await api.getUser();
  } on GithubException catch (e) {
    return e;
  }
  fail('aucune exception');
}

void main() {
  test('en-têtes : authentification, version d\'API, JSON GitHub', () async {
    final adapter = _OneShot(
      () => FakeGithubServer.json(
        200,
        {'login': 'a', 'html_url': 'https://github.com/a'},
        headers: {
          'github-authentication-token-expiration': ['2026-12-31 10:00:00 UTC'],
        },
      ),
    );
    final api = GithubApi(
      token: 'secret',
      dio: Dio()..httpClientAdapter = adapter,
    );
    final user = await api.getUser();
    expect(adapter.last!.headers['Authorization'], 'Bearer secret');
    expect(adapter.last!.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(adapter.last!.headers['Accept'], 'application/vnd.github+json');
    expect(user.scopes, isNull, reason: 'jeton fine-grained : pas de portées');
    expect(user.tokenExpiration, '2026-12-31 10:00:00 UTC');
  });

  group('erreurs typées', () {
    test('401', () async {
      expect(
        (await errorFor(401, {'message': 'Bad credentials'})).kind,
        GithubErrorKind.unauthorized,
      );
    });
    test('403 permission', () async {
      final e = await errorFor(403, {
        'message': 'Resource not accessible by personal access token',
      });
      expect(e.kind, GithubErrorKind.forbidden);
      expect(e.message, contains('not accessible'));
    });
    test('403 limite de débit avec heure de reprise', () async {
      final e = await errorFor(
        403,
        {'message': 'API rate limit exceeded'},
        headers: {
          'x-ratelimit-remaining': ['0'],
          'x-ratelimit-reset': ['1900000000'],
        },
      );
      expect(e.kind, GithubErrorKind.rateLimited);
      expect(e.resetAt, DateTime.fromMillisecondsSinceEpoch(1900000000000));
    });
    test('429 limite secondaire (retry-after)', () async {
      final e = await errorFor(
        429,
        {'message': 'slow down'},
        headers: {
          'retry-after': ['60'],
        },
      );
      expect(e.kind, GithubErrorKind.rateLimited);
      expect(e.resetAt!.isAfter(DateTime.now()), isTrue);
    });
    test('404, 409 dépôt vide, 422', () async {
      expect(
        (await errorFor(404, {'message': 'Not Found'})).kind,
        GithubErrorKind.notFound,
      );
      expect(
        (await errorFor(409, {'message': 'Git Repository is empty.'})).kind,
        GithubErrorKind.emptyRepository,
      );
      expect(
        (await errorFor(422, {'message': 'Update is not a fast forward'})).kind,
        GithubErrorKind.conflict,
      );
      final v = await errorFor(422, {
        'message': 'Repository creation failed.',
        'errors': [
          {'message': 'name already exists on this account'},
        ],
      });
      expect(v.kind, GithubErrorKind.validation);
      expect(v.message, contains('name already exists'));
    });
    test('500', () async {
      expect(
        (await errorFor(502, {'message': 'Bad gateway'})).kind,
        GithubErrorKind.server,
      );
    });
    test('réseau indisponible', () async {
      final dio = Dio()..httpClientAdapter = _Throwing();
      try {
        await GithubApi(token: 't', dio: dio).getUser();
        fail('aucune exception');
      } on GithubException catch (e) {
        expect(e.kind, GithubErrorKind.network);
      }
    });
  });

  test('pagination des dépôts', () async {
    final server = FakeGithubServer();
    for (var i = 0; i < 230; i++) {
      server.addRepo('testeur', 'r$i', empty: true);
    }
    final repos = await server.api().listRepos();
    expect(repos, hasLength(230));
    expect(server.requests.where((r) => r == 'GET /user/repos'), hasLength(3));
  });

  test('chemins encodés (espaces, accents)', () async {
    final server = FakeGithubServer();
    server.addRepo(
      'testeur',
      'album',
      files: {
        'été 2024/plage 1.jpg': [1, 2],
      },
    );
    final entries = await server.api().getContents(
      'testeur',
      'album',
      path: 'été 2024',
    );
    expect(entries.single.path, 'été 2024/plage 1.jpg');
    expect(entries.single.size, 2);
  });

  test(
    'création de dépôt : privé, initialisé, sans description vide',
    () async {
      final server = FakeGithubServer();
      final adapter = _Recording(server);
      final api = GithubApi(
        token: server.validToken,
        dio: Dio()..httpClientAdapter = adapter,
      );
      final repo = await api.createRepo(name: 'nouveau', isPrivate: true);
      expect(repo.isPrivate, isTrue);
      expect(adapter.lastBody, {
        'name': 'nouveau',
        'private': true,
        'auto_init': true,
      });
      final again = api.createRepo(name: 'nouveau', isPrivate: true);
      expect(
        again,
        throwsA(
          isA<GithubException>().having(
            (e) => e.kind,
            'kind',
            GithubErrorKind.validation,
          ),
        ),
      );
    },
  );
}

class _Throwing implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<dynamic>? s,
    Future<void>? c,
  ) => throw DioException.connectionError(
    requestOptions: o,
    reason: 'hors ligne',
  );

  @override
  void close({bool force = false}) {}
}

class _Recording implements HttpClientAdapter {
  _Recording(this.inner);

  final FakeGithubServer inner;
  Object? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<dynamic>? s,
    Future<void>? c,
  ) {
    lastBody = o.data;
    return inner.fetch(o, null, c);
  }

  @override
  void close({bool force = false}) {}
}
