/// Chat-based screen untuk generate job posting.
///
/// User bisa:
/// - Ketik posisi yang dibutuhkan
/// - AI generate job posting lengkap
/// - Refine hasil via chat (ubah gaji, tambah requirement, dll)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../flutter_chat_core/flutter_chat_core.dart';
import '../flutter_chat_ui/flutter_chat_ui.dart';
import '../flyer_chat_text_message/flyer_chat_text_message.dart';
import '../flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import '../flyer_chat_system_message/flyer_chat_system_message.dart';
import '../models/job_posting.dart';
import '../models/recruiter_job.dart';
import '../repositories/local_job_post_repository.dart';
import '../services/hybrid_ai_service.dart';

/// Chat screen untuk bikin lowongan sekali prompt.
class JobPostingChatScreen extends StatefulWidget {
  final String? apiKey;
  final HybridAIService? aiService;

  const JobPostingChatScreen({super.key, this.apiKey, this.aiService});

  @override
  State<JobPostingChatScreen> createState() => _JobPostingChatScreenState();
}

class _JobPostingChatScreenState extends State<JobPostingChatScreen> {
  late final InMemoryChatController _chatController;
  final LocalJobPostRepository _jobPostRepository = LocalJobPostRepository();
  HybridAIService? _hybridService;
  JobPosting? _lastGenerated;
  bool _isGenerating = false;
  bool _isInitializing = false;
  bool _isSaving = false;
  bool _isSavedLocally = false;
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
    unawaited(_initHybridService());
    unawaited(_sendWelcomeMessage());
  }

  Future<void> _initHybridService() async {
    final apiKey = widget.apiKey;
    setState(() => _isInitializing = true);

    try {
      _hybridService = widget.aiService ?? HybridAIService(cloudApiKey: apiKey);
      final localReady = await _hybridService!.initialize(
        onDownloadProgress: (progress) {
          setState(() => _downloadProgress = progress);
        },
      );

      if (localReady) {
        debugPrint('[JobPostingChat] Local AI ready!');
        if (!(_hybridService?.hasCloudAI ?? false)) {
          debugPrint(
            '[JobPostingChat] Cloud AI not configured, using local-only mode',
          );
        }
      } else {
        debugPrint('[JobPostingChat] Using cloud AI fallback');
      }
    } catch (e) {
      debugPrint('[JobPostingChat] Init failed: $e');
      await _sendErrorMessage('Gagal inisialisasi AI: $e');
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
    return '''Halo, saya bantu Anda menyusun lowongan dengan cepat.

Ketik posisi yang Anda butuhkan, lalu saya siapkan draft lowongannya.

Contoh:
• "Butuh Kasir"
• "Admin Gudang untuk cabang Depok"
• "Sales berpengalaman di bidang otomotif"

Setelah lowongan jadi, Anda bisa:
• revisi detail yang kurang pas
• simpan ke daftar lowongan
• salin untuk dipublikasikan''';
  }

  Future<void> _handleMessageSend(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;

    if (_isInitializing) {
      await _sendErrorMessage(
        'Bantuan AI masih disiapkan. Tunggu sampai proses selesai lalu coba lagi.',
      );
      return;
    }

    final service = _hybridService;
    if (service == null) {
      await _sendErrorMessage('Service AI belum siap.');
      return;
    }

    if (!service.isLocalAIReady && !service.hasCloudAI) {
      final reason = service.localAIErrorMessage;
      await _sendErrorMessage(
        reason == null || reason.isEmpty
            ? 'Bantuan AI belum siap. Coba lagi beberapa saat lagi.'
            : 'Bantuan AI belum siap: $reason',
      );
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
      _isSavedLocally = false;

      final responseText = _formatJobPosting(
        result.jobPosting,
        result.usedMode,
      );

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
      _isSavedLocally = false;

      final responseText = _formatJobPosting(
        result.jobPosting,
        result.usedMode,
      );

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
        ? '🧠 **Diproses di perangkat**'
        : '☁️ **Diproses online**';

    buffer.writeln(aiBadge);
    buffer.writeln('✅ **Lowongan Siap**');
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
    buffer.writeln(
      '📌 **Langkah berikutnya:** simpan lowongan ini, copy untuk publikasi, atau ketik revisi untuk perbaikan.',
    );
    return buffer.toString();
  }

  Future<void> _saveJobPosting() async {
    final job = _lastGenerated;
    if (job == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final savedJob = RecruiterJob(
        id: 'local_job_${DateTime.now().millisecondsSinceEpoch}',
        title: job.title,
        department: null,
        location: job.location,
        description:
            '${job.description}\n\nTanggung jawab:\n- ${job.responsibilities.join('\n- ')}\n\nEstimasi gaji: ${job.salaryRange}\nTipe kerja: ${job.employmentType}',
        requirements: job.requirements,
        status: 'draft',
      );
      await _jobPostRepository.save(savedJob);
      if (!mounted) return;
      setState(() => _isSavedLocally = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lowongan berhasil disimpan ke daftar lokal.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan lowongan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
              tooltip: 'Ganti mode proses',
              onPressed: _toggleAIMode,
            ),
          if (_lastGenerated != null)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'Salin lowongan',
              onPressed: _copyToClipboard,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Mulai ulang percakapan',
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
                        ? 'Menyiapkan model... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                        : 'Menyiapkan bantuan AI...',
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
          if (_lastGenerated != null && !_isInitializing)
            _GeneratedJobActionPanel(
              job: _lastGenerated!,
              isSavedLocally: _isSavedLocally,
              isSaving: _isSaving,
              onSave: _saveJobPosting,
              onCopy: _copyToClipboard,
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
    return User(id: userId, name: userId == 'ai' ? 'NgeRekrut AI' : 'Kamu');
  }

  Builders _buildBuilders() {
    return Builders(
      textMessageBuilder:
          (context, message, index, {isSentByMe = false, groupStatus}) {
            return FlyerChatTextMessage(
              message: message,
              index: index,
              onLinkTap: (url, title) {},
            );
          },
      textStreamMessageBuilder:
          (context, message, index, {isSentByMe = false, groupStatus}) {
            return FlyerChatTextStreamMessage(
              message: message,
              index: index,
              streamState: const StreamStateStreaming(''),
            );
          },
      systemMessageBuilder:
          (context, message, index, {isSentByMe = false, groupStatus}) {
            return FlyerChatSystemMessage(message: message, index: index);
          },
    );
  }

  Future<void> _copyToClipboard() async {
    if (_lastGenerated == null) return;
    await Clipboard.setData(
      ClipboardData(text: _lastGenerated!.toDisplayText()),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lowongan disalin ke clipboard.'),
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
    final hasCloudAI = _hybridService?.hasCloudAI ?? false;

    return Chip(
      label: Text(_getModeLabel(mode, lastUsed, hasCloudAI)),
      avatar: Icon(_getModeIcon(mode), size: 14),
      visualDensity: VisualDensity.compact,
    );
  }

  String _getModeLabel(AIMode current, AIMode lastUsed, bool hasCloudAI) {
    if (current == AIMode.auto) {
      if (!hasCloudAI) return 'Perangkat';
      return lastUsed == AIMode.local ? 'Perangkat' : 'Online';
    }
    if (current == AIMode.cloud && !hasCloudAI) {
      return 'Perangkat';
    }
    return current == AIMode.local ? 'Perangkat' : 'Online';
  }

  IconData _getModeIcon([AIMode? mode]) {
    final m = mode ?? _hybridService?.currentMode ?? AIMode.auto;
    if (m == AIMode.local ||
        (m == AIMode.auto && _hybridService?.lastUsedMode == AIMode.local)) {
      return Icons.memory;
    }
    return Icons.cloud;
  }

  void _toggleAIMode() {
    if (_hybridService == null) return;

    final current = _hybridService!.currentMode;
    final hasCloudAI = _hybridService!.hasCloudAI;
    final newMode = hasCloudAI
        ? (current == AIMode.local ? AIMode.cloud : AIMode.local)
        : AIMode.local;
    _hybridService!.setMode(newMode);
    setState(() {});

    final modeText = hasCloudAI
        ? (newMode == AIMode.local ? 'Perangkat' : 'Online')
        : 'Perangkat';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode proses: $modeText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _GeneratedJobActionPanel extends StatelessWidget {
  const _GeneratedJobActionPanel({
    required this.job,
    required this.isSavedLocally,
    required this.isSaving,
    required this.onSave,
    required this.onCopy,
  });

  final JobPosting job;
  final bool isSavedLocally;
  final bool isSaving;
  final VoidCallback onSave;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.location} • ${job.employmentType}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSavedLocally
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSavedLocally ? 'Tersimpan' : 'Belum disimpan',
                  style: TextStyle(
                    color: isSavedLocally
                        ? const Color(0xFF166534)
                        : const Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lowongan ini sudah siap untuk disimpan ke daftar lowongan atau dicopy untuk publikasi.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Menyimpan...' : 'Simpan Lowongan'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  onCopy();
                },
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy untuk Publikasi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
