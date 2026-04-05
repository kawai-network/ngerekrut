import 'dart:async';

import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:ngerekrut/langchain/langchain.dart';
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

    // Load messages via ChatMessagePersist
    final chatMessages = ChatMessageQuery.fromSession(sessionId);

    // Convert ChatMessage ke Message (flutter_chat_core format)
    final messages = chatMessages.map(_chatMessageToMessage).toList();

    await setMessages(messages);
  }

  @override
  Future<void> insertMessage(
    Message message, {
    int? index,
    bool animated = true,
  }) async {
    // Simpan via ChatMessagePersist
    final content = _extractTextContent(message);
    final chatMsg = ChatMessage.humanText(content);
    chatMsg.save(sessionId);

    // Add to in-memory list
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

  /// Convert [ChatMessage] (LangChain) ke [Message] (flutter_chat_core).
  Message _chatMessageToMessage(ChatMessage chatMsg) {
    final now = DateTime.now();
    final authorId = switch (chatMsg) {
      SystemChatMessage() => 'system',
      HumanChatMessage() => 'user',
      AIChatMessage() => 'ai',
      ToolChatMessage() => 'tool',
      CustomChatMessage(:final role) => role,
    };

    return switch (chatMsg) {
      SystemChatMessage(:final content) => Message.system(
          id: _generateId(),
          authorId: authorId,
          createdAt: now,
          text: content,
        ),

      HumanChatMessage() => Message.text(
          id: _generateId(),
          authorId: authorId,
          createdAt: now,
          text: _extractContentText(chatMsg),
        ),

      AIChatMessage(:final content, :final toolCalls) => Message.text(
          id: _generateId(),
          authorId: authorId,
          createdAt: now,
          text: content,
          metadata: toolCalls.isNotEmpty ? {'hasToolCalls': true} : null,
        ),

      ToolChatMessage(:final content) => Message.text(
          id: _generateId(),
          authorId: authorId,
          createdAt: now,
          text: content,
        ),

      CustomChatMessage(:final role) => Message.custom(
          id: _generateId(),
          authorId: role,
          createdAt: now,
          metadata: {'role': role},
        ),
    };
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _extractContentText(ChatMessage chatMsg) {
    return switch (chatMsg) {
      HumanChatMessage(:final content) => switch (content) {
        ChatMessageContentText(:final text) => text,
        ChatMessageContentImage(:final data) => '[Image: $data]',
        ChatMessageContentMultiModal(:final parts) => parts
            .map((p) => switch (p) {
              ChatMessageContentText(:final text) => text,
              ChatMessageContentImage(:final data) => '[Image: $data]',
              ChatMessageContentMultiModal _ => '',
            })
            .join('\n'),
      },
      _ => chatMsg.contentAsString,
    };
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
