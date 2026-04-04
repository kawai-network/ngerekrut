import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for Message with vector embedding support.
@Entity()
class MessageEntity {
  int id;

  @Unique()
  String messageId;

  String type;
  String authorId;
  String? replyToMessageId;

  int createdAt;
  int? deletedAt;
  int? failedAt;
  int? sentAt;
  int? deliveredAt;
  int? seenAt;
  int? updatedAt;
  int? editedAt;

  bool pinned;
  String? status;
  String? textContent;
  String? mediaSource;
  String? mediaMetadataJson;
  String? customMetadataJson;
  String? reactionsJson;
  String? streamId;

  String? thumbhash;
  String? blurhash;
  double? width;
  double? height;
  int? size;
  bool? hasOverlay;
  String? fileName;
  String? mimeType;
  int? duration;
  String? waveformJson;
  String? linkPreviewDataJson;

  /// Vector embedding for semantic search (HNSW index).
  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 768)
  List<double>? embedding;

  MessageEntity({
    this.id = 0,
    required this.messageId,
    required this.type,
    required this.authorId,
    this.replyToMessageId,
    this.createdAt = 0,
    this.deletedAt,
    this.failedAt,
    this.sentAt,
    this.deliveredAt,
    this.seenAt,
    this.updatedAt,
    this.editedAt,
    this.pinned = false,
    this.status,
    this.textContent,
    this.mediaSource,
    this.mediaMetadataJson,
    this.customMetadataJson,
    this.reactionsJson,
    this.streamId,
    this.thumbhash,
    this.blurhash,
    this.width,
    this.height,
    this.size,
    this.hasOverlay,
    this.fileName,
    this.mimeType,
    this.duration,
    this.waveformJson,
    this.linkPreviewDataJson,
    this.embedding,
  });
}
