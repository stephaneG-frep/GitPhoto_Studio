/// Migrations du schéma SQLite.
///
/// Chaque migration porte le numéro de version qu'elle produit. Les migrations
/// sont appliquées dans l'ordre, dans une transaction, et la version courante
/// est mémorisée dans `PRAGMA user_version`.
///
/// Règle : ne jamais modifier une migration déjà livrée ; en ajouter une
/// nouvelle à la fin de [migrations].
library;

class Migration {
  const Migration(this.version, this.statements);

  final int version;
  final List<String> statements;
}

/// Aucune table ne contient de jeton GitHub ni de clé IA : ces secrets
/// relèvent exclusivement du stockage sécurisé de la plateforme.
const List<Migration> migrations = [
  Migration(1, [
    '''
    CREATE TABLE preferences (
      key   TEXT PRIMARY KEY NOT NULL,
      value TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE albums (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      name       TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE media (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      source_path TEXT NOT NULL,
      file_name   TEXT NOT NULL,
      mime_type   TEXT,
      size_bytes  INTEGER NOT NULL,
      sha256      TEXT,
      width       INTEGER,
      height      INTEGER,
      duration_ms INTEGER,
      taken_at    INTEGER,
      imported_at INTEGER NOT NULL,
      album_id    INTEGER REFERENCES albums(id) ON DELETE SET NULL
    )
    ''',
    'CREATE INDEX idx_media_sha256 ON media(sha256)',
    '''
    CREATE TABLE repositories (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      owner          TEXT NOT NULL,
      name           TEXT NOT NULL,
      default_branch TEXT,
      is_private     INTEGER NOT NULL DEFAULT 1,
      html_url       TEXT,
      is_active      INTEGER NOT NULL DEFAULT 0,
      added_at       INTEGER NOT NULL,
      UNIQUE(owner, name)
    )
    ''',
    '''
    CREATE TABLE operations (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      kind          TEXT NOT NULL,
      repository_id INTEGER REFERENCES repositories(id) ON DELETE SET NULL,
      branch        TEXT,
      commit_message TEXT,
      commit_sha    TEXT,
      status        TEXT NOT NULL,
      error_message TEXT,
      html_url      TEXT,
      created_at    INTEGER NOT NULL,
      finished_at   INTEGER
    )
    ''',
    '''
    CREATE TABLE operation_files (
      operation_id INTEGER NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
      media_id     INTEGER REFERENCES media(id) ON DELETE SET NULL,
      remote_path  TEXT NOT NULL,
      PRIMARY KEY (operation_id, remote_path)
    )
    ''',
    '''
    CREATE TABLE transfer_queue (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      idempotency_key TEXT NOT NULL UNIQUE,
      operation_id    INTEGER REFERENCES operations(id) ON DELETE CASCADE,
      media_id        INTEGER REFERENCES media(id) ON DELETE SET NULL,
      remote_path     TEXT NOT NULL,
      strategy        TEXT NOT NULL,
      status          TEXT NOT NULL,
      attempts        INTEGER NOT NULL DEFAULT 0,
      last_error      TEXT,
      created_at      INTEGER NOT NULL,
      updated_at      INTEGER NOT NULL
    )
    ''',
    'CREATE INDEX idx_transfer_status ON transfer_queue(status)',
    '''
    CREATE TABLE ai_conversations (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      provider_id TEXT NOT NULL,
      title       TEXT,
      created_at  INTEGER NOT NULL
    )
    ''',
    '''
    CREATE TABLE ai_messages (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      conversation_id INTEGER NOT NULL
                      REFERENCES ai_conversations(id) ON DELETE CASCADE,
      role            TEXT NOT NULL,
      content         TEXT NOT NULL,
      created_at      INTEGER NOT NULL
    )
    ''',
  ]),
  // Phase 2 : bibliothèque de médias (copies de travail et miniatures).
  Migration(2, [
    'ALTER TABLE media ADD COLUMN stored_path TEXT',
    'ALTER TABLE media ADD COLUMN thumbnail_path TEXT',
    'ALTER TABLE media ADD COLUMN thumbnail_bytes INTEGER NOT NULL DEFAULT 0',
    "ALTER TABLE media ADD COLUMN media_kind TEXT NOT NULL DEFAULT 'image'",
    'ALTER TABLE media ADD COLUMN camera_model TEXT',
    'ALTER TABLE media ADD COLUMN has_gps INTEGER NOT NULL DEFAULT 0',
    'DROP INDEX idx_media_sha256',
    'CREATE UNIQUE INDEX idx_media_sha256 ON media(sha256)',
  ]),
  // Phase 4 : versions optimisées, empreinte visuelle, albums.
  Migration(3, [
    // Version dérivée (optimisée, convertie…) d'un autre média.
    'ALTER TABLE media ADD COLUMN derived_from INTEGER REFERENCES media(id) ON DELETE SET NULL',
    // Empreinte visuelle (dHash 64 bits, hexadécimal) : doublons probables.
    'ALTER TABLE media ADD COLUMN phash TEXT',
    'CREATE INDEX idx_media_album ON media(album_id)',
    'CREATE UNIQUE INDEX idx_albums_name ON albums(name COLLATE NOCASE)',
  ]),
  // Phase 5 : file d'attente persistante et reprise.
  Migration(4, [
    'ALTER TABLE transfer_queue ADD COLUMN git_blob_sha TEXT',
    'ALTER TABLE transfer_queue ADD COLUMN size_bytes INTEGER',
    // add | overwrite : décision prise à l'analyse, revérifiée à la reprise.
    "ALTER TABLE transfer_queue ADD COLUMN action TEXT NOT NULL DEFAULT 'add'",
    // Empreinte du blob déjà envoyé à GitHub (reprise fichier par fichier).
    'ALTER TABLE transfer_queue ADD COLUMN uploaded_sha TEXT',
    'ALTER TABLE operations ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0',
    'CREATE INDEX idx_transfer_operation ON transfer_queue(operation_id)',
  ]),
  // Phase 6 : fichiers produits par l'application hors bibliothèque (README
  // rédigé par l'agent), publiés depuis leur chemin local.
  Migration(5, ['ALTER TABLE transfer_queue ADD COLUMN local_path TEXT']),
];

int get latestSchemaVersion => migrations.last.version;
