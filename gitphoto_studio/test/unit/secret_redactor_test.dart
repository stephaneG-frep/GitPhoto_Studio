import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/logging/app_logger.dart';
import 'package:gitphoto_studio/core/security/secret_redactor.dart';

void main() {
  const mask = SecretRedactor.mask;

  test('masque les jetons GitHub classiques et fine-grained', () {
    const classic = 'ghp_abcdefghijklmnopqrstuvwxyz0123456789';
    const fine = 'github_pat_11ABCDEFG0123456789_abcdefghijklmnopqrstuvwxyz';
    final out = SecretRedactor.redact('jeton $classic puis $fine');
    expect(out, isNot(contains(classic)));
    expect(out, isNot(contains(fine)));
    expect(out, 'jeton $mask puis $mask');
  });

  test('masque les en-têtes Authorization et clés API', () {
    expect(
      SecretRedactor.redact('Authorization: Bearer abc.def.ghi'),
      'Authorization: Bearer $mask',
    );
    expect(
      SecretRedactor.redact('authorization: token xyz123'),
      'authorization: token $mask',
    );
    expect(SecretRedactor.redact('x-api-key: k-123456'), 'x-api-key: $mask');
  });

  test('masque les clés dans les URL', () {
    expect(
      SecretRedactor.redact('https://api.example.com/v1?key=SECRET123&x=1'),
      'https://api.example.com/v1?key=$mask&x=1',
    );
  });

  test('masque les clés de fournisseurs IA', () {
    const key = 'sk-ant-api03-AbCdEfGhIjKlMnOpQrStUv';
    expect(SecretRedactor.redact('clé=$key'), isNot(contains(key)));
    const google = 'AIzaSyA1234567890abcdefghijklmnopqrstu';
    expect(SecretRedactor.redact(google), mask);
  });

  test('laisse intact un texte sans secret', () {
    const text = 'Publication de 3 photos dans owner/portfolio (main)';
    expect(SecretRedactor.redact(text), text);
  });

  test('le journal ne conserve jamais le secret et respecte sa capacité', () {
    final logger = AppLogger(capacity: 2);
    logger.info('a');
    logger.error('échec avec ghp_abcdefghijklmnopqrstuvwxyz0123456789');
    logger.warning('c');
    expect(logger.entries, hasLength(2));
    expect(logger.entries.first.message, 'échec avec $mask');
    expect(logger.entries.last.level, LogLevel.warning);
  });
}
