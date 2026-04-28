/// Chat screen implementation with full integration of all chat libraries.
///
/// This screen demonstrates:
/// - ObjectBox persistence via [ObjectBoxChatController]
/// - Text messages with markdown support
/// - System messages
/// - Text stream messages (for AI responses)
/// - Vector search for semantic message search
library;

import 'package:flutter/material.dart';
import 'package:ngerekrut/objectbox_store_provider.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:ngerekrut/flutter_chat_ui/flutter_chat_ui.dart';

import '../flyer_chat_file_message/flyer_chat_file_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';

// Import LangChain untuk persistence
import 'package:ngerekrut/langchain/langchain.dart' as ai;

/// Main chat screen widget with full library integration.
class FullChatScreen extends StatefulWidget {
  /// Current user ID for the chat session.
  final String currentUserId;

  /// Session ID for the chat.
  final String sessionId;

  /// Optional current user name.
  final String? currentUserName;

  /// Creates the full chat screen.
  const FullChatScreen({
    super.key,
    required this.currentUserId,
    required this.sessionId,
    this.currentUserName,
  });

  @override
  State<FullChatScreen> createState() => _FullChatScreenState();
}

class _FullChatScreenState extends State<FullChatScreen> {
  static const _streamTextMetadataKey = 'streamText';

  ObjectBoxChatController? _chatController;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    ObjectBoxChatController? controller;
    try {
      // Initialize ObjectBox
      if (!ObjectBoxStoreProvider.isInitialized) {
        await ObjectBoxStoreProvider.initialize();
      }

      // Create controller with sessionId
      controller = ObjectBoxChatController(
        sessionId: widget.sessionId,
      );

      // Load existing messages
      await controller.loadMessages(limit: 50);

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _chatController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      controller?.dispose();
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _chatController?.dispose();
    super.dispose();
  }

  Future<void> _sendSystemMessage() async {
    final message = Message.system(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: 'system',
      text: 'System message: User joined the chat',
      createdAt: DateTime.now(),
    );

    await _chatController?.insertMessage(message);
  }

  Future<void> _simulateStreamingResponse() async {
    // Create a streaming message placeholder
    final streamId = DateTime.now().millisecondsSinceEpoch.toString();
    final streamMessage = Message.textStream(
      id: streamId,
      authorId: 'assistant',
      streamId: streamId,
      createdAt: DateTime.now(),
      metadata: const {_streamTextMetadataKey: ''},
      status: MessageStatus.sending,
    );

    await _chatController?.insertMessage(streamMessage);
    var currentStreamMessage = streamMessage;

    // Simulate streaming text
    final fullText = "This is a simulated AI response with **markdown** support:\n\n- Item 1\n- Item 2\n- Item 3\n\n```dart\nprint('Hello World');\n```";
    final words = fullText.split(' ');

    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      final partialText = words.sublist(0, i + 1).join(' ');
      final updatedMessage = Message.textStream(
        id: streamId,
        authorId: 'assistant',
        streamId: streamId,
        createdAt: streamMessage.createdAt,
        metadata: {_streamTextMetadataKey: partialText},
        status: MessageStatus.sending,
      ) as TextStreamMessage;

      await _chatController?.updateMessage(currentStreamMessage, updatedMessage);
      currentStreamMessage = updatedMessage;
    }

    // Mark as complete
    final finalMessage = Message.text(
      id: streamId,
      authorId: 'assistant',
      text: fullText,
      createdAt: streamMessage.createdAt,
      status: MessageStatus.seen,
    );

    await _chatController?.updateMessage(currentStreamMessage, finalMessage);
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
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Chat History'),
              onTap: () {
                Navigator.pop(context);
                _showChatHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChatHistory() {
    final messages = ai.ChatMessageQuery.fromSession(widget.sessionId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chat History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final prefix = switch (msg) {
                            ai.SystemChatMessage() => 'System',
                            ai.HumanChatMessage() => 'You',
                            ai.AIChatMessage() => 'AI',
                            ai.ToolChatMessage() => 'Tool',
                            ai.CustomChatMessage() => 'Custom',
                          };
                          return ListTile(
                            leading: Text(prefix[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                            title: Text(msg.contentAsString),
                            subtitle: Text(msg.runtimeType.toString()),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
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
                ai.ChatMessageQuery.deleteSession(widget.sessionId);
                await _chatController?.loadMessages(limit: 50);
                setState(() {});
              }
            },
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Chat(
        currentUserId: widget.currentUserId,
        resolveUser: _resolveUser,
        chatController: _chatController!,
        builders: _buildBuilders(),
        onMessageSend: (text) async {
          // Save via ChatMessagePersist
          ai.ChatMessage.humanText(text).save(widget.sessionId);
        },
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
        final streamText =
            message.metadata?[_streamTextMetadataKey] as String? ?? '';
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: StreamStateStreaming(streamText),
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
    // Return default user
    return User(
      id: userId,
      name: userId == 'system' ? 'System' : (userId == 'ai' ? 'AI Assistant' : 'User'),
    );
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
                  await _chatController?.updateMessage(message, updatedMessage);
                },
              ),
            if (message.pinned == true)
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('Unpin'),
                onTap: () async {
                  Navigator.pop(context);
                  final updatedMessage = message.copyWith(pinned: false);
                  await _chatController?.updateMessage(message, updatedMessage);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _chatController?.removeMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }
}
