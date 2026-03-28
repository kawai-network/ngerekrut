/// Example usage of the chat database integration.
/// 
/// This file demonstrates how to initialize and use the database layer
/// with the flutter_chat_core models.
library;

import 'package:flutter/foundation.dart';

import '../data/data.dart';
import '../flutter_chat_core/src/models/message.dart';
import '../flutter_chat_core/src/models/user.dart';
import '../flutter_chat_core/src/utils/typedefs.dart';

/// Example class showing how to use the database layer.
class ChatDatabaseExample {
  late final ChatDatabaseService _database;
  late final MessageRepository _messageRepository;
  late final UserRepository _userRepository;

  /// Initializes the database and repositories.
  Future<void> initialize({String? dbPath}) async {
    // Create database service with optional custom path
    _database = ChatDatabaseService(dbPath: dbPath);
    
    // Initialize database connection and run migrations
    await _database.initialize();
    
    // Create repositories
    _messageRepository = MessageRepository(_database);
    _userRepository = UserRepository(_database);
    
    debugPrint('Database initialized successfully');
  }

  /// Example: Create and save a user.
  Future<void> createUserExample() async {
    final user = User(
      id: 'user_123',
      name: 'John Doe',
      imageSource: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now(),
      metadata: {'role': 'admin'},
    );

    await _userRepository.upsertUser(user);
    debugPrint('User created: ${user.id}');
  }

  /// Example: Create and save a text message.
  Future<void> createTextMessageExample() async {
    final message = Message.text(
      id: 'msg_456',
      authorId: 'user_123',
      text: 'Hello, World!',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _messageRepository.insertMessage(message);
    debugPrint('Message created: ${message.id}');
  }

  /// Example: Create and save an image message.
  Future<void> createImageMessageExample() async {
    final message = Message.image(
      id: 'msg_789',
      authorId: 'user_123',
      source: 'https://example.com/image.jpg',
      width: 1920,
      height: 1080,
      size: 245678,
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _messageRepository.insertMessage(message);
    debugPrint('Image message created: ${message.id}');
  }

  /// Example: Add reaction to a message.
  Future<void> addReactionExample() async {
    await _messageRepository.addReaction(
      'msg_456',
      'user_789',
      '👍',
    );
    debugPrint('Reaction added');
  }

  /// Example: Get messages by author.
  Future<void> getMessagesExample() async {
    final messages = await _messageRepository.getMessagesByAuthor(
      'user_123',
      limit: 20,
    );

    debugPrint('Found ${messages.length} messages');
    
    for (final message in messages) {
      debugPrint('Message ${message.id}: ${message.resolvedStatus}');
    }
  }

  /// Example: Search messages.
  Future<void> searchMessagesExample() async {
    final messages = await _messageRepository.searchMessages('Hello');
    debugPrint('Found ${messages.length} matching messages');
  }

  /// Example: Get user by ID.
  Future<void> getUserExample() async {
    final user = await _userRepository.getUserById('user_123');
    if (user != null) {
      debugPrint('User: ${user.name}');
    }
  }

  /// Example: Get message statistics.
  Future<void> getStatsExample() async {
    final stats = await _messageRepository.getMessageStats();
    final totalCount = await _messageRepository.getMessageCount();
    
    debugPrint('Total messages: $totalCount');
    debugPrint('By type: $stats');
  }

  /// Example: Transaction usage.
  Future<void> transactionExample() async {
    await _database.runTransaction(() async {
      // Create user
      final user = User(
        id: 'user_txn',
        name: 'Transaction User',
        createdAt: DateTime.now(),
      );
      await _userRepository.insertUser(user);

      // Create message
      final message = Message.text(
        id: 'msg_txn',
        authorId: 'user_txn',
        text: 'Transaction message',
        createdAt: DateTime.now(),
      );
      await _messageRepository.insertMessage(message);

      // If any operation fails, entire transaction rolls back
    });
    
    debugPrint('Transaction completed');
  }

  /// Example: Get messages with pagination.
  Future<void> paginationExample() async {
    const pageSize = 20;
    DateTime? lastCreatedAt;
    
    // Load first page
    var messages = await _messageRepository.getAllMessages(limit: pageSize);
    if (messages.isNotEmpty) {
      lastCreatedAt = messages.last.createdAt;
    }
    
    debugPrint('First page: ${messages.length} messages');
    
    // Load next page
    if (lastCreatedAt != null) {
      messages = await _messageRepository.getMessagesInRange(
        before: lastCreatedAt,
        limit: pageSize,
      );
      debugPrint('Next page: ${messages.length} messages');
    }
  }

  /// Example: Update message status.
  Future<void> updateMessageStatusExample() async {
    final message = await _messageRepository.getMessageById('msg_456');
    if (message != null) {
      final updated = message.copyWith(
        seenAt: DateTime.now(),
        status: MessageStatus.seen,
      );
      await _messageRepository.updateMessage(updated);
      debugPrint('Message status updated to seen');
    }
  }

  /// Example: Soft delete a message.
  Future<void> softDeleteExample() async {
    await _messageRepository.softDeleteMessage('msg_456');
    debugPrint('Message soft deleted');
  }

  /// Example: Get pinned messages.
  Future<void> getPinnedMessagesExample() async {
    final messages = await _messageRepository.getPinnedMessages();
    debugPrint('Found ${messages.length} pinned messages');
  }

  /// Disposes the database connection.
  Future<void> dispose() async {
    await _database.close();
    debugPrint('Database closed');
  }
}

/// Flutter-specific initialization example.
class FlutterInitializationExample {
  /// Initialize database with proper path for Flutter.
  static Future<ChatDatabaseService> initializeDatabase() async {
    // Get platform-specific database path
    final dbPath = await DatabasePathProvider.getDatabasePath();
    
    // Create and initialize database
    final database = ChatDatabaseService(dbPath: dbPath);
    await database.initialize();
    
    return database;
  }

  /// Create repositories for use in your app.
  static Future<Map<String, dynamic>> createRepositories() async {
    final database = await initializeDatabase();
    
    return {
      'database': database,
      'messageRepository': MessageRepository(database),
      'userRepository': UserRepository(database),
    };
  }
}
