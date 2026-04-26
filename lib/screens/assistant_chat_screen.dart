/// Tab-specific assistant chat screen using LangChain.
///
/// Opens a chat with the assistant relevant to the current tab.
/// Uses LangChain's ConversationBufferMemory for conversation history.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../services/hybrid_ai_service.dart';
import '../langchain/chat_models/chat_models.dart' as lc;
import '../langchain/memory/memory.dart';
import '../langchain/chat_history/objectbox_chat_history.dart';
import '../ai/assistants/assistant_base.dart';
import '../ai/assistants/assistant_manager.dart';
import '../ai/assistants/assistant_context.dart';
import '../ai/assistants/langchain_adapter.dart';
import '../models/job_posting.dart';
import '../models/recruiter_job.dart';
import '../repositories/job_posting_repository.dart';

/// Chat screen for a specific tab's assistant.
class AssistantChatScreen extends StatefulWidget {
  final AssistantConfig assistant;
  final HybridAIService? aiService;

  /// Context data for the assistant (selected job, candidates, etc.)
  final AssistantContext? context;

  /// Optional session ID for persistent history.
  /// If null, a new session will be created.
  final String? sessionId;

  const AssistantChatScreen({
    super.key,
    required this.assistant,
    this.aiService,
    this.context,
    this.sessionId,
  });

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  static const _streamTextMetadataKey = 'streamText';
  static const _rakaDraftIdPrefix = 'raka_draft_';

  late InMemoryChatController _chatController;
  late AssistantConfig _assistant;
  late AssistantContext? _assistantContext;
  final JobPostingRepository _jobPostingRepository = JobPostingRepository();

  // LangChain components
  late HybridChatModel _chatModel;
  late ConversationBufferMemory _memory;

  // Whether this screen owns the AI service (should dispose on close)
  late bool _ownsService;

  bool _isProcessing = false;
  bool _isInitializing = false;
  String? _draftJobId;
  JobPosting? _activeRakaDraft;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _assistant = widget.assistant;
    _assistantContext = widget.context;
    _ownsService = widget.aiService == null;

    // Generate session ID if not provided
    final effectiveSessionId = widget.sessionId ??
        'assistant_${widget.assistant.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Initialize LangChain components with persistent history
    final service = widget.aiService ??
        HybridAIService(cloudApiKey: null);
    _chatModel = HybridChatModel(
      service: service,
      defaultSystemPrompt: _buildFullSystemPrompt(),
    );
    _memory = ConversationBufferMemory(
      chatHistory: ObjectBoxChatHistory(sessionId: effectiveSessionId),
      memoryKey: 'history',
      returnMessages: true,
    );

    _chatController = InMemoryChatController();
    _initService();
    unawaited(_loadPersistentHistory());
    unawaited(_sendWelcomeMessage());
  }

  /// Load existing conversation history from ObjectBox.
  Future<void> _loadPersistentHistory() async {
    final historyVars = await _memory.loadMemoryVariables();
    final historyMessages = historyVars['history'] as List<lc.ChatMessage>? ?? [];

    // Load messages into chat UI
    for (final msg in historyMessages) {
      final chatMsg = Message.text(
        id: _uuid.v4(),
        authorId: msg is lc.HumanChatMessage ? 'user' : 'ai',
        text: msg.contentAsString,
        createdAt: DateTime.now(),
        status: MessageStatus.seen,
      );
      await _chatController.insertMessage(chatMsg);
    }
  }

  String _buildFullSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(_assistant.systemPrompt);

    if (_assistantContext != null) {
      buffer.writeln(_assistantContext!.toSystemContext());
    }

    buffer.writeln('\nInstruksi tambahan:');
    buffer.writeln('- Gunakan konteks di atas untuk memberikan jawaban yang relevan dan spesifik.');
    buffer.writeln('- Jika ada data kandidat atau lowongan, referensi data tersebut dalam jawaban.');
    buffer.writeln('- Berikan saran yang actionable berdasarkan konteks yang ada.');
    buffer.writeln('- Ingat percakapan sebelumnya dan lanjutkan dari sana.');
    if (_assistant.id == 'raka') {
      buffer.writeln(
        '- Untuk permintaan lowongan, selalu prioritaskan membuat draft awal meskipun input user minim. Jangan berhenti hanya untuk meminta detail tambahan.',
      );
      buffer.writeln(
        '- Jika informasi belum lengkap, pakai asumsi default yang wajar lalu beri label asumsi secara singkat di jawaban.',
      );
      buffer.writeln(
        '- Gunakan format jawaban yang rapi dan konsisten: Asumsi Awal, Draft Lowongan, lalu Yang Bisa Disesuaikan.',
      );
      buffer.writeln(
        '- Untuk user non-recruiter, hindari jargon HR yang tidak perlu. Pilih bahasa yang mudah dipahami dan langsung operasional.',
      );
    }

    return buffer.toString();
  }

  Future<void> _initService() async {
    setState(() => _isInitializing = true);

    try {
      final service = _chatModel.service;
      await service.initialize(
        onDownloadProgress: (progress) {
          if (!mounted) return;
          setState(() {});
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

    final service = _chatModel.service;
    if (!service.isLocalAIReady && !service.hasCloudAI) {
      await _sendErrorMessage('AI lokal belum siap. Coba lagi beberapa saat.');
      return;
    }

    // Save user message to chat UI
    final userId = _uuid.v4();
    final userMsg = Message.text(
      id: userId,
      authorId: 'user',
      text: text.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(userMsg);

    if (_assistant.id == 'raka') {
      await _generateRakaResponse(text.trim());
      return;
    }

    await _generateResponse(text.trim());
  }

  Future<void> _generateResponse(String userMessage) async {
    setState(() => _isProcessing = true);

    final streamId = _uuid.v4();
    final streamMsg = Message.textStream(
      id: streamId,
      authorId: 'ai',
      streamId: streamId,
      createdAt: DateTime.now(),
      metadata: const {_streamTextMetadataKey: ''},
      status: MessageStatus.sending,
    ) as TextStreamMessage;
    await _chatController.insertMessage(streamMsg);

    try {
      // Use streaming response
      final stream = _chatModel.invokeWithStreaming(
        prompt: userMessage,
        systemPrompt: _buildFullSystemPrompt(),
      );

      var accumulatedResponse = '';
      var currentStreamMsg = streamMsg;

      await for (final chunk in stream) {
        accumulatedResponse += chunk;

        // Update streaming message with accumulated content
        currentStreamMsg = await _updateStreamMessage(
          currentStreamMsg,
          accumulatedResponse,
        );
      }

      // Final message (replace streaming with complete text)
      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: accumulatedResponse,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(currentStreamMsg, finalMsg);

      // FIX #2: Use correct LangChain memory keys (input/output, not history)
      await _memory.saveContext(
        inputValues: {'input': userMessage},
        outputValues: {'output': accumulatedResponse},
      );
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

  Future<TextStreamMessage> _updateStreamMessage(
    TextStreamMessage currentMessage,
    String accumulatedText,
  ) async {
    final updatedMessage = Message.textStream(
      id: currentMessage.id,
      authorId: currentMessage.authorId,
      streamId: currentMessage.streamId,
      createdAt: currentMessage.createdAt,
      metadata: {_streamTextMetadataKey: accumulatedText},
      status: MessageStatus.sending,
    ) as TextStreamMessage;
    await _chatController.updateMessage(currentMessage, updatedMessage);
    return updatedMessage;
  }

  Future<void> _persistRakaDraft(JobPosting posting) async {
    final draftJobId =
        _draftJobId ?? '$_rakaDraftIdPrefix${DateTime.now().millisecondsSinceEpoch}';
    final draft = RecruiterJob(
      id: draftJobId,
      title: posting.title,
      unitLabel: null,
      location: posting.location,
      description:
          '${posting.description}\n\nTanggung jawab:\n- ${posting.responsibilities.join('\n- ')}\n\nNilai tambah:\n- Belum dicatat terpisah dari jawaban Raka.\n\nEstimasi gaji: ${posting.salaryRange}\nTipe kerja: ${posting.employmentType}',
      requirements: posting.requirements,
      status: JobPostingRepository.statusDraft,
    );

    final existing = await _jobPostingRepository.getByJobId(draftJobId);
    if (existing == null) {
      await _jobPostingRepository.create(draft);
    } else {
      await _jobPostingRepository.update(draft);
    }

    if (!mounted) return;
    setState(() {
      _draftJobId = draftJobId;
      _activeRakaDraft = posting;
    });
  }

  Future<void> _generateRakaResponse(String userMessage) async {
    setState(() => _isProcessing = true);
    final isFirstDraft = _activeRakaDraft == null;

    final streamId = _uuid.v4();
    final streamMsg = Message.textStream(
      id: streamId,
      authorId: 'ai',
      streamId: streamId,
      createdAt: DateTime.now(),
      metadata: const {_streamTextMetadataKey: ''},
      status: MessageStatus.sending,
    ) as TextStreamMessage;
    await _chatController.insertMessage(streamMsg);

    try {
      var currentStreamMsg = streamMsg;
      final progressTicker = _startProgressTicker(
        initialMessage: streamMsg,
        updates: _activeRakaDraft == null
            ? const [
                'Raka sedang menyusun draft lowongan awal...',
                'Menentukan asumsi default yang paling masuk akal...',
                'Merapikan requirement dan tanggung jawab...',
                'Menyiapkan draft lowongan yang bisa langsung direvisi...',
              ]
            : const [
                'Raka sedang merevisi draft lowongan aktif...',
                'Menyesuaikan isi sesuai arahan terbaru...',
                'Merapikan ulang detail lowongan...',
                'Menyiapkan versi revisi yang terbaru...',
              ],
        onMessageUpdated: (message) => currentStreamMsg = message,
      );

      final result = _activeRakaDraft == null
          ? await _chatModel.service.generateJobPosting(userMessage)
          : await _chatModel.service.refineJobPosting(
              _activeRakaDraft!,
              userMessage,
            );
      await progressTicker.cancel();

      await _persistRakaDraft(result.jobPosting);

      final responseText = _formatRakaJobPostingResponse(
        result,
        isFirstDraft: isFirstDraft,
      );
      currentStreamMsg = await _streamTextResponse(
        initialMessage: currentStreamMsg,
        finalText: responseText,
      );

      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: responseText,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(currentStreamMsg, finalMsg);

      await _memory.saveContext(
        inputValues: {'input': userMessage},
        outputValues: {'output': responseText},
      );
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

  _ProgressTicker _startProgressTicker({
    required TextStreamMessage initialMessage,
    required List<String> updates,
    required void Function(TextStreamMessage) onMessageUpdated,
  }) {
    var currentMessage = initialMessage;
    var updateIndex = 0;
    var cancelled = false;

    final loop = () async {
      if (updates.isEmpty) return;
      while (!cancelled && mounted) {
        currentMessage = await _updateStreamMessage(
          currentMessage,
          updates[updateIndex],
        );
        onMessageUpdated(currentMessage);
        updateIndex = (updateIndex + 1) % updates.length;
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }();

    return _ProgressTicker(
      cancel: () async {
        cancelled = true;
        await loop;
      },
    );
  }

  Future<TextStreamMessage> _streamTextResponse({
    required TextStreamMessage initialMessage,
    required String finalText,
  }) async {
    var currentMessage = initialMessage;
    var accumulatedText = '';

    for (final chunk in _splitIntoStreamChunks(finalText)) {
      accumulatedText += chunk;
      currentMessage = await _updateStreamMessage(currentMessage, accumulatedText);
      await Future.delayed(const Duration(milliseconds: 18));
    }

    return currentMessage;
  }

  List<String> _splitIntoStreamChunks(String text) {
    final chunks = <String>[];
    final pattern = RegExp(r'.{1,12}(?:\s+|$)', dotAll: true);
    for (final match in pattern.allMatches(text)) {
      final chunk = match.group(0);
      if (chunk != null && chunk.isNotEmpty) {
        chunks.add(chunk);
      }
    }
    if (chunks.isEmpty && text.isNotEmpty) {
      chunks.add(text);
    }
    return chunks;
  }

  String _formatRakaJobPostingResponse(
    GenerationResult result, {
    required bool isFirstDraft,
  }) {
    final job = result.jobPosting;
    final modeLabel = result.usedMode == AIMode.local
        ? '🧠 **Diproses di perangkat**'
        : '☁️ **Diproses online**';
    final buffer = StringBuffer()
      ..writeln(modeLabel)
      ..writeln(isFirstDraft ? '✅ **Draft Lowongan Awal**' : '✅ **Draft Lowongan Diperbarui**')
      ..writeln('')
      ..writeln('**Asumsi Awal**')
      ..writeln(
        'Jika Anda belum memberi detail lengkap, Raka memakai asumsi default yang aman: lokasi Jakarta, tipe kerja Full-time, dan requirement tingkat menengah umum.',
      )
      ..writeln('')
      ..writeln('**Draft Lowongan**')
      ..writeln('- Judul Posisi: ${job.title}')
      ..writeln('- Lokasi: ${job.location}')
      ..writeln('- Tipe Kerja: ${job.employmentType}')
      ..writeln('- Estimasi Gaji: ${job.salaryRange}')
      ..writeln('')
      ..writeln('**Ringkasan Posisi**')
      ..writeln(job.description)
      ..writeln('')
      ..writeln('**Tanggung Jawab**');

    for (final item in job.responsibilities) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('')
      ..writeln('**Kualifikasi**');
    for (final item in job.requirements) {
      buffer.writeln('- $item');
    }

    buffer
      ..writeln('')
      ..writeln('**Yang Bisa Disesuaikan**')
      ..writeln('- Lokasi kerja')
      ..writeln('- Range gaji')
      ..writeln('- Pengalaman minimum')
      ..writeln('- Jam kerja atau jenis industrinya');

    return buffer.toString();
  }

  @override
  void dispose() {
    _chatController.dispose();
    // FIX #5: Only dispose service if we created it here (not shared from home screen)
    if (_ownsService) {
      _chatModel.service.dispose();
    }
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
        final streamText =
            message.metadata?[_streamTextMetadataKey] as String? ?? '';
        return FlyerChatTextStreamMessage(
          message: message,
          index: index,
          streamState: StreamStateStreaming(streamText),
        );
      },
    );
  }

  // FIX #1: Reset chat without reassigning final fields
  // Instead of recreating components, just clear memory and reload
  Future<void> _resetChat() async {
    await _memory.clear();
    _chatController.dispose();
    _chatController = InMemoryChatController();
    unawaited(_sendWelcomeMessage());
  }
}

class _ProgressTicker {
  final Future<void> Function() cancel;

  const _ProgressTicker({required this.cancel});
}

/// Helper to open the assistant chat for a given tab index.
void openAssistantChat({
  required BuildContext context,
  required int tabIndex,
  HybridAIService? aiService,
  AssistantContext? assistantContext,
  String? sessionId,
}) {
  final assistant = AssistantManager.getAssistantForTab(tabIndex);
  if (assistant == null) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AssistantChatScreen(
        assistant: assistant,
        aiService: aiService,
        context: assistantContext,
        sessionId: sessionId,
      ),
    ),
  );
}
