import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_query.dart';

NewMedia media(
  String name, {
  MediaKind kind = MediaKind.image,
  int size = 100,
  String? sha,
  DateTime? taken,
  int importedDay = 1,
}) => NewMedia(
  fileName: name,
  storedPath: '/lib/$name',
  sourcePath: '/src/$name',
  kind: kind,
  mimeType: kind == MediaKind.image ? 'image/jpeg' : 'video/mp4',
  sizeBytes: size,
  sha256: sha ?? name,
  importedAt: DateTime(2025, 1, importedDay),
  takenAt: taken,
  thumbnailBytes: 10,
);

void main() {
  late AppDatabase db;
  late MediaRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = MediaRepository(db);
  });
  tearDown(() => db.close());

  test('insertion et relecture complète', () {
    final id = repo.insert(
      NewMedia(
        fileName: 'a.jpg',
        storedPath: '/lib/a.jpg',
        sourcePath: '/src/a.jpg',
        kind: MediaKind.image,
        mimeType: 'image/jpeg',
        sizeBytes: 1234,
        sha256: 'abc',
        importedAt: DateTime(2025, 3, 1, 12),
        takenAt: DateTime(2024, 7, 14, 10, 30),
        width: 4000,
        height: 3000,
        cameraModel: 'Pixel Cam',
        hasGps: true,
        thumbnailPath: '/lib/t.png',
        thumbnailBytes: 50,
      ),
    );
    final m = repo.findById(id)!;
    expect(m.fileName, 'a.jpg');
    expect(m.kind, MediaKind.image);
    expect(m.width, 4000);
    expect(m.takenAt, DateTime(2024, 7, 14, 10, 30));
    expect(m.cameraModel, 'Pixel Cam');
    expect(m.hasGps, isTrue);
    expect(repo.findBySha256('abc')!.id, id);
    expect(repo.findBySha256('zzz'), isNull);
  });

  test('une même empreinte ne peut être enregistrée deux fois', () {
    repo.insert(media('a.jpg', sha: 'same'));
    expect(() => repo.insert(media('b.jpg', sha: 'same')), throwsA(anything));
  });

  test('filtres photos / vidéos', () {
    repo.insert(media('a.jpg'));
    repo.insert(media('b.mp4', kind: MediaKind.video));
    List<String> names(MediaFilter f) => repo
        .list(MediaListQuery(filter: f, sort: MediaSort.name, ascending: true))
        .map((m) => m.fileName)
        .toList();
    expect(names(MediaFilter.all), ['a.jpg', 'b.mp4']);
    expect(names(MediaFilter.images), ['a.jpg']);
    expect(names(MediaFilter.videos), ['b.mp4']);
  });

  test('recherche insensible à la casse, caractères spéciaux littéraux', () {
    repo.insert(media('Vacances_2024.jpg'));
    repo.insert(media('vacances-2023.jpg'));
    repo.insert(media('100%.jpg'));
    List<String> search(String s) => repo
        .list(MediaListQuery(search: s, sort: MediaSort.name, ascending: true))
        .map((m) => m.fileName)
        .toList();
    expect(search('VACANCES'), ['vacances-2023.jpg', 'Vacances_2024.jpg']);
    expect(search('_'), ['Vacances_2024.jpg']);
    expect(search('%'), ['100%.jpg']);
    expect(search('  '), hasLength(3));
  });

  test('tris par nom, taille, type et date', () {
    repo.insert(media('b.jpg', size: 300, importedDay: 1));
    repo.insert(
      media('a.mp4', kind: MediaKind.video, size: 100, importedDay: 3),
    );
    repo.insert(
      media('c.jpg', size: 200, importedDay: 2, taken: DateTime(2020)),
    );
    List<String> sorted(MediaSort s, {bool asc = true}) => repo
        .list(MediaListQuery(sort: s, ascending: asc))
        .map((m) => m.fileName)
        .toList();
    expect(sorted(MediaSort.name), ['a.mp4', 'b.jpg', 'c.jpg']);
    expect(sorted(MediaSort.size), ['a.mp4', 'c.jpg', 'b.jpg']);
    expect(sorted(MediaSort.size, asc: false), ['b.jpg', 'c.jpg', 'a.mp4']);
    expect(sorted(MediaSort.type).first, 'b.jpg'); // image avant vidéo
    // La date de prise de vue prime sur la date d'import.
    expect(sorted(MediaSort.date), ['c.jpg', 'b.jpg', 'a.mp4']);
  });

  test('suppression et espace occupé', () {
    final a = repo.insert(media('a.jpg', size: 100));
    final b = repo.insert(media('b.jpg', size: 200));
    expect(repo.librarySizeBytes(), 100 + 200 + 2 * 10);
    final removed = repo.deleteByIds([a]);
    expect(removed.single.fileName, 'a.jpg');
    expect(repo.findById(a), isNull);
    expect(repo.findById(b), isNotNull);
    expect(repo.deleteByIds(const []), isEmpty);
    expect(repo.librarySizeBytes(), 210);
  });
}
