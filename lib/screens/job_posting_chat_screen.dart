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
import '../repositories/job_posting_repository.dart';
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
  static const _streamTextMetadataKey = 'streamText';
  static const _autoDraftIdPrefix = 'draft_job_';

  late InMemoryChatController _chatController;
  final JobPostingRepository _sharedJobPostRepository = JobPostingRepository();
  HybridAIService? _hybridService;
  JobPosting? _lastGenerated;
  String? _draftJobId;
  bool _isGenerating = false;
  bool _isInitializing = false;
  bool _isSaving = false;
  bool _isSaved = false;
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
    if (!mounted) return;
    setState(() => _isInitializing = true);

    try {
      _hybridService = widget.aiService ?? HybridAIService(cloudApiKey: apiKey);
      final localReady = await _hybridService!.initialize(
        onDownloadProgress: (progress) {
          if (!mounted) return;
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
• preview hasilnya
• salin untuk dipublikasikan

Catatan:
• satu percakapan fokus untuk satu lowongan
• jika ingin membuat lowongan lain, mulai percakapan baru''';
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

    if (_lastGenerated != null) {
      if (_looksLikeRefinement(text)) {
        await _handleRefine(text.trim());
      } else {
        await _sendSingleJobScopeMessage();
      }
      return;
    }

    await _handleGenerate(text.trim());
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

    if (!mounted) return;
    setState(() => _isGenerating = true);

    // Create streaming message placeholder
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

    _ProgressTicker? progressTicker;
    try {
      var currentStreamMsg = streamMsg;
      final progressUpdates = _buildGenerationProgressUpdates(position);
      progressTicker = _startProgressTicker(
        initialMessage: streamMsg,
        updates: progressUpdates,
        onMessageUpdated: (message) => currentStreamMsg = message,
      );

      final result = await _hybridService!.generateJobPosting(position);
      await progressTicker.cancel();
      _lastGenerated = result.jobPosting;
      await _persistCurrentDraft();

      final responseText = _formatJobPosting(
        result.jobPosting,
        result.usedMode,
      );

      currentStreamMsg = await _streamTextResponse(
        initialMessage: currentStreamMsg,
        finalText: responseText,
      );

      // Update streaming message with final content
      final finalMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: responseText,
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(currentStreamMsg, finalMsg);
    } catch (e) {
      await progressTicker?.cancel();
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
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleRefine(String request) async {
    if (_hybridService == null || _lastGenerated == null) return;

    if (!mounted) return;
    setState(() => _isGenerating = true);

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

    _ProgressTicker? progressTicker;
    try {
      var currentStreamMsg = streamMsg;
      progressTicker = _startProgressTicker(
        initialMessage: streamMsg,
        updates: const [
          'Meninjau draft yang sebelumnya...',
          'Menyesuaikan detail sesuai revisi...',
          'Merapikan ulang deskripsi dan requirement...',
          'Menyusun versi revisi yang siap dipakai...',
        ],
        onMessageUpdated: (message) => currentStreamMsg = message,
      );

      final result = await _hybridService!.refineJobPosting(
        _lastGenerated!,
        request,
      );
      await progressTicker.cancel();
      _lastGenerated = result.jobPosting;
      await _persistCurrentDraft();

      final responseText = _formatJobPosting(
        result.jobPosting,
        result.usedMode,
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
    } catch (e) {
      await progressTicker?.cancel();
      final errorMsg = Message.text(
        id: streamId,
        authorId: 'ai',
        text: '❌ Gagal refine: $e',
        createdAt: streamMsg.createdAt,
        status: MessageStatus.seen,
      );
      await _chatController.updateMessage(streamMsg, errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
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
      '📌 **Langkah berikutnya:** draft ini sudah tersimpan otomatis. Anda bisa kembali ke daftar lowongan, copy untuk publikasi, atau ketik revisi untuk perbaikan.',
    );
    return buffer.toString();
  }

  List<String> _buildGenerationProgressUpdates(String position) {
    final cleanPosition = position.trim();
    return [
      'Memahami kebutuhan untuk posisi $cleanPosition...',
      'Menyusun judul dan konteks lowongan...',
      'Menentukan requirement yang realistis...',
      'Merumuskan tanggung jawab utama...',
      'Merapikan draft agar siap dipublikasikan...',
    ];
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

  Future<bool> _persistCurrentDraft({bool showSuccessMessage = false}) async {
    final job = _lastGenerated;
    if (job == null || _isSaving) return false;

    if (!mounted) return false;
    setState(() => _isSaving = true);
    try {
      final draftJobId =
          _draftJobId ?? '$_autoDraftIdPrefix${DateTime.now().millisecondsSinceEpoch}';
      final savedJob = RecruiterJob(
        id: draftJobId,
        title: job.title,
        unitLabel: null,
        location: job.location,
        description:
            '${job.description}\n\nTanggung jawab:\n- ${job.responsibilities.join('\n- ')}\n\nEstimasi gaji: ${job.salaryRange}\nTipe kerja: ${job.employmentType}',
        requirements: job.requirements,
        status: JobPostingRepository.statusDraft,
      );

      final existing = await _sharedJobPostRepository.getByJobId(draftJobId);
      if (existing == null) {
        await _sharedJobPostRepository.create(savedJob);
      } else {
        await _sharedJobPostRepository.update(savedJob);
      }

      if (!mounted) return false;
      setState(() {
        _draftJobId = draftJobId;
        _isSaved = true;
      });

      if (showSuccessMessage && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan lowongan: $e')));
      return false;
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

  Future<void> _sendSingleJobScopeMessage() async {
    final infoId = _uuid.v4();
    final infoMsg = Message.text(
      id: infoId,
      authorId: 'ai',
      text:
          'Percakapan ini sekarang fokus ke satu lowongan yang sudah aktif. Jika masih lowongan yang sama, kirim revisi seperti "ubah lokasi", "tambah requirement", atau "naikkan gaji". Jika ingin membuat lowongan lain, tekan tombol reset di kanan atas untuk mulai percakapan baru.',
      createdAt: DateTime.now(),
      status: MessageStatus.seen,
    );
    await _chatController.insertMessage(infoMsg);
  }

  @override
  void dispose() {
    _chatController.dispose();
    if (widget.aiService == null) {
      _hybridService?.dispose();
    }
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
          if (_lastGenerated != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Preview',
              onPressed: _showDraftPreview,
            ),
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
            tooltip: 'Mulai lowongan baru',
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
          if (!_isGenerating && !_isInitializing && _lastGenerated == null)
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
              isSaved: _isSaved,
              isSaving: _isSaving,
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
            final streamText =
                message.metadata?[_streamTextMetadataKey] as String? ?? '';
            return FlyerChatTextStreamMessage(
              message: message,
              index: index,
              streamState: StreamStateStreaming(streamText),
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

  Future<void> _showDraftPreview() async {
    final job = _lastGenerated;
    if (job == null || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${job.location} • ${job.employmentType}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PreviewSection(
                    title: 'Deskripsi',
                    child: Text(
                      job.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PreviewSection(
                    title: 'Kualifikasi',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: job.requirements
                          .map((item) => _PreviewBullet(text: item))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PreviewSection(
                    title: 'Tanggung Jawab',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: job.responsibilities
                          .map((item) => _PreviewBullet(text: item))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PreviewSection(
                    title: 'Estimasi Gaji',
                    child: Text(
                      job.salaryRange,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resetChat() {
    final previousController = _chatController;
    setState(() {
      _lastGenerated = null;
      _isSaved = false;
      _draftJobId = null;
    });
    // Recreate the controller after clearing state to avoid mutating a
    // disposed chat controller from pending async tasks.
    _chatController = InMemoryChatController();
    previousController.dispose();
    unawaited(_sendWelcomeMessage());
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
    if (!mounted) return;
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

class _ProgressTicker {
  final Future<void> Function() cancel;

  const _ProgressTicker({required this.cancel});
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PreviewBullet extends StatelessWidget {
  const _PreviewBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedJobActionPanel extends StatelessWidget {
  const _GeneratedJobActionPanel({
    required this.job,
    required this.isSaved,
    required this.isSaving,
    required this.onCopy,
  });

  final JobPosting job;
  final bool isSaved;
  final bool isSaving;
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
                  color: isSaved
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSaved ? 'Draft tersimpan' : 'Menyimpan draft',
                  style: TextStyle(
                    color: isSaved
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
            isSaved
                ? 'Draft ini sudah tersimpan otomatis. Percakapan ini sekarang fokus untuk revisi lowongan yang sama.'
                : 'Draft ini sedang disimpan ke daftar lowongan. Tunggu sebentar sebelum lanjut revisi.',
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
                onPressed: null,
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isSaving ? 'Menyimpan...' : 'Draft Tersimpan Otomatis',
                ),
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
