import '../../../objectbox.g.dart';
import '../../../objectbox_store_provider.dart';
import 'chat_message_record.dart';
import 'types.dart';

/// Persist extension untuk [ChatMessage].
///
/// Simpan message langsung ke ObjectBox.
extension ChatMessagePersist on ChatMessage {
  /// Simpan message ini ke session.
  int save(String sessionId) {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final record = ChatMessageRecord(
      id: 0,
      messageId: _generateId(),
      sessionId: sessionId,
      role: _getRole(this),
      content: _getContent(this),
      toolCallId: _getToolCallId(this),
      toolCallsJson: _getToolCallsJson(this),
      customRole: _getCustomRole(this),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    return box.put(record);
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
}

/// Query methods untuk [ChatMessage].
///
/// Static methods untuk mengambil messages dari ObjectBox.
extension ChatMessageQuery on ChatMessage {
  /// Ambil semua messages untuk session.
  static List<ChatMessage> fromSession(String sessionId) {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final builder = box.query(ChatMessageRecord_.sessionId.equals(sessionId));
    final query = builder.build();
    final records = query.find();
    query.close();

    return records.map(_toChatMessage).toList();
  }

  /// Ambil N messages terakhir.
  static List<ChatMessage> latest(String sessionId, {int count = 10}) {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final builder = box.query(ChatMessageRecord_.sessionId.equals(sessionId));
    final query = builder.build();
    final records = query.find();
    query.close();

    final limited = records.take(count).toList();
    return limited.map(_toChatMessage).toList();
  }

  /// Hapus session.
  static void deleteSession(String sessionId) {
    final store = ObjectBoxStoreProvider.store;
    final box = store.box<ChatMessageRecord>();

    final builder = box.query(ChatMessageRecord_.sessionId.equals(sessionId));
    final query = builder.build();
    final records = query.find();
    query.close();

    box.removeMany(records.map((r) => r.id).toList());
  }

  /// Convert record ke ChatMessage.
  static ChatMessage _toChatMessage(ChatMessageRecord record) {
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
