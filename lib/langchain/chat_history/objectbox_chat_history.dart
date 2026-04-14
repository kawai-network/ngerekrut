/// ObjectBox-backed implementation of LangChain's BaseChatMessageHistory.
///
/// Provides persistent chat history for assistant conversations.
library;

import '../chat_history/chat_history.dart';
import '../chat_models/chat_models.dart';
import '../chat_models/types_persist.dart';

/// LangChain-compatible chat history backed by ObjectBox.
///
/// Uses existing [ChatMessage.save] and [ChatMessage.fromSession] methods
/// to persist and retrieve messages.
class ObjectBoxChatHistory extends BaseChatMessageHistory {
  /// Unique session identifier.
  final String sessionId;

  ObjectBoxChatHistory({required this.sessionId});

  @override
  Future<List<ChatMessage>> getChatMessages() async {
    return ChatMessage.fromSession(sessionId);
  }

  @override
  Future<void> addChatMessage(ChatMessage message) async {
    message.save(sessionId);
  }

  @override
  Future<ChatMessage> removeFirst() async {
    final messages = await getChatMessages();
    if (messages.isEmpty) {
      throw StateError('Cannot remove from empty history');
    }
    final first = messages.first;
    ChatMessage.deleteSession(sessionId);
    // Re-save all except first
    for (final msg in messages.skip(1)) {
      msg.save(sessionId);
    }
    return first;
  }

  @override
  Future<ChatMessage> removeLast() async {
    final messages = await getChatMessages();
    if (messages.isEmpty) {
      throw StateError('Cannot remove from empty history');
    }
    final last = messages.last;
    // Delete and re-save all except last
    ChatMessage.deleteSession(sessionId);
    for (final msg in messages.take(messages.length - 1)) {
      msg.save(sessionId);
    }
    return last;
  }

  @override
  Future<void> clear() async {
    ChatMessage.deleteSession(sessionId);
  }
}
