import 'dart:async';

import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:ngerekrut/langchain/langchain.dart';
import 'package:ngerekrut/objectbox.g.dart';
import 'package:ngerekrut/objectbox_store_provider.dart';

/// Simple chat controller yang menggunakan [ChatMessagePersist].
///
/// Ini adalah implementasi [ChatController] yang menggunakan
/// LangChain's ChatMessage dengan ObjectBox persistence.
class ObjectBoxChatController extends InMemoryChatController {
  /// Creates a new controller.
  ObjectBoxChatController({
    required this.sessionId,
    super.messages,
  });

  /// Session ID untuk grouping messages.
  final String sessionId;

  /// Loads messages from ObjectBox storage.
  Future<void> loadMessages({int limit = 50}) async {
    // Initialize ObjectBox if not already
    if (!ObjectBoxStoreProvider.isInitialized) {
      await ObjectBoxStoreProvider.initialize();
    }

    final box = ObjectBoxStoreProvider.box<ChatMessageRecord>();
    final query = box
        .query(ChatMessageRecord_.sessionId.equals(sessionId))
        .order(ChatMessageRecord_.createdAt)
        .build();
    final records = query.find();
    query.close();

    final messages = records.map(_recordToMessage).toList();

    await setMessages(messages);
  }

  @override
  Future<void> insertMessage(
    Message message, {
    int? index,
    bool animated = true,
  }) async {
    final chatMsg = _messageToChatMessage(message);
    chatMsg.save(sessionId);

    await super.insertMessage(message, index: index, animated: animated);
  }

  @override
  Future<void> setMessages(List<Message> messages, {bool animated = true}) async {
    // Clear in-memory and set new messages
    _clearInMemory();
    await insertAllMessages(messages, animated: animated);
  }

  void _clearInMemory() {
    // Clear messages from InMemoryChatController
    final currentMessages = List<Message>.from(messages);
    for (final message in currentMessages) {
      removeMessage(message);
    }
  }

  Message _recordToMessage(ChatMessageRecord record) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    return switch (record.role) {
      'system' => Message.system(
          id: record.messageId,
          authorId: 'system',
          createdAt: createdAt,
          text: record.content,
        ),
      'ai' => Message.text(
          id: record.messageId,
          authorId: 'ai',
          createdAt: createdAt,
          text: record.content,
          status: MessageStatus.sent,
        ),
      'tool' => Message.text(
          id: record.messageId,
          authorId: 'tool',
          createdAt: createdAt,
          text: record.content,
          status: MessageStatus.sent,
        ),
      'custom' => Message.custom(
          id: record.messageId,
          authorId: record.customRole ?? 'custom',
          createdAt: createdAt,
          metadata: {'role': record.customRole ?? 'custom'},
        ),
      _ => Message.text(
          id: record.messageId,
          authorId: 'user',
          createdAt: createdAt,
          text: record.content,
          status: MessageStatus.sent,
        ),
    };
  }

  ChatMessage _messageToChatMessage(Message message) {
    final content = _extractTextContent(message);
    if (message is SystemMessage || message.authorId == 'system') {
      return ChatMessage.system(content);
    }
    if (message.authorId == 'ai' || message.authorId == 'assistant') {
      return ChatMessage.ai(content);
    }
    if (message.authorId == 'tool') {
      return ChatMessage.tool(toolCallId: 'tool', content: content);
    }
    if (message is CustomMessage) {
      return ChatMessage.custom(content, role: message.authorId);
    }
    return ChatMessage.humanText(content);
  }

  String _extractTextContent(Message message) {
    if (message is TextMessage) return message.text;
    if (message is SystemMessage) return message.text;
    if (message is ImageMessage) return message.text ?? '';
    if (message is VideoMessage) return message.text ?? '';
    if (message is AudioMessage) return message.text ?? '';
    if (message is FileMessage) return message.name;
    return '';
  }
}
