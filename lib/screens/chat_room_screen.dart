library;

import 'package:flutter/material.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:ngerekrut/flutter_chat_ui/flutter_chat_ui.dart';
import 'package:ngerekrut/objectbox_store_provider.dart';

import '../flyer_chat_file_message/flyer_chat_file_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../models/chat_session_record.dart';
import '../repositories/chat_session_repository.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.session,
    this.currentUserId = 'recruiter_user',
  });

  final ChatSessionRecord session;
  final String currentUserId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatSessionRepository _sessionRepository = ChatSessionRepository();
  ObjectBoxChatController? _chatController;
  ChatSessionRecord? _session;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    ObjectBoxChatController? controller;
    try {
      await _sessionRepository.initialize();
      if (!ObjectBoxStoreProvider.isInitialized) {
        await ObjectBoxStoreProvider.initialize();
      }

      controller = ObjectBoxChatController(sessionId: widget.session.sessionId);
      await controller.loadMessages(limit: 100);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _chatController = controller;
        _session = _sessionRepository.ensureSession(widget.session.sessionId);
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

  Future<void> _handleSend(String text) async {
    final content = text.trim();
    if (content.isEmpty || _chatController == null) return;

    final message = Message.text(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      authorId: widget.currentUserId,
      text: content,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _chatController!.insertMessage(message);
    final session = _sessionRepository.recordMessage(
      widget.session.sessionId,
      content,
    );
    if (!mounted) return;
    setState(() => _session = session);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Recruiter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Recruiter')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Gagal membuka sesi chat.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isInitializing = true;
                    });
                    _initializeChat();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_session?.title ?? 'Chat Recruiter'),
            if (_session?.lastMessagePreview.isNotEmpty == true)
              Text(
                _session!.lastMessagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Chat(
        currentUserId: widget.currentUserId,
        resolveUser: _resolveUser,
        chatController: _chatController!,
        builders: _buildBuilders(),
        onMessageSend: _handleSend,
      ),
    );
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatTextMessage(
          message: message,
          index: index,
          onLinkTap: (url, title) {},
        );
      },
      systemMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatSystemMessage(message: message, index: index);
      },
      textStreamMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: const StreamStateStreaming(''),
        );
      },
      fileMessageBuilder: (
        context,
        message,
        index, {
        isSentByMe = false,
        groupStatus,
      }) {
        return FlyerChatFileMessage(message: message, index: index);
      },
    );
  }

  Future<User?> _resolveUser(UserID userId) async {
    return User(
      id: userId,
      name: userId == widget.currentUserId ? 'Anda' : 'Assistant',
    );
  }
}
