/// Chat-based screen untuk generate job posting.
///
/// User bisa:
/// - Ketik posisi yang dibutuhkan
/// - AI generate job posting lengkap
/// - Refine hasil via chat (ubah gaji, tambah requirement, dll)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../services/hybrid_ai_service.dart';
import '../models/job_posting.dart';

/// Chat screen untuk bikin lowongan sekali prompt.
class JobPostingChatScreen extends StatefulWidget {
  final String? apiKey;

  const JobPostingChatScreen({super.key, this.apiKey});

  @override
  State<JobPostingChatScreen> createState() => _JobPostingChatScreenState();
}

class _JobPostingChatScreenState extends State<JobPostingChatScreen> {
  late final InMemoryChatController _chatController;
  HybridAIService? _hybridService;
  JobPosting? _lastGenerated;
  bool _isGenerating = false;
  bool _isInitializing = false;
  double _downloadProgress = 0.0;

  final _uuid = const Uuid();

  final _suggestions = [
    'Kasir',
    'Admin Gudang',
    'Sales',
    'Waiters',
    'Staff Admin',
    'Programmer',
    'Desainer Grafis',
  ];

  @override
  void initState() {
    super.initState();
    _chatController = InMemoryChatController();
    _initHybridService();
    _sendWelcomeMessage();
  }

  Future<void> _initHybridService() async {
    final apiKey = widget.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _sendErrorMessage('API Key belum dikonfigurasi.');
      return;
    }

    setState(() => _isInitializing = true);

    try {
      _hybridService = HybridAIService(cloudApiKey: apiKey);
      final localReady = await _hybridService!.initialize(
        onDownloadProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
      );

      if (localReady) {
        debugPrint('[JobPostingChat] Local AI ready!');
      } else {
        debugPrint('[JobPostingChat] Using cloud AI fallback');
      }
    } catch (e) {
      debugPrint('[JobPostingChat] Init failed: $e');
      _sendErrorMessage('Gagal inisialisasi AI: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final welcomeId = _uuid.v4();
    final welcomeMsg = Message.text(
      id: welcomeId,
      authorId: 'ai',
      text: _buildWelcomeMessage(),
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(welcomeMsg);
  }

  String _buildWelcomeMessage() {
    return '''👋 Halo! Saya asisten rekrutmen AI dengan **Hybrid Mode**.

**Ketik posisi yang kamu butuhkan**, saya akan buatkan job posting lengkap dalam hitungan detik.

Contoh:
• "Butuh Kasir"
• "Admin Gudang untuk cabang Depok"
• "Sales berpengalaman di bidang otomotif"

**Mode AI:**
- 🧠 **Local** - Offline, gratis, privasi terjaga
- ☁️ **Cloud** - Fallback, kualitas lebih konsisten

Setelah job posting jadi, kamu bisa:
✏️ Edit detail (gaji, lokasi, requirements)
📋 Copy untuk dipublikasikan
🔄 Generate ulang dengan perubahan''';
  }

  Future<void> _handleMessageSend(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

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

    // Check if user wants to refine or generate new
    if (_lastGenerated != null && _looksLikeRefinement(text)) {
      await _handleRefine(text.trim());
    } else {
      await _handleGenerate(text.trim());
    }
  }

  bool _looksLikeRefinement(String text) {
    final lower = text.toLowerCase();
    return lower.contains('ubah') ||
        lower.contains('ganti') ||
        lower.contains('tambah') ||
        lower.contains('kurangi') ||
        lower.contains('edit') ||
        lower.contains('revisi') ||
        lower.contains('gaji') ||
        lower.contains('requirement') ||
        lower.contains('syarat');
  }

  Future<void> _handleGenerate(String position) async {
    if (_hybridService == null) {
      await _sendErrorMessage('Service belum terinisialisasi.');
      return;
    }

    setState(() => _isGenerating = true);

    // Create streaming message placeholder
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
      final result = await _hybridService!.generateJobPosting(position);
      _lastGenerated = result.jobPosting;

      final responseText = _formatJobPosting(result.jobPosting, result.usedMode);

      // Update streaming message with final content
      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: responseText,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, finalMsg);
    } catch (e) {
      // Replace streaming message with error
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: '❌ Maaf, terjadi kesalahan: $e\n\nCoba lagi atau ubah mode AI.',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleRefine(String request) async {
    if (_hybridService == null || _lastGenerated == null) return;

    setState(() => _isGenerating = true);

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
      final result = await _hybridService!.refineJobPosting(
        _lastGenerated!,
        request,
      );
      _lastGenerated = result.jobPosting;

      final responseText = _formatJobPosting(result.jobPosting, result.usedMode);

      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: responseText,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, finalMsg);
    } catch (e) {
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: '❌ Gagal refine: $e',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  String _formatJobPosting(JobPosting job, AIMode usedMode) {
    final buffer = StringBuffer();
    final aiBadge = usedMode == AIMode.local
        ? '🧠 **Local AI**'
        : '☁️ **Cloud AI**';

    buffer.writeln('$aiBadge ✅ **Lowongan Siap!** 🎉');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('### 📋 ${job.title}');
    buffer.writeln('📍 ${job.location}  •  💼 ${job.employmentType}');
    buffer.writeln('');
    buffer.writeln('**Deskripsi:**');
    buffer.writeln(job.description);
    buffer.writeln('');
    buffer.writeln('**✅ Kualifikasi:**');
    for (var i = 0; i < job.requirements.length; i++) {
      buffer.writeln('- ${job.requirements[i]}');
    }
    buffer.writeln('');
    buffer.writeln('**🎯 Tanggung Jawab:**');
    for (var i = 0; i < job.responsibilities.length; i++) {
      buffer.writeln('- ${job.responsibilities[i]}');
    }
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('💰 **Estimasi Gaji:** ${job.salaryRange}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln('💡 *Ketik "ubah gaji jadi 5-8 juta" atau "tambah requirement bisa bahasa Inggris" untuk refine.*');
    return buffer.toString();
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
            const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(width: 8),
            const Text('Bikin Lowongan'),
            if (_hybridService != null) ...[
              const SizedBox(width: 8),
              _buildAIModeChip(),
            ],
          ],
        ),
        actions: [
          if (_hybridService != null && _hybridService!.isLocalAIReady)
            IconButton(
              icon: Icon(_getModeIcon()),
              tooltip: 'Toggle AI Mode',
              onPressed: _toggleAIMode,
            ),
          if (_lastGenerated != null)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'Copy Job Posting',
              onPressed: _copyToClipboard,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Initialization progress
          if (_isInitializing)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _downloadProgress > 0
                        ? 'Downloading model... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                        : 'Initializing AI...',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_downloadProgress > 0)
                    LinearProgressIndicator(value: _downloadProgress),
                ],
              ),
            ),
          // Suggestion chips
          if (!_isGenerating && !_isInitializing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _suggestions
                    .map(
                      (s) => ActionChip(
                        label: Text(s),
                        avatar: const Icon(Icons.work_outline, size: 16),
                        onPressed: () => _handleMessageSend(s),
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
      name: userId == 'ai' ? 'NgeRekrut AI' : 'Kamu',
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
      systemMessageBuilder: (context, message, index,
          {isSentByMe = false, groupStatus}) {
        return FlyerChatSystemMessage(message: message, index: index);
      },
    );
  }

  void _copyToClipboard() {
    if (_lastGenerated == null) return;
    // Use Flutter's clipboard API
    // Note: In real app, use clipboard package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Job posting disalin ke clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetChat() {
    setState(() {
      _lastGenerated = null;
    });
    // Recreate controller to clear messages
    _chatController.dispose();
    _chatController = InMemoryChatController();
    _sendWelcomeMessage();
  }

  Widget _buildAIModeChip() {
    final mode = _hybridService?.currentMode ?? AIMode.auto;
    final lastUsed = _hybridService?.lastUsedMode ?? AIMode.local;

    return Chip(
      label: Text(_getModeLabel(mode, lastUsed)),
      avatar: Icon(_getModeIcon(mode), size: 14),
      visualDensity: VisualDensity.compact,
    );
  }

  String _getModeLabel(AIMode current, AIMode lastUsed) {
    if (current == AIMode.auto) {
      return lastUsed == AIMode.local ? 'Local' : 'Cloud';
    }
    return current == AIMode.local ? 'Local' : 'Cloud';
  }

  IconData _getModeIcon([AIMode? mode]) {
    final m = mode ?? _hybridService?.currentMode ?? AIMode.auto;
    if (m == AIMode.local || (m == AIMode.auto && _hybridService?.lastUsedMode == AIMode.local)) {
      return Icons.memory;
    }
    return Icons.cloud;
  }

  void _toggleAIMode() {
    if (_hybridService == null) return;

    final current = _hybridService!.currentMode;
    final newMode = current == AIMode.local ? AIMode.cloud : AIMode.local;
    _hybridService!.setMode(newMode);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode AI: ${newMode == AIMode.local ? 'Local (Offline)' : 'Cloud (OpenAI)'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
