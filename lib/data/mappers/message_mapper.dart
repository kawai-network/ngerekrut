import 'dart:convert';

import '../../flutter_chat_core/src/models/message.dart';
import '../../flutter_chat_core/src/models/link_preview_data.dart';
import '../../flutter_chat_core/src/utils/typedefs.dart';
import '../database/chat_database_service.dart';

/// Mapper class for converting between [Message] objects and database rows.
///
/// Uses the hybrid approach:
/// - Common fields are stored in normalized columns
/// - Type-specific data is stored in JSON columns
class MessageMapper {
  /// Converts a [Message] object to a database row map.
  Map<String, dynamic> toRow(Message message) {
    final row = <String, dynamic>{
      'id': message.id,
      'type': _getTypeName(message),
      'author_id': message.authorId,
      'reply_to_message_id': message.replyToMessageId,
      'created_at': ChatDatabaseService.dateTimeToEpoch(message.createdAt),
      'deleted_at': ChatDatabaseService.dateTimeToEpoch(message.deletedAt),
      'failed_at': ChatDatabaseService.dateTimeToEpoch(message.failedAt),
      'sent_at': ChatDatabaseService.dateTimeToEpoch(message.sentAt),
      'delivered_at': ChatDatabaseService.dateTimeToEpoch(message.deliveredAt),
      'seen_at': ChatDatabaseService.dateTimeToEpoch(message.seenAt),
      'updated_at': ChatDatabaseService.dateTimeToEpoch(message.updatedAt),
      'pinned': message.pinned ?? false,
      'status': message.status?.name,
    };

    // Add type-specific fields
    if (message is TextMessage) {
      row['text_content'] = message.text;
      row['media_source'] = null;
      row['media_metadata'] = message.linkPreviewData != null
          ? jsonEncode({'linkPreviewData': message.linkPreviewData!.toJson()})
          : null;
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is TextStreamMessage) {
      row['text_content'] = null;
      row['media_source'] = null;
      row['media_metadata'] = jsonEncode({'streamId': message.streamId});
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is ImageMessage) {
      row['text_content'] = message.text;
      row['media_source'] = message.source;
      row['media_metadata'] = jsonEncode({
        if (message.thumbhash != null) 'thumbhash': message.thumbhash,
        if (message.blurhash != null) 'blurhash': message.blurhash,
        if (message.width != null) 'width': message.width,
        if (message.height != null) 'height': message.height,
        if (message.size != null) 'size': message.size,
        if (message.hasOverlay != null) 'hasOverlay': message.hasOverlay,
      });
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is FileMessage) {
      row['text_content'] = null;
      row['media_source'] = message.source;
      row['media_metadata'] = jsonEncode({
        'name': message.name,
        if (message.size != null) 'size': message.size,
        if (message.mimeType != null) 'mimeType': message.mimeType,
      });
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is VideoMessage) {
      row['text_content'] = message.text;
      row['media_source'] = message.source;
      row['media_metadata'] = jsonEncode({
        if (message.name != null) 'name': message.name,
        if (message.size != null) 'size': message.size,
        if (message.width != null) 'width': message.width,
        if (message.height != null) 'height': message.height,
      });
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is AudioMessage) {
      row['text_content'] = message.text;
      row['media_source'] = message.source;
      row['media_metadata'] = jsonEncode({
        'duration': message.duration.inMilliseconds,
        if (message.size != null) 'size': message.size,
        if (message.waveform != null) 'waveform': message.waveform,
      });
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is SystemMessage) {
      row['text_content'] = message.text;
      row['media_source'] = null;
      row['media_metadata'] = null;
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is CustomMessage) {
      row['text_content'] = null;
      row['media_source'] = null;
      row['media_metadata'] = null;
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    } else if (message is UnsupportedMessage) {
      row['text_content'] = null;
      row['media_source'] = null;
      row['media_metadata'] = null;
      row['custom_metadata'] = message.metadata != null
          ? jsonEncode(message.metadata)
          : null;
    }

    return row;
  }

  /// Converts a database row map to a [Message] object.
  Message fromRow(Map<String, dynamic> row) {
    final type = row['type'] as String;
    final textContent = row['text_content'] as String?;
    final mediaSource = row['media_source'] as String?;
    final mediaMetadata = ChatDatabaseService.decodeJson(
      row['media_metadata'] as String?,
    );
    final customMetadata = ChatDatabaseService.decodeJson(
      row['custom_metadata'] as String?,
    );

    switch (type) {
      case 'text':
        return Message.text(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          text: textContent ?? '',
          linkPreviewData: mediaMetadata?['linkPreviewData'] != null
              ? LinkPreviewData.fromJson(
                  mediaMetadata!['linkPreviewData'] as Map<String, dynamic>,
                )
              : null,
        );

      case 'text_stream':
        return Message.textStream(
          id: row['id'] as String,
          authorId: row['author_id'] as String,
          replyToMessageId: row['reply_to_message_id'] as String?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          streamId: mediaMetadata?['streamId'] as String? ?? '',
        );

      case 'image':
        return Message.image(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          source: mediaSource ?? '',
          text: textContent,
          thumbhash: mediaMetadata?['thumbhash'] as String?,
          blurhash: mediaMetadata?['blurhash'] as String?,
          width: (mediaMetadata?['width'] as num?)?.toDouble(),
          height: (mediaMetadata?['height'] as num?)?.toDouble(),
          size: mediaMetadata?['size'] as int?,
          hasOverlay: mediaMetadata?['hasOverlay'] as bool?,
        );

      case 'file':
        return Message.file(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          source: mediaSource ?? '',
          name: mediaMetadata?['name'] as String? ?? '',
          size: mediaMetadata?['size'] as int?,
          mimeType: mediaMetadata?['mimeType'] as String?,
        );

      case 'video':
        return Message.video(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          source: mediaSource ?? '',
          text: textContent,
          name: mediaMetadata?['name'] as String?,
          size: mediaMetadata?['size'] as int?,
          width: (mediaMetadata?['width'] as num?)?.toDouble(),
          height: (mediaMetadata?['height'] as num?)?.toDouble(),
        );

      case 'audio':
        return Message.audio(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          source: mediaSource ?? '',
          duration: Duration(
            milliseconds: mediaMetadata?['duration'] as int? ?? 0,
          ),
          text: textContent,
          size: mediaMetadata?['size'] as int?,
          waveform: mediaMetadata?['waveform'] != null
              ? List<double>.from(mediaMetadata!['waveform'] as List)
              : null,
        );

      case 'system':
        return Message.system(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
          text: textContent ?? '',
        );

      case 'custom':
        return Message.custom(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
        );

      default:
        return Message.unsupported(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: ChatDatabaseService.epochToDateTime(
            row['created_at'] as int?,
          ),
          deletedAt: ChatDatabaseService.epochToDateTime(
            row['deleted_at'] as int?,
          ),
          failedAt: ChatDatabaseService.epochToDateTime(
            row['failed_at'] as int?,
          ),
          sentAt: ChatDatabaseService.epochToDateTime(row['sent_at'] as int?),
          deliveredAt: ChatDatabaseService.epochToDateTime(
            row['delivered_at'] as int?,
          ),
          seenAt: ChatDatabaseService.epochToDateTime(row['seen_at'] as int?),
          updatedAt: ChatDatabaseService.epochToDateTime(
            row['updated_at'] as int?,
          ),
          reactions: null,
          pinned: row['pinned'] as bool?,
          metadata: customMetadata,
          status: _parseStatus(row['status'] as String?),
        );
    }
  }

  /// Parses a [MessageStatus] from a string.
  /// Returns null for unrecognized values.
  MessageStatus? _parseStatus(String? status) {
    if (status == null) return null;
    try {
      return MessageStatus.values.firstWhere(
        (e) => e.name == status,
      );
    } on StateError {
      // Unknown status value, return null
      return null;
    }
  }

  /// Gets the type name for a message.
  String _getTypeName(Message message) {
    if (message is TextMessage) return 'text';
    if (message is TextStreamMessage) return 'text_stream';
    if (message is ImageMessage) return 'image';
    if (message is FileMessage) return 'file';
    if (message is VideoMessage) return 'video';
    if (message is AudioMessage) return 'audio';
    if (message is SystemMessage) return 'system';
    if (message is CustomMessage) return 'custom';
    return 'unsupported';
  }
}
