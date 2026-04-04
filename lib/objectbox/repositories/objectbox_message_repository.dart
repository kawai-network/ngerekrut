import 'dart:convert';
import 'dart:math' as math;

import 'package:objectbox/objectbox.dart';

import '../../../flutter_chat_core/src/models/message.dart';
import '../../../flutter_chat_core/src/models/link_preview_data.dart';
import '../../../flutter_chat_core/src/utils/typedefs.dart';
import '../../../objectbox.g.dart';
import '../entities/message_entity.dart';
import '../entities/reaction_entity.dart';
import '../entities/objectbox_store_provider.dart';

/// Repository for managing [Message] persistence operations using ObjectBox.
class ObjectBoxMessageRepository {
  ObjectBoxMessageRepository();

  Box<MessageEntity> get _messageBox => ObjectBoxStoreProvider.messageBox;
  Box<ReactionEntity> get _reactionBox => ObjectBoxStoreProvider.reactionBox;

  Future<void> insertMessage(Message message) async {
    _insertMessageSync(message);
  }

  Future<void> updateMessage(Message message) async {
    final entity = _toEntity(message);
    final existing = _getByMessageId(message.id.toString());
    if (existing == null) return;
    entity.id = existing.id;
    // Preserve embedding if not being updated
    if (entity.embedding == null && existing.embedding != null) {
      entity.embedding = existing.embedding;
    }
    _messageBox.put(entity);
    await _updateReactions(message.id, message.reactions);
  }

  Future<void> upsertMessage(Message message) async {
    final entity = _toEntity(message);
    final existing = _getByMessageId(message.id.toString());
    if (existing != null) {
      entity.id = existing.id;
      // Preserve embedding if not being updated
      if (entity.embedding == null && existing.embedding != null) {
        entity.embedding = existing.embedding;
      }
    }
    _messageBox.put(entity);
    await _updateReactions(message.id, message.reactions);
  }

  Future<void> deleteMessage(MessageID id) async {
    final existing = _getByMessageId(id.toString());
    if (existing != null) {
      // Delete reactions
      final reactions = _reactionBox.getAll().where((r) => r.messageId == id.toString()).toList();
      if (reactions.isNotEmpty) {
        _reactionBox.removeMany(reactions.map((r) => r.id).toList());
      }
      _messageBox.remove(existing.id);
    }
  }

  Future<void> softDeleteMessage(MessageID id) async {
    final existing = _getByMessageId(id.toString());
    if (existing != null) {
      existing.deletedAt = DateTime.now().millisecondsSinceEpoch;
      _messageBox.put(existing);
    }
  }

  Future<Message?> getMessageById(MessageID id) async {
    final entity = _getByMessageId(id.toString());
    if (entity == null) return null;
    final message = _toModel(entity);
    final reactions = await _getReactions(id);
    return _withReactions(message, reactions);
  }

  Future<List<Message>> getAllMessages({int limit = 50, bool includeDeleted = false}) async {
    var all = _messageBox.getAll();
    if (!includeDeleted) {
      all = all.where((m) => m.deletedAt == null || m.deletedAt! <= 0).toList();
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> getMessagesByAuthor(
    UserID authorId, {
    int limit = 50,
    DateTime? before,
    bool includeDeleted = false,
  }) async {
    var all = _messageBox.getAll().where((m) => m.authorId == authorId.toString()).toList();
    if (!includeDeleted) {
      all = all.where((m) => m.deletedAt == null || m.deletedAt! <= 0).toList();
    }
    if (before != null) {
      all = all.where((m) => m.createdAt < before.millisecondsSinceEpoch).toList();
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> getMessagesByStatus(MessageStatus status, {int limit = 50}) async {
    var all = _messageBox.getAll()
        .where((m) => m.status == status.name)
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> getMessagesInRange({
    DateTime? after,
    DateTime? before,
    int limit = 50,
    bool includeDeleted = false,
  }) async {
    var all = _messageBox.getAll();
    if (!includeDeleted) {
      all = all.where((m) => m.deletedAt == null || m.deletedAt! <= 0).toList();
    }
    if (after != null) {
      all = all.where((m) => m.createdAt >= after.millisecondsSinceEpoch).toList();
    }
    if (before != null) {
      all = all.where((m) => m.createdAt < before.millisecondsSinceEpoch).toList();
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> searchMessages(String query, {int limit = 50}) async {
    final all = _messageBox.getAll()
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .where((m) => (m.textContent ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> getPinnedMessages({int limit = 50}) async {
    final all = _messageBox.getAll()
        .where((m) => m.pinned)
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<List<Message>> getMessagesByType(String type, {int limit = 50}) async {
    final all = _messageBox.getAll()
        .where((m) => m.type == type)
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  Future<void> addReaction(MessageID messageId, UserID userId, String reactionKey) async {
    _putReactionIfAbsent(
      messageId: messageId.toString(),
      userId: userId.toString(),
      reactionKey: reactionKey,
    );
  }

  Future<void> removeReaction(MessageID messageId, UserID userId, String reactionKey) async {
    final all = _reactionBox.getAll();
    final toRemove = all
        .where((r) =>
            r.messageId == messageId.toString() &&
            r.userId == userId.toString() &&
            r.reactionKey == reactionKey)
        .toList();
    if (toRemove.isNotEmpty) {
      _reactionBox.removeMany(toRemove.map((r) => r.id).toList());
    }
  }

  Future<void> clearReactions(MessageID messageId) async {
    final all = _reactionBox.getAll();
    final toRemove = all.where((r) => r.messageId == messageId.toString()).toList();
    if (toRemove.isNotEmpty) {
      _reactionBox.removeMany(toRemove.map((r) => r.id).toList());
    }
  }

  Future<Map<String, int>> getMessageStats({DateTime? since}) async {
    var all = _messageBox.getAll().where((m) => m.deletedAt == null || m.deletedAt! <= 0);
    if (since != null) {
      all = all.where((m) => m.createdAt >= since.millisecondsSinceEpoch);
    }
    final stats = <String, int>{};
    for (final entity in all) {
      stats[entity.type] = (stats[entity.type] ?? 0) + 1;
    }
    return stats;
  }

  Future<int> getMessageCount({bool includeDeleted = false}) async {
    var all = _messageBox.getAll();
    if (!includeDeleted) {
      all = all.where((m) => m.deletedAt == null || m.deletedAt! <= 0).toList();
    }
    return all.length;
  }

  Future<void> deleteAllMessages() async {
    final store = ObjectBoxStoreProvider.store;
    store.runInTransaction(TxMode.write, () {
      _reactionBox.removeAll();
      _messageBox.removeAll();
    });
  }

  Future<void> insertMessages(List<Message> messages) async {
    if (messages.isEmpty) return;
    final store = ObjectBoxStoreProvider.store;
    store.runInTransaction(TxMode.write, () {
      for (final message in messages) {
        _insertMessageSync(message);
      }
    });
  }

  /// Vector search - finds messages by embedding similarity.
  Future<List<(Message, double)>> searchByVector(
    List<double> queryVector, {
    int limit = 20,
    double? minSimilarity,
  }) async {
    if (queryVector.isEmpty) return [];

    // Simple cosine similarity search (brute force for now)
    final all = _messageBox.getAll()
        .where((m) => m.embedding != null && m.embedding!.isNotEmpty)
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .toList();

    final results = <(Message, double)>[];
    for (final entity in all) {
      final similarity = _cosineSimilarity(queryVector, entity.embedding!);
      if (minSimilarity != null && similarity < minSimilarity) continue;
      final message = _toModel(entity);
      final reactions = await _getReactions(message.id);
      results.add((_withReactions(message, reactions), similarity));
    }

    results.sort((a, b) => b.$2.compareTo(a.$2));
    return results.take(limit).toList();
  }

  Future<List<Message>> getSimilarMessages(MessageID messageId, {int limit = 10}) async {
    final entity = _getByMessageId(messageId.toString());
    if (entity?.embedding == null) return [];
    final results = await searchByVector(entity!.embedding!, limit: limit + 1);
    return results.where((r) => r.$1.id != messageId).take(limit).map((r) => r.$1).toList();
  }

  Future<void> updateEmbedding(MessageID messageId, List<double> embedding) async {
    final entity = _getByMessageId(messageId.toString());
    if (entity == null) throw StateError('Message not found');
    entity.embedding = embedding;
    _messageBox.put(entity);
  }

  Future<List<Message>> getMessagesWithoutEmbedding({int limit = 100}) async {
    final all = _messageBox.getAll()
        .where((m) => (m.embedding == null || m.embedding!.isEmpty))
        .where((m) => m.deletedAt == null || m.deletedAt! <= 0)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entities = all.take(limit).toList();
    return await _loadWithReactions(entities);
  }

  // Helper methods

  MessageEntity? _getByMessageId(String messageId) {
    final all = _messageBox.getAll();
    try {
      return all.firstWhere((e) => e.messageId == messageId);
    } catch (_) {
      return null;
    }
  }

  void _insertMessageSync(Message message) {
    final entity = _toEntity(message);
    _messageBox.put(entity);
    if (message.reactions != null && message.reactions!.isNotEmpty) {
      _insertReactionsSync(message.id, message.reactions!);
    }
  }

  ReactionEntity? _findReaction({
    required String messageId,
    required String userId,
    required String reactionKey,
  }) {
    final query = _reactionBox
        .query(ReactionEntity_.messageId.equals(messageId) &
            ReactionEntity_.userId.equals(userId) &
            ReactionEntity_.reactionKey.equals(reactionKey))
        .build();
    final existing = query.findFirst();
    query.close();
    return existing;
  }

  void _putReactionIfAbsent({
    required String messageId,
    required String userId,
    required String reactionKey,
  }) {
    final existing = _findReaction(
      messageId: messageId,
      userId: userId,
      reactionKey: reactionKey,
    );
    if (existing != null) return;
    _reactionBox.put(ReactionEntity.create(
      messageId: messageId,
      reactionKey: reactionKey,
      userId: userId,
    ));
  }

  void _insertReactionsSync(MessageID messageId, Map<String, List<UserID>> reactions) {
    for (final entry in reactions.entries) {
      for (final userId in entry.value) {
        _putReactionIfAbsent(
          messageId: messageId.toString(),
          userId: userId.toString(),
          reactionKey: entry.key,
        );
      }
    }
  }

  Future<void> _insertReactions(MessageID messageId, Map<String, List<UserID>> reactions) async {
    _insertReactionsSync(messageId, reactions);
  }

  Future<void> _updateReactions(MessageID messageId, Map<String, List<UserID>>? reactions) async {
    await clearReactions(messageId);
    if (reactions != null && reactions.isNotEmpty) {
      await _insertReactions(messageId, reactions);
    }
  }

  Future<Map<String, List<UserID>>> _getReactions(MessageID messageId) async {
    final all = _reactionBox.getAll().where((r) => r.messageId == messageId.toString()).toList();
    final reactions = <String, List<UserID>>{};
    for (final entity in all) {
      reactions.putIfAbsent(entity.reactionKey, () => []).add(entity.userId);
    }
    return reactions;
  }

  Future<List<Message>> _loadWithReactions(List<MessageEntity> entities) async {
    final messages = entities.map(_toModel).toList();
    final result = <Message>[];
    for (final message in messages) {
      final reactions = await _getReactions(message.id);
      result.add(_withReactions(message, reactions));
    }
    return result;
  }

  Message _withReactions(Message message, Map<String, List<UserID>> reactions) {
    return message.copyWith(reactions: reactions.isEmpty ? null : reactions);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  MessageEntity _toEntity(Message message) {
    // Extract type-specific fields with proper type checking
    int? editedAt;
    if (message is TextMessage) {
      editedAt = message.editedAt?.millisecondsSinceEpoch;
    }
    
    String? streamId;
    if (message is TextStreamMessage) {
      streamId = message.streamId;
    }

    // Extract media fields based on message type
    String? thumbhash, blurhash, fileName, mimeType, waveformJson;
    double? width, height;
    int? size, duration;
    bool? hasOverlay;

    if (message is ImageMessage) {
      thumbhash = message.thumbhash;
      blurhash = message.blurhash;
      width = message.width;
      height = message.height;
      size = message.size;
      hasOverlay = message.hasOverlay;
    } else if (message is FileMessage) {
      fileName = message.name;
      mimeType = message.mimeType;
      size = message.size;
    } else if (message is VideoMessage) {
      fileName = message.name;
      width = message.width;
      height = message.height;
      size = message.size;
    } else if (message is AudioMessage) {
      duration = message.duration.inMilliseconds;
      size = message.size;
      waveformJson = message.waveform != null ? jsonEncode(message.waveform) : null;
    }

    return MessageEntity(
      messageId: message.id.toString(),
      type: message.runtimeType.toString(),
      authorId: message.authorId.toString(),
      replyToMessageId: message.replyToMessageId?.toString(),
      createdAt: message.createdAt?.millisecondsSinceEpoch ?? 0,
      deletedAt: message.deletedAt?.millisecondsSinceEpoch,
      failedAt: message.failedAt?.millisecondsSinceEpoch,
      sentAt: message.sentAt?.millisecondsSinceEpoch,
      deliveredAt: message.deliveredAt?.millisecondsSinceEpoch,
      seenAt: message.seenAt?.millisecondsSinceEpoch,
      updatedAt: message.updatedAt?.millisecondsSinceEpoch,
      editedAt: editedAt,
      pinned: message.pinned ?? false,
      status: message.status?.name,
      textContent: _extractTextContent(message),
      mediaSource: _extractMediaSource(message),
      mediaMetadataJson: _extractMediaMetadata(message),
      customMetadataJson: message.metadata != null ? jsonEncode(message.metadata) : null,
      reactionsJson: message.reactions != null ? jsonEncode(message.reactions) : null,
      streamId: streamId,
      thumbhash: thumbhash,
      blurhash: blurhash,
      width: width,
      height: height,
      size: size,
      hasOverlay: hasOverlay,
      fileName: fileName,
      mimeType: mimeType,
      duration: duration,
      waveformJson: waveformJson,
      linkPreviewDataJson: _extractLinkPreviewData(message),
      embedding: null,
    );
  }

  Message _toModel(MessageEntity entity) {
    final createdAt = entity.createdAt > 0 ? DateTime.fromMillisecondsSinceEpoch(entity.createdAt) : null;
    final deletedAt = entity.deletedAt != null && entity.deletedAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.deletedAt!)
        : null;
    final failedAt = entity.failedAt != null && entity.failedAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.failedAt!)
        : null;
    final sentAt = entity.sentAt != null && entity.sentAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.sentAt!)
        : null;
    final deliveredAt = entity.deliveredAt != null && entity.deliveredAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.deliveredAt!)
        : null;
    final seenAt = entity.seenAt != null && entity.seenAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.seenAt!)
        : null;
    final updatedAt = entity.updatedAt != null && entity.updatedAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.updatedAt!)
        : null;
    final editedAt = entity.editedAt != null && entity.editedAt! > 0
        ? DateTime.fromMillisecondsSinceEpoch(entity.editedAt!)
        : null;
    final status = _parseMessageStatus(entity.status);
    final metadata = entity.customMetadataJson != null
        ? jsonDecode(entity.customMetadataJson!) as Map<String, dynamic>
        : null;

    switch (entity.type) {
      case 'TextMessage':
        return Message.text(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          editedAt: editedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          text: entity.textContent ?? '',
          linkPreviewData: entity.linkPreviewDataJson != null
              ? LinkPreviewData.fromJson(jsonDecode(entity.linkPreviewDataJson!) as Map<String, dynamic>)
              : null,
        );
      case 'ImageMessage':
        return Message.image(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          source: entity.mediaSource ?? '',
          text: entity.textContent,
          thumbhash: entity.thumbhash,
          blurhash: entity.blurhash,
          width: entity.width,
          height: entity.height,
          size: entity.size,
          hasOverlay: entity.hasOverlay,
        );
      case 'FileMessage':
        return Message.file(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          source: entity.mediaSource ?? '',
          name: entity.fileName ?? '',
          size: entity.size,
          mimeType: entity.mimeType,
        );
      case 'VideoMessage':
        return Message.video(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          source: entity.mediaSource ?? '',
          text: entity.textContent,
          name: entity.fileName,
          size: entity.size,
          width: entity.width,
          height: entity.height,
        );
      case 'AudioMessage':
        final mediaMetadata = entity.mediaMetadataJson != null
            ? jsonDecode(entity.mediaMetadataJson!) as Map<String, dynamic>
            : {};
        final waveform = mediaMetadata['waveform'] as List<dynamic>?;
        return Message.audio(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          source: entity.mediaSource ?? '',
          duration: entity.duration != null ? Duration(milliseconds: entity.duration!) : Duration.zero,
          text: entity.textContent,
          size: entity.size,
          waveform: waveform?.map((e) => e as double).toList(),
        );
      case 'SystemMessage':
        return Message.system(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
          text: entity.textContent ?? '',
        );
      case 'CustomMessage':
        return Message.custom(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
        );
      case 'TextStreamMessage':
        return Message.textStream(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          metadata: metadata,
          status: status,
          streamId: entity.streamId ?? '',
        );
      default:
        return Message.unsupported(
          id: entity.messageId,
          authorId: entity.authorId,
          replyToMessageId: entity.replyToMessageId,
          createdAt: createdAt,
          deletedAt: deletedAt,
          failedAt: failedAt,
          sentAt: sentAt,
          deliveredAt: deliveredAt,
          seenAt: seenAt,
          updatedAt: updatedAt,
          pinned: entity.pinned,
          status: status,
          metadata: metadata,
        );
    }
  }

  String? _extractTextContent(Message message) {
    if (message is TextMessage) {
      return message.text;
    }
    if (message is SystemMessage) {
      return message.text;
    }
    if (message is ImageMessage) {
      return message.text;
    }
    if (message is VideoMessage) {
      return message.text;
    }
    if (message is AudioMessage) {
      return message.text;
    }
    return null;
  }

  String? _extractMediaSource(Message message) {
    if (message is ImageMessage) return message.source;
    if (message is FileMessage) return message.source;
    if (message is VideoMessage) return message.source;
    if (message is AudioMessage) return message.source;
    return null;
  }

  String? _extractMediaMetadata(Message message) {
    final metadata = <String, dynamic>{};
    
    if (message is TextMessage) {
      if (message.linkPreviewData != null) {
        metadata['linkPreviewData'] = message.linkPreviewData;
      }
    } else if (message is ImageMessage) {
      if (message.text != null) metadata['text'] = message.text;
      if (message.thumbhash != null) metadata['thumbhash'] = message.thumbhash;
      if (message.blurhash != null) metadata['blurhash'] = message.blurhash;
      if (message.width != null) metadata['width'] = message.width;
      if (message.height != null) metadata['height'] = message.height;
      if (message.size != null) metadata['size'] = message.size;
      if (message.hasOverlay != null) metadata['hasOverlay'] = message.hasOverlay;
    } else if (message is FileMessage) {
      if (message.name != null) metadata['name'] = message.name;
      if (message.mimeType != null) metadata['mimeType'] = message.mimeType;
      if (message.size != null) metadata['size'] = message.size;
    } else if (message is VideoMessage) {
      if (message.text != null) metadata['text'] = message.text;
      if (message.name != null) metadata['name'] = message.name;
      if (message.size != null) metadata['size'] = message.size;
      if (message.width != null) metadata['width'] = message.width;
      if (message.height != null) metadata['height'] = message.height;
    } else if (message is AudioMessage) {
      if (message.text != null) metadata['text'] = message.text;
      if (message.duration != null) metadata['duration'] = message.duration.inMilliseconds;
      if (message.size != null) metadata['size'] = message.size;
      if (message.waveform != null) metadata['waveform'] = message.waveform;
    }
    
    if (metadata.isEmpty) return null;
    return jsonEncode(metadata);
  }

  String? _extractLinkPreviewData(Message message) {
    if (message is TextMessage && message.linkPreviewData != null) {
      return jsonEncode(message.linkPreviewData);
    }
    return null;
  }

  MessageStatus? _parseMessageStatus(String? status) {
    if (status == null) return null;
    try {
      return MessageStatus.values.firstWhere((e) => e.name == status);
    } catch (_) {
      return null;
    }
  }
}
