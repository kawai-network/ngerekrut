import '../../flutter_chat_core/src/models/message.dart';
import '../../flutter_chat_core/src/utils/typedefs.dart';
import '../database/chat_database_service.dart';
import '../mappers/message_mapper.dart';

/// Repository for managing [Message] persistence operations.
/// 
/// Provides CRUD operations and query methods for messages stored in DuckDB.
class MessageRepository {
  final ChatDatabaseService _database;
  final MessageMapper _mapper;

  /// Creates a [MessageRepository] instance.
  MessageRepository(this._database) : _mapper = MessageMapper();

  /// Inserts a new message into the database.
  Future<void> insertMessage(Message message) async {
    final row = _mapper.toRow(message);

    await _database.runTransaction(() async {
      // Insert message row
      await _database.executeVoid('''
        INSERT INTO messages (
          id, type, author_id, reply_to_message_id,
          created_at, deleted_at, failed_at, sent_at,
          delivered_at, seen_at, updated_at,
          pinned, status, text_content, media_source,
          media_metadata, custom_metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        row['id'],
        row['type'],
        row['author_id'],
        row['reply_to_message_id'],
        row['created_at'],
        row['deleted_at'],
        row['failed_at'],
        row['sent_at'],
        row['delivered_at'],
        row['seen_at'],
        row['updated_at'],
        row['pinned'],
        row['status'],
        row['text_content'],
        row['media_source'],
        row['media_metadata'],
        row['custom_metadata'],
      ]);

      // Insert reactions if present
      if (message.reactions != null && message.reactions!.isNotEmpty) {
        await _insertReactions(message.id, message.reactions!);
      }
    });
  }

  /// Updates an existing message in the database.
  Future<void> updateMessage(Message message) async {
    final row = _mapper.toRow(message);

    await _database.runTransaction(() async {
      // Update message row
      await _database.executeVoid('''
        UPDATE messages SET
          type = ?,
          author_id = ?,
          reply_to_message_id = ?,
          created_at = ?,
          deleted_at = ?,
          failed_at = ?,
          sent_at = ?,
          delivered_at = ?,
          seen_at = ?,
          updated_at = ?,
          pinned = ?,
          status = ?,
          text_content = ?,
          media_source = ?,
          media_metadata = ?,
          custom_metadata = ?
        WHERE id = ?
      ''', [
        row['type'],
        row['author_id'],
        row['reply_to_message_id'],
        row['created_at'],
        row['deleted_at'],
        row['failed_at'],
        row['sent_at'],
        row['delivered_at'],
        row['seen_at'],
        row['updated_at'],
        row['pinned'],
        row['status'],
        row['text_content'],
        row['media_source'],
        row['media_metadata'],
        row['custom_metadata'],
        row['id'],
      ]);

      // Update reactions
      await _updateReactions(message.id, message.reactions);
    });
  }

  /// Upserts a message (insert or update) atomically.
  ///
  /// Uses INSERT ... ON CONFLICT to avoid race conditions with concurrent writers.
  /// Both the message and its reactions are updated in a single transaction.
  Future<void> upsertMessage(Message message) async {
    final row = _mapper.toRow(message);

    await _database.runTransaction(() async {
      // Atomic upsert: INSERT or UPDATE on conflict
      await _database.executeVoid('''
        INSERT INTO messages (
          id, type, author_id, reply_to_message_id,
          created_at, deleted_at, failed_at, sent_at,
          delivered_at, seen_at, updated_at,
          pinned, status, text_content, media_source,
          media_metadata, custom_metadata
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT (id) DO UPDATE SET
          type = excluded.type,
          author_id = excluded.author_id,
          reply_to_message_id = excluded.reply_to_message_id,
          created_at = excluded.created_at,
          deleted_at = excluded.deleted_at,
          failed_at = excluded.failed_at,
          sent_at = excluded.sent_at,
          delivered_at = excluded.delivered_at,
          seen_at = excluded.seen_at,
          updated_at = excluded.updated_at,
          pinned = excluded.pinned,
          status = excluded.status,
          text_content = excluded.text_content,
          media_source = excluded.media_source,
          media_metadata = excluded.media_metadata,
          custom_metadata = excluded.custom_metadata
      ''', [
        row['id'],
        row['type'],
        row['author_id'],
        row['reply_to_message_id'],
        row['created_at'],
        row['deleted_at'],
        row['failed_at'],
        row['sent_at'],
        row['delivered_at'],
        row['seen_at'],
        row['updated_at'],
        row['pinned'],
        row['status'],
        row['text_content'],
        row['media_source'],
        row['media_metadata'],
        row['custom_metadata'],
      ]);

      // Update reactions in the same transaction
      await _updateReactions(message.id, message.reactions);
    });
  }

  /// Deletes a message by ID.
  Future<void> deleteMessage(MessageID id) async {
    await _database.runTransaction(() async {
      await _database.executeVoid(
        'DELETE FROM reactions WHERE message_id = ?',
        [id],
      );
      await _database.executeVoid('DELETE FROM messages WHERE id = ?', [id]);
    });
  }

  /// Soft deletes a message by setting deleted_at timestamp.
  Future<void> softDeleteMessage(MessageID id) async {
    await _database.executeVoid('''
      UPDATE messages SET deleted_at = ? WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, id]);
  }

  /// Gets a message by ID.
  Future<Message?> getMessageById(MessageID id) async {
    final result = await _database.execute('''
      SELECT * FROM messages WHERE id = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final message = _mapper.fromRow(result.first);
    final reactions = await _getReactions(id);
    
    return _withReactions(message, reactions);
  }

  /// Gets all messages (excluding deleted) ordered by creation date.
  Future<List<Message>> getAllMessages({
    int limit = 50,
    bool includeDeleted = false,
  }) async {
    final conditions = <String>[];
    if (!includeDeleted) {
      conditions.add('deleted_at IS NULL');
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await _database.execute('''
      SELECT * FROM messages
      $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Gets messages by author ID.
  Future<List<Message>> getMessagesByAuthor(
    UserID authorId, {
    int limit = 50,
    DateTime? before,
    bool includeDeleted = false,
  }) async {
    final conditions = <String>['author_id = ?'];
    final params = <dynamic>[authorId];

    if (!includeDeleted) {
      conditions.add('deleted_at IS NULL');
    }

    if (before != null) {
      conditions.add('created_at < ?');
      params.add(before.millisecondsSinceEpoch);
    }

    final whereClause = conditions.join(' AND ');

    final result = await _database.execute('''
      SELECT * FROM messages
      WHERE $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [...params, limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Gets messages by status.
  Future<List<Message>> getMessagesByStatus(
    MessageStatus status, {
    int limit = 50,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM messages
      WHERE status = ? AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT ?
    ''', [status.name, limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Gets messages in a date range.
  Future<List<Message>> getMessagesInRange({
    DateTime? after,
    DateTime? before,
    int limit = 50,
    bool includeDeleted = false,
  }) async {
    final conditions = <String>[];
    final params = <dynamic>[];

    if (!includeDeleted) {
      conditions.add('deleted_at IS NULL');
    }

    if (after != null) {
      conditions.add('created_at >= ?');
      params.add(after.millisecondsSinceEpoch);
    }

    if (before != null) {
      conditions.add('created_at <= ?');
      params.add(before.millisecondsSinceEpoch);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await _database.execute('''
      SELECT * FROM messages
      $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [...params, limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Searches messages by text content.
  Future<List<Message>> searchMessages(
    String query, {
    int limit = 50,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM messages
      WHERE text_content LIKE ?
        AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT ?
    ''', ['%$query%', limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Gets pinned messages.
  Future<List<Message>> getPinnedMessages({
    int limit = 50,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM messages
      WHERE pinned = TRUE AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT ?
    ''', [limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Gets messages by type.
  Future<List<Message>> getMessagesByType(
    String type, {
    int limit = 50,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM messages
      WHERE type = ? AND deleted_at IS NULL
      ORDER BY created_at DESC
      LIMIT ?
    ''', [type, limit]);

    return _loadMessagesWithReactions(result);
  }

  /// Adds a reaction to a message.
  Future<void> addReaction(
    MessageID messageId,
    UserID userId,
    String reactionKey,
  ) async {
    await _database.executeVoid('''
      INSERT INTO reactions (message_id, reaction_key, user_id)
      VALUES (?, ?, ?)
      ON CONFLICT DO NOTHING
    ''', [messageId, reactionKey, userId]);
  }

  /// Removes a reaction from a message.
  Future<void> removeReaction(
    MessageID messageId,
    UserID userId,
    String reactionKey,
  ) async {
    await _database.executeVoid('''
      DELETE FROM reactions
      WHERE message_id = ? AND user_id = ? AND reaction_key = ?
    ''', [messageId, userId, reactionKey]);
  }

  /// Clears all reactions from a message.
  Future<void> clearReactions(MessageID messageId) async {
    await _database.executeVoid('DELETE FROM reactions WHERE message_id = ?', [
      messageId,
    ]);
  }

  /// Gets message count statistics.
  Future<Map<String, int>> getMessageStats({
    DateTime? since,
  }) async {
    final conditions = <String>['deleted_at IS NULL'];
    final params = <dynamic>[];

    if (since != null) {
      conditions.add('created_at >= ?');
      params.add(since.millisecondsSinceEpoch);
    }

    final whereClause = conditions.join(' AND ');

    final result = await _database.execute('''
      SELECT type, COUNT(*) as count
      FROM messages
      WHERE $whereClause
      GROUP BY type
    ''', params);

    return {
      for (final row in result) row['type'] as String: row['count'] as int,
    };
  }

  /// Gets total message count.
  Future<int> getMessageCount({
    bool includeDeleted = false,
  }) async {
    final conditions = <String>[];
    if (!includeDeleted) {
      conditions.add('deleted_at IS NULL');
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await _database.execute('''
      SELECT COUNT(*) as count FROM messages $whereClause
    ''');

    return result.first['count'] as int;
  }

  /// Inserts reactions for a message.
  Future<void> _insertReactions(
    MessageID messageId,
    Map<String, List<UserID>> reactions,
  ) async {
    if (reactions.isEmpty) return;
    final values = <String>[];
    final params = <dynamic>[];
    for (final entry in reactions.entries) {
      for (final userId in entry.value) {
        values.add('(?, ?, ?)');
        params.addAll([messageId, entry.key, userId]);
      }
    }
    if (values.isEmpty) return;
    await _database.executeVoid('''
      INSERT INTO reactions (message_id, reaction_key, user_id)
      VALUES ${values.join(',')}
      ON CONFLICT DO NOTHING
    ''', params);
  }

  /// Inserts multiple messages atomically in a single transaction.
  Future<void> insertMessages(List<Message> messages) async {
    await _database.runTransaction(() async {
      for (final message in messages) {
        final row = _mapper.toRow(message);
        await _database.executeVoid('''
          INSERT INTO messages (
            id, type, author_id, reply_to_message_id,
            created_at, deleted_at, failed_at, sent_at,
            delivered_at, seen_at, updated_at,
            pinned, status, text_content, media_source,
            media_metadata, custom_metadata
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', [
          row['id'],
          row['type'],
          row['author_id'],
          row['reply_to_message_id'],
          row['created_at'],
          row['deleted_at'],
          row['failed_at'],
          row['sent_at'],
          row['delivered_at'],
          row['seen_at'],
          row['updated_at'],
          row['pinned'],
          row['status'],
          row['text_content'],
          row['media_source'],
          row['media_metadata'],
          row['custom_metadata'],
        ]);

        // Insert reactions if present
        if (message.reactions != null && message.reactions!.isNotEmpty) {
          await _insertReactions(message.id, message.reactions!);
        }
      }
    });
  }

  /// Updates reactions for a message.
  Future<void> _updateReactions(
    MessageID messageId,
    Map<String, List<UserID>>? reactions,
  ) async {
    // Delete existing reactions
    await _database.executeVoid(
      'DELETE FROM reactions WHERE message_id = ?',
      [messageId],
    );

    // Insert new reactions
    if (reactions != null && reactions.isNotEmpty) {
      await _insertReactions(messageId, reactions);
    }
  }

  /// Gets reactions for a message.
  Future<Map<String, List<UserID>>> _getReactions(MessageID messageId) async {
    final result = await _database.execute('''
      SELECT reaction_key, user_id FROM reactions
      WHERE message_id = ?
      ORDER BY id
    ''', [messageId]);

    final reactions = <String, List<UserID>>{};
    for (final row in result) {
      final key = row['reaction_key'] as String;
      final userId = row['user_id'] as String;

      reactions.putIfAbsent(key, () => []).add(userId);
    }

    return reactions;
  }

  /// Loads messages with their reactions.
  Future<List<Message>> _loadMessagesWithReactions(
    List<Map<String, dynamic>> result,
  ) async {
    if (result.isEmpty) return [];
    
    final messages = result.map(_mapper.fromRow).toList();
    final messageIds = messages.map((m) => m.id).toList();

    // Load all reactions for these messages
    final reactionsResult = await _database.execute('''
      SELECT message_id, reaction_key, user_id FROM reactions
      WHERE message_id IN (${List.filled(messageIds.length, '?').join(',')})
      ORDER BY id
    ''', messageIds);

    // Group reactions by message
    final reactionsByMessage = <String, Map<String, List<UserID>>>{};
    for (final row in reactionsResult) {
      final messageId = row['message_id'] as String;
      final reactionKey = row['reaction_key'] as String;
      final userId = row['user_id'] as String;

      reactionsByMessage.putIfAbsent(messageId, () => {});
      reactionsByMessage[messageId]!
          .putIfAbsent(reactionKey, () => [])
          .add(userId);
    }

    // Apply reactions to messages
    return messages
        .map((m) => _withReactions(m, reactionsByMessage[m.id] ?? {}))
        .toList();
  }

  /// Creates a copy of a message with updated reactions.
  Message _withReactions(Message message, Map<String, List<UserID>> reactions) {
    return message.copyWith(reactions: reactions.isEmpty ? null : reactions);
  }
}
