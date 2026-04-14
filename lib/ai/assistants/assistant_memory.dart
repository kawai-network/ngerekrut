/// Conversation memory for assistant chat.
///
/// Stores conversation history per assistant ID for persistence across sessions.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Represents a single message in the conversation.
class ConversationMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Manages conversation memory per assistant.
class AssistantMemory {
  static final AssistantMemory _instance = AssistantMemory._internal();
  factory AssistantMemory() => _instance;
  AssistantMemory._internal();

  /// In-memory storage: assistantId -> list of messages
  final Map<String, List<ConversationMessage>> _memories = {};

  /// Maximum messages to keep per assistant.
  static const int maxMessages = 50;

  /// Get conversation history for an assistant.
  List<ConversationMessage> getHistory(String assistantId) {
    return List.unmodifiable(_memories[assistantId] ?? []);
  }

  /// Add a message to the conversation history.
  void addMessage(String assistantId, ConversationMessage message) {
    _memories.putIfAbsent(assistantId, () => []);
    _memories[assistantId]!.add(message);

    // Trim old messages if exceeding max
    if (_memories[assistantId]!.length > maxMessages) {
      _memories[assistantId] = _memories[assistantId]!.sublist(
        _memories[assistantId]!.length - maxMessages,
      );
    }
  }

  /// Get recent conversation summary for context injection.
  String getRecentContext(String assistantId, {int maxMessages = 5}) {
    final history = _memories[assistantId] ?? [];
    if (history.isEmpty) return '';

    final recent = history.length > maxMessages
        ? history.sublist(history.length - maxMessages)
        : history;

    final buffer = StringBuffer();
    buffer.writeln('\n--- RIWAYAT PERCAKAPAN TERAKHIR ---');
    for (final msg in recent) {
      final roleLabel = msg.role == 'user' ? 'Pengguna' : 'Asisten';
      buffer.writeln('$roleLabel: ${msg.content}');
    }
    buffer.writeln('--- END RIWAYAT ---');
    return buffer.toString();
  }

  /// Clear conversation history for an assistant.
  void clearHistory(String assistantId) {
    _memories.remove(assistantId);
  }

  /// Clear all conversation histories.
  void clearAll() {
    _memories.clear();
  }

  /// Get conversation count for an assistant.
  int getMessageCount(String assistantId) {
    return _memories[assistantId]?.length ?? 0;
  }

  /// Serialize memories to JSON for persistence.
  String toJson() {
    final map = <String, dynamic>{};
    _memories.forEach((key, value) {
      map[key] = value.map((msg) => msg.toJson()).toList();
    });
    return jsonEncode(map);
  }

  /// Load memories from JSON string.
  void fromJson(String jsonString) {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      _memories.clear();
      map.forEach((key, value) {
        final list = value as List;
        _memories[key] = list
            .map((item) => ConversationMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      });
      debugPrint('[AssistantMemory] Loaded ${_memories.length} assistant histories');
    } catch (e) {
      debugPrint('[AssistantMemory] Failed to load memories: $e');
    }
  }
}
