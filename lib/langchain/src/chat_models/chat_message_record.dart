import 'package:objectbox/objectbox.dart';

/// ObjectBox record untuk menyimpan [ChatMessage] dari LangChain.
///
/// Ini SATU-SATUNYA entity yang dibutuhkan untuk persistensi chat messages.
@Entity()
class ChatMessageRecord {
  ChatMessageRecord({
    required this.id,
    required this.messageId,
    required this.sessionId,
    required this.role,
    required this.content,
    this.toolCallId,
    this.toolCallsJson,
    this.customRole,
    required this.createdAt,
  });

  int id;
  String messageId;
  String sessionId;
  String role;
  String content;
  String? toolCallId;
  String? toolCallsJson;
  String? customRole;
  int createdAt;
}
