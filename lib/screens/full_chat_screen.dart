/// Chat screen implementation with full integration of all chat libraries.
/// 
/// This screen demonstrates:
/// - DuckDB persistence via [DuckDBChatController]
/// - Text messages with markdown support
/// - System messages
/// - Text stream messages (for AI responses)
library;

import 'package:flutter/material.dart';
import '../data/data.dart';
import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_file_message/flyer_chat_file_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

/// Main chat screen widget with full library integration.
class FullChatScreen extends StatefulWidget {
  /// Current user ID for the chat session.
  final String currentUserId;

  /// Optional current user name.
  final String? currentUserName;

  /// Creates the full chat screen.
  const FullChatScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<FullChatScreen> createState() => _FullChatScreenState();
}

class _FullChatScreenState extends State<FullChatScreen> {
  late ChatDatabaseService _database;
  late DuckDBChatController _chatController;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Initialize database
      final dbPath = await DatabasePathProvider.getDatabasePath();
      _database = ChatDatabaseService(dbPath: dbPath);
      await _database.initialize();

      // Create repositories
      final messageRepository = MessageRepository(_database);
      final userRepository = UserRepository(_database);

      // Create controller with DuckDB persistence
      _chatController = DuckDBChatController(
        messageRepository: messageRepository,
        userRepository: userRepository,
      );

      // Save current user
      await _chatController.saveUser(
        User(
          id: widget.currentUserId,
          name: widget.currentUserName ?? 'User',
        ),
      );

      // Load existing messages
      await _chatController.loadMessages(limit: 50);

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final message = Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: widget.currentUserId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _chatController.insertMessage(message);
  }

  Future<void> _sendSystemMessage() async {
    final message = Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: 'system',
      text: 'System message: User joined the chat',
      createdAt: DateTime.now(),
    );

    await _chatController.insertMessage(message);
  }

  Future<void> _simulateStreamingResponse() async {
    // Create a streaming message placeholder
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    final streamMessage = Message.textStream(
      id: streamId,
      authorId: 'assistant',
      streamId: streamId,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    await _chatController.insertMessage(streamMessage);

    // Simulate streaming text
    final fullText = "This is a simulated AI response with **markdown** support:\n\n- Item 1\n- Item 2\n- Item 3\n\n```dart\nprint('Hello World');\n```";
    final words = fullText.split(' ');

    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final partialText = words.sublist(0, i + 1).join(' ');
      final updatedMessage = Message.text(
        id: streamId,
        authorId: 'assistant',
        text: partialText,
        createdAt: streamMessage.createdAt,
        status: MessageStatus.sending,
      );

      await _chatController.updateMessage(streamMessage, updatedMessage);
    }

    // Mark as complete
    final finalMessage = Message.text(
      id: streamId,
      authorId: 'assistant',
      text: fullText,
      createdAt: streamMessage.createdAt,
      status: MessageStatus.seen,
    );

    await _chatController.updateMessage(streamMessage, finalMessage);
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Send System Message'),
              onTap: () {
                Navigator.pop(context);
                _sendSystemMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Simulate AI Response'),
              onTap: () {
                Navigator.pop(context);
                _simulateStreamingResponse();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _error = null;
                  });
                  _initializeChat();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Chat Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _showMessageOptions,
            tooltip: 'Message Options',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Clear all messages by setting empty list
                // Note: This only clears UI, not database
                await _chatController.setMessages([]);
              }
            },
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Chat(
        currentUserId: widget.currentUserId,
        resolveUser: _resolveUser,
        chatController: _chatController,
        builders: _buildBuilders(),
        onMessageSend: _sendMessage,
        onMessageTap: (context, message, {required index, required details}) {
          debugPrint('Tapped message: ${message.id}');
        },
        onMessageLongPress: (context, message, {required index, required details}) {
          debugPrint('Long pressed message: ${message.id}');
          _showMessageActions(context, message);
        },
      ),
    );
  }

  Builders _buildBuilders() {
    return Builders(
      // Text message builder - uses FlyerChatTextMessage
      textMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatTextMessage(
          message: message,
          index: index,
          onLinkTap: (url, title) {
            debugPrint('Link tapped: $url');
          },
        );
      },
      
      // System message builder - uses FlyerChatSystemMessage
      systemMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatSystemMessage(
          message: message,
          index: index,
        );
      },
      
      // Text stream message builder - uses FlyerChatTextStreamMessage
      // Note: For a real implementation, you need to manage the stream state externally
      textStreamMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: const StreamStateStreaming(''),
        );
      },
      
      // File message builder - uses FlyerChatFileMessage
      fileMessageBuilder: (context, message, index, {isSentByMe = false, groupStatus}) {
        return FlyerChatFileMessage(
          message: message,
          index: index,
        );
      },
    );
  }

  Future<User?> _resolveUser(UserID userId) async {
    // Try to get from controller cache first
    try {
      return await _chatController.getUser(userId);
    } catch (e) {
      // Return default user if not found
      return User(
        id: userId,
        name: userId == 'system' ? 'System' : 'User',
      );
    }
  }

  void _showMessageActions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                // Implement reply functionality
              },
            ),
            if (message.pinned != true)
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('Pin'),
                onTap: () async {
                  Navigator.pop(context);
                  final updatedMessage = message.copyWith(pinned: true);
                  await _chatController.updateMessage(message, updatedMessage);
                },
              ),
            if (message.pinned == true)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('Unpin'),
                onTap: () async {
                  Navigator.pop(context);
                  final updatedMessage = message.copyWith(pinned: false);
                  await _chatController.updateMessage(message, updatedMessage);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _chatController.removeMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }
}
