import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/app/providers.dart';
import 'package:gitphoto_studio/core/database/app_database.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_environment.dart';
import 'package:gitphoto_studio/features/ai_agent/application/agent_tools.dart';
import 'package:gitphoto_studio/features/dashboard/application/dashboard_stats.dart';
import 'package:gitphoto_studio/features/gallery/data/album_repository.dart';
import 'package:gitphoto_studio/features/gallery/data/media_repository.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_item.dart';
import 'package:gitphoto_studio/features/gallery/domain/media_query.dart';
import 'package:gitphoto_studio/features/github/application/github_session.dart';
import 'package:gitphoto_studio/features/help/application/guided_tour.dart';

import '../support/fake_secret_store.dart';

/// Grosse bibliothèque (5 000 médias, 50 albums) : les opérations courantes
/// restent rapides. Seuils larges : ils détectent un coût quadratique, pas
/// une variation de machine.
void main() {
  late AppDatabase db;
  const n = 5000;

  setUpAll(() {
    db = AppDatabase.inMemory();
    final media = MediaRepository(db);
    final albums = AlbumRepository(db);
    final albumIds = [
      for (var a = 0; a < 50; a++) albums.findOrCreate('Album $a'),
    ];
    db.raw.execute('BEGIN');
    for (var i = 0; i < n; i++) {
      media.insert(
        NewMedia(
          fileName: 'photo_$i.jpg',
          storedPath: '/x/$i.jpg',
          sourcePath: '/x/$i.jpg',
          kind: i % 10 == 0 ? MediaKind.video : MediaKind.image,
          sizeBytes: 1000 + i,
          sha256: 'sha$i',
          importedAt: DateTime(2020).add(Duration(hours: i)),
          takenAt: i.isEven ? DateTime(2019).add(Duration(hours: i)) : null,
          albumId: i % 3 == 0 ? albumIds[i % 50] : null,
        ),
      );
    }
    db.raw.execute('COMMIT');
  });
  tearDownAll(() => db.close());

  int ms(void Function() f) {
    final sw = Stopwatch()..start();
    f();
    return sw.elapsedMilliseconds;
  }

  Future<int> msAsync(Future<void> Function() f) async {
    final sw = Stopwatch()..start();
    await f();
    return sw.elapsedMilliseconds;
  }

  test('requêtes de la galerie', () {
    final repo = MediaRepository(db);
    final timings = <String, int>{
      'tri par date': ms(
        () => expect(repo.list(const MediaListQuery()), hasLength(n)),
      ),
      'tri par nom': ms(
        () => repo.list(const MediaListQuery(sort: MediaSort.name)),
      ),
      'vidéos': ms(
        () => repo.list(const MediaListQuery(filter: MediaFilter.videos)),
      ),
      'recherche': ms(() => repo.list(const MediaListQuery(search: '_42'))),
      'album': ms(() => repo.list(const MediaListQuery(albumId: 1))),
      'taille totale': ms(repo.librarySizeBytes),
    };
    // ignore: avoid_print
    print('Galerie ($n médias) : $timings');
    for (final e in timings.entries) {
      expect(e.value, lessThan(1500), reason: e.key);
    }
  });

  test('tableau de bord, parcours guidé, recherche de l’agent', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        secretStoreProvider.overrideWithValue(FakeSecretStore()),
      ],
    );
    addTearDown(container.dispose);
    final dash = ms(() => container.read(dashboardStatsProvider));
    final tour = ms(() => container.read(guidedTourProvider));
    final tools = AgentToolbox(container.read(agentEnvironmentProvider));
    late Map<String, Object?> result;
    final agent = await msAsync(() async {
      result =
          jsonDecode(
                await tools.run(AgentToolNames.searchMedia, {'limit': 200}),
              )
              as Map<String, Object?>;
    });
    final albumSearch = await msAsync(
      () => tools.run(AgentToolNames.searchMedia, {
        'album': 'Album 7',
        'limit': 200,
      }),
    );
    // ignore: avoid_print
    print(
      'Accueil $dash ms, parcours $tour ms, agent $agent ms, agent/album $albumSearch ms',
    );
    expect(result['total'], n);
    // Raccourcie par éléments entiers, avec la consigne pour la suite.
    final items = result['items']! as List;
    expect(items.length, result['returned']);
    expect(items.length, inInclusiveRange(50, 200));
    expect(result['note'], contains('offset=${items.length}'));
    expect(dash, lessThan(1500));
    expect(tour, lessThan(1500));
    expect(agent, lessThan(1500));
    expect(albumSearch, lessThan(1500));
  });
}
