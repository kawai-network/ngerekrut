/// Complete example of integrating DuckDB with flutter_chat_core.
///
/// This example shows how to:
/// 1. Initialize DuckDB database
/// 2. Create DuckDBChatController
/// 3. Use the controller in your Flutter app
library;

import 'package:flutter/material.dart';

import 'data.dart';
import '../flutter_chat_core/src/models/message.dart';
import '../flutter_chat_core/src/utils/typedefs.dart';

/// Initialize DuckDB and create controller
Future<DuckDBChatController> initializeChatController() async {
  // 1. Get platform-specific database path
  final dbPath = await DatabasePathProvider.getDatabasePath();
  
  debugPrint('Database path: $dbPath');

  // 2. Create and initialize database service
  final database = ChatDatabaseService(dbPath: dbPath);
  await database.initialize();
  
  debugPrint('Database initialized');

  // 3. Create repositories
  final messageRepository = MessageRepository(database);
  final userRepository = UserRepository(database);

  // 4. Create DuckDB-backed chat controller
  final controller = DuckDBChatController(
    messageRepository: messageRepository,
    userRepository: userRepository,
  );

  // 5. Load existing messages from database
  await controller.loadMessages(limit: 50);
  
  debugPrint('Loaded ${controller.messages.length} messages');

  return controller;
}

/// Example Flutter widget using DuckDBChatController
class ChatScreenExample extends StatefulWidget {
  const ChatScreenExample({super.key});

  @override
  State<ChatScreenExample> createState() => _ChatScreenExampleState();
}

class _ChatScreenExampleState extends State<ChatScreenExample> {
  DuckDBChatController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _controller = await initializeChatController();
      
      // Listen to operations for UI updates
      _controller!.operationsStream.listen((operation) {
        setState(() {
          // Rebuild UI when messages change
        });
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing controller: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller == null) {
      return Scaffold(
        body: Center(child: Text('Failed to initialize chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('DuckDB Chat')),
      body: ListView.builder(
        itemCount: _controller!.messages.length,
        itemBuilder: (context, index) {
          final message = _controller!.messages[index];
          // Get text based on message type
          String text = '';
          if (message is TextMessage) {
            text = message.text;
          } else if (message is SystemMessage) {
            text = message.text;
          } else {
            text = '[${message.runtimeType}]';
          }
          return ListTile(
            title: Text(text),
            subtitle: Text(message.authorId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendTestMessage,
        child: const Icon(Icons.send),
      ),
    );
  }

  Future<void> _sendTestMessage() async {
    if (_controller == null) return;

    final message = Message.text(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'current_user',
      text: 'Hello from DuckDB!',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _controller!.insertMessage(message);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Example: Load older messages for infinite scroll
class PaginatedChatExample extends StatefulWidget {
  const PaginatedChatExample({super.key});

  @override
  State<PaginatedChatExample> createState() => _PaginatedChatExampleState();
}

class _PaginatedChatExampleState extends State<PaginatedChatExample> {
  DuckDBChatController? _controller;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = await initializeChatController();
    
    _controller!.operationsStream.listen((operation) {
      setState(() {});
    });

    setState(() {});
  }

  Future<void> _loadOlderMessages() async {
    if (_controller == null || _isLoadingMore) return;

    final messages = _controller!.messages;
    if (messages.isEmpty) return;

    // Get the oldest message timestamp
    final oldestMessage = messages.first;
    final before = oldestMessage.createdAt;

    if (before == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final olderMessages = await _controller!.loadOlderMessages(
        before: before,
        limit: 20,
      );

      debugPrint('Loaded ${olderMessages.length} older messages');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paginated Chat')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Load more when scrolling to top
          if (notification.metrics.pixels == 0) {
            _loadOlderMessages();
          }
          return false;
        },
        child: ListView.builder(
          reverse: true, // Show newest at bottom
          itemCount: _controller!.messages.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && _isLoadingMore) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading older messages...'),
              );
            }

            final actualIndex = _isLoadingMore ? index - 1 : index;
            final messageIndex = _controller!.messages.length - 1 - actualIndex;
            
            if (messageIndex < 0) return const SizedBox.shrink();

            final message = _controller!.messages[messageIndex];
            // Get text based on message type
            String text = '';
            if (message is TextMessage) {
              text = message.text;
            } else if (message is SystemMessage) {
              text = message.text;
            } else {
              text = '[${message.runtimeType}]';
            }
            return ListTile(
              title: Text(text),
              subtitle: Text(message.authorId),
            );
          },
        ),
      ),
    );
  }
}

/// Example: Using reactions
class ChatWithReactionsExample extends StatefulWidget {
  ChatWithReactionsExample({super.key});

  @override
  State<ChatWithReactionsExample> createState() => _ChatWithReactionsExampleState();
}

class _ChatWithReactionsExampleState extends State<ChatWithReactionsExample> {
  DuckDBChatController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = DuckDBChatController(
      messageRepository: MessageRepository(ChatDatabaseService()),
      userRepository: UserRepository(ChatDatabaseService()),
    );
  }

  Future<void> toggleReaction(String messageId, String userId) async {
    if (_controller == null) return;
    
    // Toggle thumbs up reaction
    final message = _controller!.messages.firstWhere((m) => m.id == messageId);
    final hasReaction = message.reactions?['👍']?.contains(userId) ?? false;

    if (hasReaction) {
      await _controller!.removeReaction(messageId, userId, '👍');
    } else {
      await _controller!.addReaction(messageId, userId, '👍');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// Example: Search messages
class ChatSearchExample extends StatefulWidget {
  const ChatSearchExample({super.key});

  @override
  State<ChatSearchExample> createState() => _ChatSearchExampleState();
}

class _ChatSearchExampleState extends State<ChatSearchExample> {
  DuckDBChatController? _controller;
  List<Message> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = await initializeChatController();
    setState(() {});
  }

  Future<void> _searchMessages(String query) async {
    if (_controller == null) return;

    final results = await _controller!.searchMessages(query, limit: 20);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _searchMessages,
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final message = _searchResults[index];
              // Get text content based on message type
              String text = '';
              if (message is TextMessage) {
                text = message.text;
              } else if (message is SystemMessage) {
                text = message.text;
              } else if (message is ImageMessage) {
                text = message.text ?? '[Image]';
              } else if (message is FileMessage) {
                text = '[File: ${message.name}]';
              } else if (message is VideoMessage) {
                text = message.text ?? '[Video]';
              } else if (message is AudioMessage) {
                text = message.text ?? '[Audio]';
              } else {
                text = '[${message.runtimeType}]';
              }
              return ListTile(
                title: Text(text),
                subtitle: Text(message.authorId),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Example: Dependency Injection setup
class DependencyInjectionExample {
  static late DuckDBChatController _chatController;

  static Future<void> initialize() async {
    // Initialize database
    final dbPath = await DatabasePathProvider.getDatabasePath();
    final database = ChatDatabaseService(dbPath: dbPath);
    await database.initialize();

    // Create controller
    _chatController = DuckDBChatController(
      messageRepository: MessageRepository(database),
      userRepository: UserRepository(database),
    );

    // Load initial messages
    await _chatController.loadMessages(limit: 50);
  }

  static DuckDBChatController get chatController => _chatController;
}
