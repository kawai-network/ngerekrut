import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for Reaction.
@Entity()
class ReactionEntity {
  int id;

  @Index()
  String messageId;

  String reactionKey;

  @Index()
  String userId;

  int createdAt;

  ReactionEntity({
    this.id = 0,
    required this.messageId,
    required this.reactionKey,
    required this.userId,
    this.createdAt = 0,
  });

  factory ReactionEntity.create({
    required String messageId,
    required String reactionKey,
    required String userId,
  }) {
    return ReactionEntity(
      messageId: messageId,
      reactionKey: reactionKey,
      userId: userId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
