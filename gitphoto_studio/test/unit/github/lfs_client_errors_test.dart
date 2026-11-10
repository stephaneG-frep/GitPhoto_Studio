import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/github_exception.dart';
import 'package:gitphoto_studio/features/github/data/lfs_client.dart';
import 'package:gitphoto_studio/shared/open_url.dart';
import 'package:path/path.dart' as p;

import '../../support/fake_ai.dart';

/// Réponses inhabituelles du service Git LFS (serveur simulé).
void main() {
  late Directory dir;
  late File file;
  late LfsObject object;
  late FakeAiHttp http;
  late LfsClient lfs;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('gitphoto_lfs_');
    file = File(p.join(dir.path, 'video.mp4'))
      ..writeAsBytesSync(List.filled(4096, 7));
    object = await LfsObject.ofFile(file.path);
    http = FakeAiHttp();
    lfs = LfsClient(
      token: 'ghp_jeton_de_test_000000000000000000000',
      dio: http.dio(),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, Object?> actions({bool verify = true}) => {
    'objects': [
      {
        'oid': object.oid,
        'size': object.size,
        'actions': {
          'upload': {
            'href': 'https://lfs.example/upload/${object.oid}',
            'header': {'X-Signature': 'abc'},
          },
          if (verify) 'verify': {'href': 'https://lfs.example/verify'},
        },
      },
    ],
  };

  Future<void> expectKind(
    Future<Object?> f,
    GithubErrorKind kind, [
    String? text,
  ]) => expectLater(
    f,
    throwsA(
      isA<GithubException>()
          .having((e) => e.kind, 'kind', kind)
          .having((e) => e.message, 'message', contains(text ?? '')),
    ),
  );

  test('envoi complet : lot, transfert en flux, vérification', () async {
    http
      ..reply(200, actions())
      ..reply(200, {})
      ..reply(200, {});
    expect(await lfs.upload('o', 'r', file.path, object), isTrue);
    final batch = http.requests[0];
    expect(batch.uri.toString(), contains('/o/r.git/info/lfs/objects/batch'));
    expect(batch.body!['operation'], 'upload');
    expect(http.requests[1].method, 'PUT');
    expect(http.requests[1].headers['X-Signature'], 'abc');
    expect(http.requests[2].uri.toString(), 'https://lfs.example/verify');
  });

  test('objet déjà stocké : aucun transfert', () async {
    http.reply(200, {
      'objects': [
        {'oid': object.oid, 'size': object.size},
      ],
    });
    expect(await lfs.upload('o', 'r', file.path, object), isFalse);
    expect(http.requests, hasLength(1));
  });

  test('quota de stockage dépassé (507) : refus explicite', () async {
    http.reply(507, {'message': 'Insufficient storage'});
    await expectKind(
      lfs.upload('o', 'r', file.path, object),
      GithubErrorKind.validation,
      'Insufficient storage',
    );
  });

  test('objet refusé dans la réponse du lot : code repris', () async {
    http.reply(200, {
      'objects': [
        {
          'oid': object.oid,
          'error': {'code': 422, 'message': 'Size exceeds limit'},
        },
      ],
    });
    await expectKind(
      lfs.upload('o', 'r', file.path, object),
      GithubErrorKind.validation,
      'code 422',
    );
  });

  test('codes HTTP du lot → erreurs typées', () async {
    for (final (status, kind) in [
      (401, GithubErrorKind.unauthorized),
      (403, GithubErrorKind.forbidden),
      (404, GithubErrorKind.notFound),
      (429, GithubErrorKind.rateLimited),
      (503, GithubErrorKind.server),
      (418, GithubErrorKind.unknown),
    ]) {
      http.reply(status, {'message': 'refus $status'});
      await expectKind(lfs.upload('o', 'r', file.path, object), kind, 'refus');
    }
  });

  test(
    'réponse illisible : code HTTP conservé, pas « panne réseau »',
    () async {
      http.reply(401, 'pas du JSON');
      await expectKind(
        lfs.upload('o', 'r', file.path, object),
        GithubErrorKind.unauthorized,
        'HTTP 401',
      );
    },
  );

  test('transfert refusé par le stockage : erreur serveur', () async {
    http
      ..reply(200, actions())
      ..reply(500, 'oups');
    await expectKind(
      lfs.upload('o', 'r', file.path, object),
      GithubErrorKind.server,
      'envoi refusé',
    );
    // La vérification n'est pas tentée.
    expect(http.requests, hasLength(2));
  });

  test('vérification refusée : erreur, pas de faux succès', () async {
    http
      ..reply(200, actions())
      ..reply(200, {})
      ..reply(404, {'message': 'missing'});
    await expectKind(
      lfs.upload('o', 'r', file.path, object),
      GithubErrorKind.unknown,
      'vérification refusée',
    );
  });

  test('liens ouverts : https uniquement', () {
    expect(isOpenableUrl('https://github.com/a/b'), isTrue);
    for (final bad in [
      'http://github.com',
      'file:///etc/passwd',
      'intent://scan#Intent;end',
      'javascript:alert(1)',
      'https://',
      'pas une adresse',
    ]) {
      expect(isOpenableUrl(bad), isFalse, reason: bad);
    }
  });
}
