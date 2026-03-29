import 'dart:async';

import '../../flutter_chat_core/src/chat_controller/chat_controller.dart';
import '../../flutter_chat_core/src/chat_controller/chat_operation.dart';
import '../../flutter_chat_core/src/models/message.dart';
import '../../flutter_chat_core/src/models/user.dart';
import '../data.dart';

/// A [ChatController] implementation that persists messages and users to DuckDB.
///
/// This controller implements [ChatController] to maintain UI state in memory
/// for fast access, while syncing all changes to DuckDB for persistence.
///
/// Example usage:
/// ```dart
/// // Initialize database
/// final dbPath = await DatabasePathProvider.getDatabasePath();
/// final database = ChatDatabaseService(dbPath: dbPath);
/// await database.initialize();
///
/// // Create controller with DuckDB persistence
/// final controller = DuckDBChatController(
///   messageRepository: MessageRepository(database),
///   userRepository: UserRepository(database),
/// );
///
/// // Load messages from database
/// await controller.loadMessages();
/// ```
class DuckDBChatController implements ChatController {
  final MessageRepository _messageRepository;
  final UserRepository _userRepository;

  /// In-memory cache of messages for fast UI access
  List<Message> _messages = [];

  /// Stream controller for operations
  final _operationsController = StreamController<ChatOperation>.broadcast();

  /// Creates a [DuckDBChatController] instance.
  DuckDBChatController({
    required MessageRepository messageRepository,
    required UserRepository userRepository,
  })  : _messageRepository = messageRepository,
        _userRepository = userRepository;

  @override
  Future<void> insertMessage(Message message, {int? index}) async {
    // Persist to DuckDB first
    await _messageRepository.insertMessage(message);

    // Update in-memory cache
    final insertIndex = index ?? _messages.length;
    _messages.insert(insertIndex, message);

    // Notify UI
    _operationsController.add(ChatOperation.insert(message, insertIndex));
  }

  @override
  Future<void> insertAllMessages(List<Message> messages, {int? index}) async {
    // Persist to DuckDB atomically
    await _messageRepository.insertMessages(messages);

    // Update in-memory cache only after DB succeeds
    final insertIndex = index ?? _messages.length;
    _messages.insertAll(insertIndex, messages);

    // Notify UI
    _operationsController.add(ChatOperation.insertAll(messages, insertIndex));
  }

  @override
  Future<void> updateMessage(Message oldMessage, Message newMessage) async {
    // Persist to DuckDB
    await _messageRepository.updateMessage(newMessage);

    // Find the actual cached message to use as oldMessage
    final index = _messages.indexWhere((m) => m.id == oldMessage.id);
    if (index != -1) {
      final cachedOld = _messages[index];
      _messages[index] = newMessage;
      // Use the actual cached message, not the potentially stale oldMessage
      _operationsController.add(ChatOperation.update(cachedOld, newMessage, index));
    }
  }

  @override
  Future<void> removeMessage(Message message) async {
    // Remove from DuckDB (soft delete)
    await _messageRepository.softDeleteMessage(message.id);

    // Find and remove from in-memory cache
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final removedMessage = _messages.removeAt(index);
      _operationsController.add(ChatOperation.remove(removedMessage, index));
    }
  }

  @override
  Future<void> setMessages(List<Message> messages) async {
    // Only update in-memory cache and notify UI
    // Note: This method is for UI state management, not persistence
    _messages.clear();
    _messages.addAll(messages);

    // Notify UI
    _operationsController.add(ChatOperation.set(messages));
  }

  @override
  List<Message> get messages => List.unmodifiable(_messages);

  @override
  Stream<ChatOperation> get operationsStream => _operationsController.stream;

  /// Loads messages from DuckDB into the in-memory cache.
  ///
  /// Call this method when initializing the chat to populate the UI with
  /// previously persisted messages.
  ///
  /// Parameters:
  /// - [limit]: Maximum number of messages to load (default: 50)
  /// - [authorId]: Optional filter by author ID
  /// - [before]: Optional load messages before this timestamp
  ///
  /// Returns the loaded messages.
  Future<List<Message>> loadMessages({
    int limit = 50,
    String? authorId,
    DateTime? before,
  }) async {
    List<Message> loadedMessages;

    if (authorId != null) {
      loadedMessages = await _messageRepository.getMessagesByAuthor(
        authorId,
        limit: limit,
        before: before,
      );
    } else if (before != null) {
      // Use range query when before is specified
      loadedMessages = await _messageRepository.getMessagesInRange(
        before: before,
        limit: limit,
      );
    } else {
      loadedMessages = await _messageRepository.getAllMessages(
        limit: limit,
      );
    }

    // Reverse to get chronological order (oldest first)
    loadedMessages = loadedMessages.reversed.toList();

    // Update in-memory cache
    _messages.clear();
    _messages.addAll(loadedMessages);

    // Notify UI
    _operationsController.add(ChatOperation.set(loadedMessages));

    return loadedMessages;
  }

  /// Loads older messages for pagination (infinite scroll).
  ///
  /// Call this when user scrolls to the top of the chat to load more history.
  ///
  /// Returns the loaded messages (in chronological order).
  Future<List<Message>> loadOlderMessages({
    required DateTime before,
    int limit = 20,
  }) async {
    final olderMessages = await _messageRepository.getMessagesInRange(
      before: before,
      limit: limit,
    );

    // Reverse to get chronological order
    final reversedMessages = olderMessages.reversed.toList();

    if (reversedMessages.isEmpty) {
      return [];
    }

    // Insert at beginning of in-memory cache
    final insertIndex = 0;
    _messages.insertAll(insertIndex, reversedMessages);

    // Notify UI
    _operationsController.add(
      ChatOperation.insertAll(reversedMessages, insertIndex),
    );

    return reversedMessages;
  }

  /// Saves or updates a user in DuckDB.
  Future<void> saveUser(User user) async {
    await _userRepository.upsertUser(user);
  }

  /// Gets a user by ID from DuckDB.
  Future<User?> getUser(String userId) async {
    return await _userRepository.getUserById(userId);
  }

  /// Loads all users from DuckDB.
  Future<List<User>> loadUsers({int limit = 100}) async {
    return await _userRepository.getAllUsers(limit: limit);
  }

  /// Adds a reaction to a message.
  Future<void> addReaction(
    String messageId,
    String userId,
    String reactionKey,
  ) async {
    await _messageRepository.addReaction(messageId, userId, reactionKey);

    // Update in-memory cache
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final updatedMessage = _copyMessageWithReaction(
        message,
        userId,
        reactionKey,
        add: true,
      );
      _messages[index] = updatedMessage;
      _operationsController.add(ChatOperation.update(message, updatedMessage, index));
    }
  }

  /// Removes a reaction from a message.
  Future<void> removeReaction(
    String messageId,
    String userId,
    String reactionKey,
  ) async {
    await _messageRepository.removeReaction(messageId, userId, reactionKey);

    // Update in-memory cache
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final updatedMessage = _copyMessageWithReaction(
        message,
        userId,
        reactionKey,
        add: false,
      );
      _messages[index] = updatedMessage;
      _operationsController.add(ChatOperation.update(message, updatedMessage, index));
    }
  }

  /// Helper to copy a message with updated reactions
  Message _copyMessageWithReaction(
    Message message,
    String userId,
    String reactionKey, {
    required bool add,
  }) {
    // Deep copy the reactions map to avoid mutating the original
    final reactions = <String, List<String>>{};
    final originalReactions = message.reactions ?? {};
    for (final entry in originalReactions.entries) {
      reactions[entry.key] = List<String>.from(entry.value);
    }

    if (add) {
      reactions.putIfAbsent(reactionKey, () => []).add(userId);
    } else {
      final users = reactions[reactionKey];
      if (users != null) {
        users.remove(userId);
        if (users.isEmpty) {
          reactions.remove(reactionKey);
        }
      }
    }

    return message.copyWith(reactions: reactions.isEmpty ? null : reactions);
  }

  /// Searches messages by text content.
  Future<List<Message>> searchMessages(String query, {int limit = 50}) async {
    return await _messageRepository.searchMessages(query, limit: limit);
  }

  /// Gets pinned messages.
  Future<List<Message>> getPinnedMessages({int limit = 50}) async {
    return await _messageRepository.getPinnedMessages(limit: limit);
  }

  /// Gets message statistics.
  Future<Map<String, int>> getMessageStats() async {
    return await _messageRepository.getMessageStats();
  }

  @override
  void dispose() {
    _operationsController.close();
  }
}
