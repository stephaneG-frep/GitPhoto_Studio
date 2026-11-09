import '../../../core/database/app_database.dart';

/// Ligne enregistrée d'une conversation (uniquement si l'utilisateur l'a
/// autorisé dans les paramètres). Ne contient jamais de clé ni de jeton.
class StoredChatLine {
  const StoredChatLine(this.role, this.content);

  /// `user`, `assistant`, `plan` (résumé et statut) ou `error`.
  final String role;
  final String content;
}

class ConversationRepository {
  ConversationRepository(this._db);

  final AppDatabase _db;

  int create(String providerId) {
    _db.raw.execute(
      'INSERT INTO ai_conversations(provider_id, created_at) VALUES(?, ?)',
      [providerId, DateTime.now().millisecondsSinceEpoch],
    );
    return _db.raw.lastInsertRowId;
  }

  void append(int conversationId, StoredChatLine line) {
    _db.raw.execute(
      'INSERT INTO ai_messages(conversation_id, role, content, created_at) '
      'VALUES(?, ?, ?, ?)',
      [
        conversationId,
        line.role,
        line.content,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  /// Dernière conversation enregistrée, s'il y en a une.
  ({int id, List<StoredChatLine> lines})? latest() {
    final rows = _db.raw.select(
      'SELECT id FROM ai_conversations ORDER BY created_at DESC, id DESC '
      'LIMIT 1',
    );
    if (rows.isEmpty) return null;
    final id = rows.first['id']! as int;
    return (
      id: id,
      lines: [
        for (final r in _db.raw.select(
          'SELECT role, content FROM ai_messages WHERE conversation_id = ? '
          'ORDER BY id',
          [id],
        ))
          StoredChatLine(r['role']! as String, r['content']! as String),
      ],
    );
  }

  int count() =>
      _db.raw.select('SELECT COUNT(*) AS n FROM ai_conversations').first['n']!
          as int;

  /// Efface toutes les conversations (messages compris, par cascade).
  void deleteAll() => _db.raw.execute('DELETE FROM ai_conversations');
}
