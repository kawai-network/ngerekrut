/// ObjectBox-backed implementation of LangChain's BaseChatMessageHistory.
///
/// Provides persistent chat history for assistant conversations.
library;

import '../chat_history/chat_history.dart';
import '../chat_models/chat_models.dart';
import '../../objectbox.g.dart';
import '../../objectbox_store_provider.dart';

/// LangChain-compatible chat history backed by ObjectBox.
///
/// Uses ObjectBox to persist and retrieve messages directly.
base class ObjectBoxChatHistory extends BaseChatMessageHistory {
  /// Unique session identifier.
  final String sessionId;

  ObjectBoxChatHistory({required this.sessionId});

  @override
  Future<List<ChatMessage>> getChatMessages() async {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final builder = box.query(ChatMessageRecord_.sessionId.equals(sessionId))
      ..order(ChatMessageRecord_.createdAt);
    final query = builder.build();
    final records = query.find();
    query.close();

    return records.map(_toChatMessage).toList();
  }

  @override
  Future<void> addChatMessage(ChatMessage message) async {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final record = ChatMessageRecord(
      id: 0,
      messageId: _generateId(),
      sessionId: sessionId,
      role: _getRole(message),
      content: _getContent(message),
      toolCallId: _getToolCallId(message),
      toolCallsJson: _getToolCallsJson(message),
      customRole: _getCustomRole(message),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    box.put(record);
  }

  @override
  Future<ChatMessage> removeFirst() async {
    final messages = await getChatMessages();
    if (messages.isEmpty) {
      throw StateError('Cannot remove from empty history');
    }
    final first = messages.first;
    await _deleteAllMessages();
    // Re-save all except first
    for (final msg in messages.skip(1)) {
      await addChatMessage(msg);
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
    await _deleteAllMessages();
    for (final msg in messages.take(messages.length - 1)) {
      await addChatMessage(msg);
    }
    return last;
  }

  @override
  Future<void> clear() async {
    await _deleteAllMessages();
  }

  Future<void> _deleteAllMessages() async {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final builder = box.query(ChatMessageRecord_.sessionId.equals(sessionId));
    final query = builder.build();
    final records = query.find();
    query.close();

    box.removeMany(records.map((r) => r.id).toList());
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _getRole(ChatMessage msg) => switch (msg) {
        SystemChatMessage() => 'system',
        HumanChatMessage() => 'human',
        AIChatMessage() => 'ai',
        ToolChatMessage() => 'tool',
        CustomChatMessage() => 'custom',
      };

  String _getContent(ChatMessage msg) => msg.contentAsString;

  String? _getToolCallId(ChatMessage msg) =>
      switch (msg) { ToolChatMessage(:final toolCallId) => toolCallId, _ => null };

  String? _getToolCallsJson(ChatMessage msg) =>
      switch (msg) {
        AIChatMessage(:final toolCalls) when toolCalls.isNotEmpty =>
          _serializeToolCalls(toolCalls),
        _ => null,
      };

  String? _getCustomRole(ChatMessage msg) =>
      switch (msg) { CustomChatMessage(:final role) => role, _ => null };

  String _serializeToolCalls(List<dynamic> toolCalls) {
    // Simplified serialization
    return toolCalls.map((tc) => tc.toString()).join(',');
  }

  /// Convert record to ChatMessage.
  ChatMessage _toChatMessage(ChatMessageRecord record) {
    return switch (record.role) {
      'system' => ChatMessage.system(record.content),
      'human' => ChatMessage.humanText(record.content),
      'ai' => ChatMessage.ai(record.content),
      'tool' => ChatMessage.tool(
          toolCallId: record.toolCallId ?? '',
          content: record.content,
        ),
      'custom' => ChatMessage.custom(
          record.content,
          role: record.customRole ?? 'custom',
        ),
      _ => ChatMessage.humanText(record.content),
    };
  }
}
