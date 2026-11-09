import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/security/path_validator.dart';

void main() {
  group('validateRepoPath', () {
    test('accepte un chemin relatif ordinaire', () {
      final r = PathValidator.validateRepoPath('photos/2025/vacances été.jpg');
      expect(r.isValid, isTrue);
      expect(r.normalized, 'photos/2025/vacances été.jpg');
    });

    final rejected = <String, PathIssue>{
      '': PathIssue.empty,
      '   ': PathIssue.empty,
      '/etc/passwd': PathIssue.absolute,
      'C:/Users/a.jpg': PathIssue.absolute,
      '../secret.jpg': PathIssue.traversal,
      'photos/../../x.jpg': PathIssue.traversal,
      './a.jpg': PathIssue.currentDirSegment,
      'photos//a.jpg': PathIssue.emptySegment,
      'photos/': PathIssue.emptySegment,
      r'photos\a.jpg': PathIssue.backslash,
      '.git/config': PathIssue.gitDirectory,
      'a/.GIT/hooks': PathIssue.gitDirectory,
      'a\u0000b.jpg': PathIssue.controlCharacter,
      'a\nb.jpg': PathIssue.controlCharacter,
      'photo?.jpg': PathIssue.forbiddenCharacter,
      'a:b.jpg': PathIssue.forbiddenCharacter,
      'con.jpg': PathIssue.reservedName,
      'dossier/NUL': PathIssue.reservedName,
      'photo.': PathIssue.trailingDotOrSpace,
      'photo ': PathIssue.trailingDotOrSpace,
    };
    rejected.forEach((input, issue) {
      test(
        'rejette ${input.replaceAll('\u0000', r'\0').replaceAll('\n', r'\n')}'
        ' ($issue)',
        () {
          final r = PathValidator.validateRepoPath(input);
          expect(r.isValid, isFalse);
          expect(r.issues, contains(issue));
        },
      );
    });

    test('rejette un segment trop long (octets UTF-8)', () {
      final r = PathValidator.validateRepoPath('${'é' * 128}.jpg');
      expect(r.issues, contains(PathIssue.segmentTooLong));
    });

    test('rejette un chemin trop long', () {
      final r = PathValidator.validateRepoPath(
        List.filled(500, 'abcdefgh').join('/'),
      );
      expect(r.issues, contains(PathIssue.pathTooLong));
    });
  });

  group('validateFileName', () {
    test('rejette un séparateur de dossier', () {
      expect(PathValidator.validateFileName('a/b.jpg').isValid, isFalse);
      expect(PathValidator.validateFileName(r'a\b.jpg').isValid, isFalse);
    });

    test('accepte un nom simple', () {
      expect(PathValidator.validateFileName('IMG_0001.HEIC').isValid, isTrue);
    });
  });

  group('sanitizeFileName', () {
    test('produit toujours un nom valide', () {
      for (final input in [
        '../../etc/passwd',
        'a<b>c:d"e|f?g*h.jpg',
        '..',
        '.',
        '',
        'CON',
        '.git',
        'photo. ',
        'tab\there.png',
        'é' * 300,
      ]) {
        final sanitized = PathValidator.sanitizeFileName(input);
        expect(
          PathValidator.validateFileName(sanitized).isValid,
          isTrue,
          reason: '« $input » → « $sanitized »',
        );
      }
    });

    test('conserve un nom déjà sûr', () {
      expect(PathValidator.sanitizeFileName('photo-01.jpg'), 'photo-01.jpg');
    });
  });

  group('isWithinDirectory', () {
    const base = '/tmp/gitphoto/work';

    test('accepte un fichier du dossier', () {
      expect(PathValidator.isWithinDirectory(base, 'a/b.jpg'), isTrue);
      expect(PathValidator.isWithinDirectory(base, '$base/c.jpg'), isTrue);
    });

    test('refuse les traversées et les chemins extérieurs', () {
      expect(PathValidator.isWithinDirectory(base, '../x.jpg'), isFalse);
      expect(PathValidator.isWithinDirectory(base, 'a/../../x.jpg'), isFalse);
      expect(PathValidator.isWithinDirectory(base, '/etc/passwd'), isFalse);
      expect(
        PathValidator.isWithinDirectory(base, '/tmp/gitphoto/work2/a'),
        isFalse,
      );
      expect(PathValidator.isWithinDirectory(base, base), isFalse);
    });
  });
}
