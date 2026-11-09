import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/features/github/data/device_flow.dart';

import '../../support/fake_github_server.dart';

class _Scripted implements HttpClientAdapter {
  _Scripted(this.responses);

  final List<Map<String, Object?>> responses;
  final bodies = <Object?>[];
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<dynamic>? s,
    Future<void>? c,
  ) async {
    paths.add(o.uri.path);
    bodies.add(o.data);
    return FakeGithubServer.json(200, responses.removeAt(0));
  }

  @override
  void close({bool force = false}) {}
}

GithubDeviceFlow _flowWith(_Scripted adapter, List<Duration> waits) =>
    GithubDeviceFlow(
      clientId: 'Iv1.public',
      dio: Dio()..httpClientAdapter = adapter,
    )..wait = (d) async => waits.add(d);

void main() {
  const start = {
    'device_code': 'dev123',
    'user_code': 'ABCD-1234',
    'verification_uri': 'https://github.com/login/device',
    'interval': 5,
    'expires_in': 900,
  };

  test('démarrage puis jeton après attente et ralentissement', () async {
    final adapter = _Scripted([
      start,
      {'error': 'authorization_pending'},
      {'error': 'slow_down'},
      {'access_token': 'gho_token', 'token_type': 'bearer'},
    ]);
    final waits = <Duration>[];
    final flow = _flowWith(adapter, waits);
    final code = await flow.start();
    expect(code.userCode, 'ABCD-1234');
    expect(adapter.paths.first, '/login/device/code');
    expect(jsonEncode(adapter.bodies.first), contains('Iv1.public'));
    expect(jsonEncode(adapter.bodies.first), isNot(contains('secret')));

    expect(await flow.poll(code), 'gho_token');
    expect(waits.map((d) => d.inSeconds), [5, 5, 10]);
  });

  test('refus et expiration', () async {
    for (final (error, expected) in [
      ('access_denied', DeviceFlowError.denied),
      ('expired_token', DeviceFlowError.expired),
      ('incorrect_client_credentials', DeviceFlowError.misconfigured),
    ]) {
      final flow = _flowWith(
        _Scripted([
          start,
          {'error': error},
        ]),
        [],
      );
      final code = await flow.start();
      await expectLater(
        flow.poll(code),
        throwsA(
          isA<DeviceFlowException>().having((e) => e.error, 'error', expected),
        ),
      );
    }
  });

  test('Client ID invalide signalé dès le démarrage', () async {
    final flow = _flowWith(
      _Scripted([
        {
          'error': 'unauthorized_client',
          'error_description': 'Device flow disabled',
        },
      ]),
      [],
    );
    await expectLater(
      flow.start(),
      throwsA(
        isA<DeviceFlowException>().having(
          (e) => e.detail,
          'detail',
          'Device flow disabled',
        ),
      ),
    );
  });

  test('annulation par l\'utilisateur', () async {
    final flow = _flowWith(_Scripted([start]), []);
    final code = await flow.start();
    await expectLater(
      flow.poll(code, isCancelled: () => true),
      throwsA(isA<DeviceFlowException>()),
    );
  });
}
