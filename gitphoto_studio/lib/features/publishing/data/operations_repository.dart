import '../../../core/database/app_database.dart';

enum OperationStatus {
  /// En file d'attente, pas encore commencée.
  queued,
  running,
  success,
  failed,

  /// Application fermée pendant l'exécution : résultat à revérifier.
  interrupted,
  cancelled,
}

/// Opérations qu'il est possible de relancer.
const resumableStatuses = {OperationStatus.failed, OperationStatus.interrupted};

/// État d'un fichier dans la file d'attente.
enum EntryStatus { pending, uploaded, done, skipped, failed, cancelled }

/// Fichier à publier, tel que décidé à l'analyse.
class QueueEntryInput {
  const QueueEntryInput({
    required this.mediaId,
    this.localPath,
    required this.remotePath,
    required this.strategy,
    required this.gitBlobSha,
    required this.sizeBytes,
    this.overwrite = false,
  });

  final int? mediaId;

  /// Fichier hors bibliothèque (quand [mediaId] est `null`).
  final String? localPath;
  final String remotePath;

  /// Nom d'une [PublishStrategy] (`githubApi`, `gitLfs`, `nativeGit`).
  final String strategy;
  final String gitBlobSha;
  final int sizeBytes;
  final bool overwrite;
}

class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.operationId,
    required this.remotePath,
    required this.strategy,
    required this.status,
    required this.overwrite,
    this.mediaId,
    this.localPath,
    this.gitBlobSha,
    this.sizeBytes,
    this.uploadedSha,
    this.lastError,
  });

  final int id;
  final int operationId;
  final int? mediaId;
  final String? localPath;
  final String remotePath;
  final String strategy;
  final EntryStatus status;
  final bool overwrite;
  final String? gitBlobSha;
  final int? sizeBytes;
  final String? uploadedSha;
  final String? lastError;
}

class OperationFile {
  const OperationFile(this.remotePath, {this.mediaId});

  final String remotePath;
  final int? mediaId;
}

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.files,
    this.repository,
    this.branch,
    this.commitMessage,
    this.commitSha,
    this.htmlUrl,
    this.error,
    this.finishedAt,
    this.attempts = 0,
    this.entries = const [],
  });

  final int id;
  final String kind;
  final OperationStatus status;
  final DateTime createdAt;
  final List<OperationFile> files;

  /// `owner/nom`.
  final String? repository;
  final String? branch;
  final String? commitMessage;
  final String? commitSha;
  final String? htmlUrl;
  final String? error;
  final DateTime? finishedAt;
  final int attempts;

  /// Fichiers de la file d'attente (opérations créées depuis la phase 5).
  final List<QueueEntry> entries;

  bool get isResumable => resumableStatuses.contains(status);
  bool get isActive =>
      status == OperationStatus.queued || status == OperationStatus.running;
}

/// Historique des opérations et dépôts connus (SQLite).
class OperationsRepository {
  OperationsRepository(this._db);

  final AppDatabase _db;

  /// Enregistre (ou met à jour) un dépôt et renvoie son identifiant local.
  int upsertRepository({
    required String owner,
    required String name,
    String? defaultBranch,
    bool isPrivate = true,
    String? htmlUrl,
  }) {
    _db.raw.execute(
      'INSERT INTO repositories(owner, name, default_branch, is_private, '
      'html_url, added_at) VALUES(?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(owner, name) DO UPDATE SET '
      'default_branch = COALESCE(excluded.default_branch, default_branch), '
      'is_private = excluded.is_private, '
      'html_url = COALESCE(excluded.html_url, html_url)',
      [
        owner,
        name,
        defaultBranch,
        isPrivate ? 1 : 0,
        htmlUrl,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
    return _db.raw.select(
          'SELECT id FROM repositories WHERE owner = ? AND name = ?',
          [owner, name],
        ).first['id']!
        as int;
  }

  void setActiveRepository(int id) {
    _db.raw.execute('UPDATE repositories SET is_active = (id = ?)', [id]);
  }

  ({String owner, String name, String? defaultBranch})? activeRepository() {
    final rows = _db.raw.select(
      'SELECT owner, name, default_branch FROM repositories '
      'WHERE is_active = 1 LIMIT 1',
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return (
      owner: r['owner']! as String,
      name: r['name']! as String,
      defaultBranch: r['default_branch'] as String?,
    );
  }

  int start({
    required String kind,
    required int repositoryId,
    required String branch,
    required String commitMessage,
    required List<OperationFile> files,
  }) {
    _db.raw.execute('BEGIN');
    try {
      _db.raw.execute(
        'INSERT INTO operations(kind, repository_id, branch, commit_message, '
        'status, created_at) VALUES(?, ?, ?, ?, ?, ?)',
        [
          kind,
          repositoryId,
          branch,
          commitMessage,
          OperationStatus.running.name,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
      final id = _db.raw.lastInsertRowId;
      for (final f in files) {
        _db.raw.execute(
          'INSERT INTO operation_files(operation_id, media_id, remote_path) '
          'VALUES(?, ?, ?)',
          [id, f.mediaId, f.remotePath],
        );
      }
      _db.raw.execute('COMMIT');
      return id;
    } catch (_) {
      _db.raw.execute('ROLLBACK');
      rethrow;
    }
  }

  void finish(
    int id, {
    required OperationStatus status,
    String? commitSha,
    String? htmlUrl,
    String? error,
  }) {
    _db.raw.execute(
      'UPDATE operations SET status = ?, commit_sha = ?, html_url = ?, '
      'error_message = ?, finished_at = ? WHERE id = ?',
      [
        status.name,
        commitSha,
        htmlUrl,
        error,
        DateTime.now().millisecondsSinceEpoch,
        id,
      ],
    );
  }

  /// Au démarrage : une opération restée « en cours » a été interrompue
  /// (application fermée, plantage). Son résultat réel est inconnu.
  int markInterrupted() {
    _db.raw.execute(
      'UPDATE operations SET status = ?, finished_at = ? WHERE status = ?',
      [
        OperationStatus.interrupted.name,
        DateTime.now().millisecondsSinceEpoch,
        OperationStatus.running.name,
      ],
    );
    return _db.raw.updatedRows;
  }

  List<OperationRecord> list({int limit = 200}) {
    final rows = _db.raw.select(
      'SELECT o.*, r.owner, r.name FROM operations o '
      'LEFT JOIN repositories r ON r.id = o.repository_id '
      'ORDER BY o.created_at DESC, o.id DESC LIMIT ?',
      [limit],
    );
    return [
      for (final r in rows)
        OperationRecord(
          id: r['id']! as int,
          kind: r['kind']! as String,
          status:
              OperationStatus.values.asNameMap()[r['status']] ??
              OperationStatus.failed,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            r['created_at']! as int,
          ),
          finishedAt: r['finished_at'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(r['finished_at']! as int),
          repository: r['owner'] == null ? null : '${r['owner']}/${r['name']}',
          branch: r['branch'] as String?,
          commitMessage: r['commit_message'] as String?,
          commitSha: r['commit_sha'] as String?,
          htmlUrl: r['html_url'] as String?,
          error: r['error_message'] as String?,
          files: _files(r['id']! as int),
          attempts: r['attempts'] as int? ?? 0,
          entries: entries(r['id']! as int),
        ),
    ];
  }

  OperationRecord? find(int id) {
    for (final op in list(limit: 1000)) {
      if (op.id == id) return op;
    }
    return null;
  }

  // --- File d'attente ------------------------------------------------------

  /// Met une publication en file d'attente : une opération (un commit) et un
  /// enregistrement par fichier, dans une seule transaction.
  int enqueue({
    required int repositoryId,
    required String branch,
    required String commitMessage,
    required List<QueueEntryInput> entries,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.raw.execute('BEGIN');
    try {
      _db.raw.execute(
        'INSERT INTO operations(kind, repository_id, branch, commit_message, '
        'status, created_at) VALUES(?, ?, ?, ?, ?, ?)',
        [
          'publish',
          repositoryId,
          branch,
          commitMessage,
          OperationStatus.queued.name,
          now,
        ],
      );
      final id = _db.raw.lastInsertRowId;
      for (final e in entries) {
        _db.raw.execute(
          'INSERT INTO operation_files(operation_id, media_id, remote_path) '
          'VALUES(?, ?, ?)',
          [id, e.mediaId, e.remotePath],
        );
        _db.raw.execute(
          'INSERT INTO transfer_queue(idempotency_key, operation_id, media_id, '
          'remote_path, strategy, status, git_blob_sha, size_bytes, action, '
          'local_path, created_at, updated_at) '
          'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            '$id:${e.remotePath}',
            id,
            e.mediaId,
            e.remotePath,
            e.strategy,
            EntryStatus.pending.name,
            e.gitBlobSha,
            e.sizeBytes,
            e.overwrite ? 'overwrite' : 'add',
            e.mediaId == null ? e.localPath : null,
            now,
            now,
          ],
        );
      }
      _db.raw.execute('COMMIT');
      return id;
    } catch (_) {
      _db.raw.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Vrai si le même contenu est déjà en attente ou en cours d'envoi vers le
  /// même chemin du même dépôt et de la même branche (double publication).
  bool hasActiveDuplicate({
    required int repositoryId,
    required String branch,
    required String remotePath,
    required String gitBlobSha,
  }) {
    final rows = _db.raw.select(
      'SELECT 1 FROM transfer_queue q JOIN operations o ON o.id = q.operation_id '
      'WHERE o.repository_id = ? AND o.branch = ? AND q.remote_path = ? '
      'AND q.git_blob_sha = ? AND o.status IN (?, ?) LIMIT 1',
      [
        repositoryId,
        branch,
        remotePath,
        gitBlobSha,
        OperationStatus.queued.name,
        OperationStatus.running.name,
      ],
    );
    return rows.isNotEmpty;
  }

  /// Plus ancienne opération en attente.
  int? nextQueued() {
    final rows = _db.raw.select(
      'SELECT id FROM operations WHERE status = ? ORDER BY created_at, id '
      'LIMIT 1',
      [OperationStatus.queued.name],
    );
    return rows.isEmpty ? null : rows.first['id']! as int;
  }

  List<QueueEntry> entries(int operationId) => [
    for (final r in _db.raw.select(
      'SELECT * FROM transfer_queue WHERE operation_id = ? ORDER BY id',
      [operationId],
    ))
      QueueEntry(
        id: r['id']! as int,
        operationId: operationId,
        mediaId: r['media_id'] as int?,
        localPath: r['local_path'] as String?,
        remotePath: r['remote_path']! as String,
        strategy: r['strategy']! as String,
        status:
            EntryStatus.values.asNameMap()[r['status']] ?? EntryStatus.pending,
        overwrite: r['action'] == 'overwrite',
        gitBlobSha: r['git_blob_sha'] as String?,
        sizeBytes: r['size_bytes'] as int?,
        uploadedSha: r['uploaded_sha'] as String?,
        lastError: r['last_error'] as String?,
      ),
  ];

  void setEntry(
    int entryId,
    EntryStatus status, {
    String? uploadedSha,
    String? error,
  }) {
    _db.raw.execute(
      'UPDATE transfer_queue SET status = ?, '
      'uploaded_sha = COALESCE(?, uploaded_sha), last_error = ?, '
      'attempts = attempts + (CASE WHEN ? = \'failed\' THEN 1 ELSE 0 END), '
      'updated_at = ? WHERE id = ?',
      [
        status.name,
        uploadedSha,
        error,
        status.name,
        DateTime.now().millisecondsSinceEpoch,
        entryId,
      ],
    );
  }

  void setStatus(int operationId, OperationStatus status) {
    _db.raw.execute(
      'UPDATE operations SET status = ?, '
      'attempts = attempts + (CASE WHEN ? = \'running\' THEN 1 ELSE 0 END) '
      'WHERE id = ?',
      [status.name, status.name, operationId],
    );
  }

  /// Remet en file une opération échouée ou interrompue. Les fichiers déjà
  /// publiés seront reconnus à la reprise (comparaison avec GitHub).
  bool requeue(int operationId) {
    final placeholders = List.filled(resumableStatuses.length, '?').join(', ');
    _db.raw.execute(
      'UPDATE operations SET status = ?, error_message = NULL, '
      'finished_at = NULL WHERE id = ? AND status IN ($placeholders)',
      [
        OperationStatus.queued.name,
        operationId,
        for (final s in resumableStatuses) s.name,
      ],
    );
    final changed = _db.raw.updatedRows > 0;
    if (changed) {
      _db.raw.execute(
        'UPDATE transfer_queue SET status = ? WHERE operation_id = ? '
        'AND status IN (?, ?)',
        [
          EntryStatus.pending.name,
          operationId,
          EntryStatus.failed.name,
          EntryStatus.cancelled.name,
        ],
      );
    }
    return changed;
  }

  /// Annule une opération qui n'a pas abouti. Une opération en cours est
  /// annulée par l'exécuteur, entre deux fichiers.
  bool cancel(int operationId) {
    _db.raw.execute(
      'UPDATE operations SET status = ?, finished_at = ? '
      'WHERE id = ? AND status IN (?, ?, ?)',
      [
        OperationStatus.cancelled.name,
        DateTime.now().millisecondsSinceEpoch,
        operationId,
        OperationStatus.queued.name,
        OperationStatus.failed.name,
        OperationStatus.interrupted.name,
      ],
    );
    final changed = _db.raw.updatedRows > 0;
    if (changed) {
      _db.raw.execute(
        'UPDATE transfer_queue SET status = ? WHERE operation_id = ? '
        'AND status IN (?, ?, ?)',
        [
          EntryStatus.cancelled.name,
          operationId,
          EntryStatus.pending.name,
          EntryStatus.uploaded.name,
          EntryStatus.failed.name,
        ],
      );
    }
    return changed;
  }

  List<OperationFile> _files(int operationId) => [
    for (final f in _db.raw.select(
      'SELECT remote_path, media_id FROM operation_files '
      'WHERE operation_id = ? ORDER BY remote_path',
      [operationId],
    ))
      OperationFile(
        f['remote_path']! as String,
        mediaId: f['media_id'] as int?,
      ),
  ];
}
