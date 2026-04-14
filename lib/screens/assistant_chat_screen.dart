/// Tab-specific assistant chat screen.
///
/// Opens a chat with the assistant relevant to the current tab.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../services/hybrid_ai_service.dart';
import 'assistants/assistant_base.dart';
import 'assistants/assistant_manager.dart';

/// Chat screen for a specific tab's assistant.
class AssistantChatScreen extends StatefulWidget {
  final AssistantConfig assistant;
  final HybridAIService? aiService;

  const AssistantChatScreen({
    super.key,
    required this.assistant,
    this.aiService,
  });

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  late final InMemoryChatController _chatController;
  late final AssistantConfig _assistant;
  HybridAIService? _hybridService;
  bool _isProcessing = false;
  bool _isInitializing = false;
  double _downloadProgress = 0.0;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _assistant = widget.assistant;
    _chatController = InMemoryChatController();
    _initService();
    unawaited(_sendWelcomeMessage());
  }

  Future<void> _initService() async {
    setState(() => _isInitializing = true);

    try {
      _hybridService = widget.aiService ?? HybridAIService(cloudApiKey: null);
      await _hybridService!.initialize(
        onDownloadProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress);
        },
      );
    } catch (e) {
      debugPrint('[${_assistant.name}] Init failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final welcomeId = _uuid.v4();
    final welcomeMsg = Message.text(
      id: welcomeId,
      authorId: 'ai',
      text: _assistant.welcomeMessage,
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(welcomeMsg);
  }

  Future<void> _handleMessageSend(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    if (_isInitializing) {
      await _sendErrorMessage(
        'AI masih disiapkan. Tunggu sebentar lalu coba lagi.',
      );
      return;
    }

    final service = _hybridService;
    if (service == null) {
      await _sendErrorMessage('Service AI belum siap.');
      return;
    }

    if (!service.isLocalAIReady && !service.hasCloudAI) {
      await _sendErrorMessage('AI lokal belum siap. Coba lagi beberapa saat.');
      return;
    }

    // Save user message
    final userId = _uuid.v4();
    final userMsg = Message.text(
      id: userId,
      authorId: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(userMsg);

    await _generateResponse(text.trim());
  }

  Future<void> _generateResponse(String userMessage) async {
    if (_hybridService == null) {
      await _sendErrorMessage('Service belum terinisialisasi.');
      return;
    }

    setState(() => _isProcessing = true);

    final streamId = _uuid.v4();
    final streamMsg = Message.textStream(
      id: streamId,
      authorId: 'ai',
      streamId: streamId,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    await _chatController.insertMessage(streamMsg);

    try {
      final response = await _hybridService!.generateLocalResponse(
        prompt: userMessage,
        systemPrompt: _assistant.systemPrompt,
      );

      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: response,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, finalMsg);
    } catch (e) {
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: '❌ Maaf, terjadi kesalahan: $e',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendErrorMessage(String error) async {
    final errorId = _uuid.v4();
    final errorMsg = Message.text(
      id: errorId,
      authorId: 'ai',
      text: error,
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(errorMsg);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _hybridService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_assistant.icon, size: 20, color: _assistant.themeColor),
            const SizedBox(width: 8),
            Text(_assistant.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips
          if (!_isProcessing && !_isInitializing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _assistant.quickActions
                    .map(
                      (action) => ActionChip(
                        label: Text(action),
                        avatar: Icon(_assistant.icon, size: 16),
                        onPressed: () => _handleMessageSend(action),
                      ),
                    )
                    .toList(),
              ),
            ),
          // Chat UI
          Expanded(
            child: Chat(
              currentUserId: 'user',
              resolveUser: _resolveUser,
              chatController: _chatController,
              builders: _buildBuilders(),
              onMessageSend: _handleMessageSend,
            ),
          ),
        ],
      ),
    );
  }

  Future<User?> _resolveUser(UserID userId) async {
    return User(
      id: userId,
      name: userId == 'ai' ? _assistant.name : 'Kamu',
    );
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder: (context, message, index,
          {isSentByMe = false, groupStatus}) {
        return FlyerChatTextMessage(
          message: message,
          index: index,
          onLinkTap: (url, title) {},
        );
      },
      textStreamMessageBuilder: (context, message, index,
          {isSentByMe = false, groupStatus}) {
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: const StreamStateStreaming(''),
        );
      },
    );
  }

  void _resetChat() {
    _chatController.dispose();
    _chatController = InMemoryChatController();
    _sendWelcomeMessage();
  }
}

/// Helper to open the assistant chat for a given tab index.
void openAssistantChat({
  required BuildContext context,
  required int tabIndex,
  HybridAIService? aiService,
}) {
  final assistant = AssistantManager.getAssistantForTab(tabIndex);
  if (assistant == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AssistantChatScreen(
        assistant: assistant,
        aiService: aiService,
      ),
    ),
  );
}
