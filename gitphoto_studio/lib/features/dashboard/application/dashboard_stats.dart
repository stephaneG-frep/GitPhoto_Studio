import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../gallery/data/media_repository.dart';

/// Fichiers de la file pas encore publiés (en attente ou envoyés sans que
/// le commit soit finalisé).
const pendingTransferStatuses = ['pending', 'uploaded'];

class DashboardStats {
  const DashboardStats({
    required this.mediaCount,
    required this.pendingCount,
    required this.localBytes,
    this.activeRepository,
  });

  final int mediaCount;
  final int pendingCount;

  /// Base SQLite + copies de travail + miniatures.
  final int localBytes;

  /// `owner/nom` du dépôt actif, `null` si aucun.
  final String? activeRepository;

  static DashboardStats read(AppDatabase db) {
    final placeholders = List.filled(
      pendingTransferStatuses.length,
      '?',
    ).join(', ');
    final active = db.raw.select(
      'SELECT owner, name FROM repositories WHERE is_active = 1 LIMIT 1',
    );
    return DashboardStats(
      mediaCount: db.count('media'),
      pendingCount: db.count(
        'transfer_queue',
        where: 'status IN ($placeholders)',
        args: pendingTransferStatuses,
      ),
      localBytes: db.fileSizeBytes() + MediaRepository(db).librarySizeBytes(),
      activeRepository: active.isEmpty
          ? null
          : '${active.first['owner']}/${active.first['name']}',
    );
  }
}

final dashboardStatsProvider = Provider<DashboardStats>(
  (ref) => DashboardStats.read(ref.watch(appDatabaseProvider)),
);
