import 'package:objectbox/objectbox.dart';

/// ObjectBox record untuk metadata sesi chat recruiter.
@Entity()
class ChatSessionRecord {
  ChatSessionRecord({
    this.id = 0,
    required this.sessionId,
    required this.title,
    required this.lastMessagePreview,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  int id;
  String sessionId;
  String title;
  String lastMessagePreview;
  int messageCount;
  int createdAt;
  int updatedAt;
}
