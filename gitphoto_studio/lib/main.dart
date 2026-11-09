import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/database/app_database.dart';
import 'features/gallery/application/gallery_providers.dart';
import 'features/gallery/data/library_paths.dart';
import 'features/publishing/data/operations_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDir = await getApplicationSupportDirectory();
  await supportDir.create(recursive: true);
  final database = AppDatabase.open(
    p.join(supportDir.path, 'gitphoto_studio.db'),
  );
  // Une publication restée « en cours » a été interrompue par la fermeture
  // de l'application : son résultat réel est inconnu.
  OperationsRepository(database).markInterrupted();
  final tempDir = await getTemporaryDirectory();
  final libraryPaths = LibraryPaths(
    root: supportDir.path,
    temporaryDir: tempDir.path,
  )..ensureCreated();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        libraryPathsProvider.overrideWithValue(libraryPaths),
      ],
      child: const GitPhotoStudioApp(),
    ),
  );
}
