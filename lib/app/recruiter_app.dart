library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../models/chat_session_record.dart';
import '../repositories/chat_session_repository.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';
import '../screens/chat_room_screen.dart';
import '../screens/full_chat_screen.dart';
import '../screens/gemma_proof_screen.dart';
import '../screens/hiring_screen.dart';
import '../screens/job_candidates_screen.dart';
import '../screens/job_posting_chat_screen.dart';
import '../services/api/candidates_api.dart';
import '../services/api/cloudflare_kv_api_client.dart';
import '../services/api/jobs_api.dart';
import '../services/api/screenings_api.dart';
import '../services/hybrid_ai_service.dart';
import '../services/interview_guide_generation_service.dart';
import '../services/resume_screening_service.dart';
import '../services/scorecard_generation_service.dart';
import 'runtime_config.dart';

class RecruiterApp extends StatelessWidget {
  final String title;
  final bool enableAIInitialization;

  const RecruiterApp({
    super.key,
    this.title = 'NgeRekrut',
    this.enableAIInitialization = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18CD5B)),
        useMaterial3: true,
      ),
      home: RecruiterHomeScreen(
        enableAIInitialization: enableAIInitialization,
      ),
    );
  }
}

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({
    super.key,
    this.enableAIInitialization = true,
  });

  final bool enableAIInitialization;

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  final ChatSessionRepository _sessionRepository = ChatSessionRepository();
  final LocalShortlistRepository _localShortlistRepository =
      LocalShortlistRepository();
  final LocalScorecardRepository _localScorecardRepository =
      LocalScorecardRepository();
  final LocalInterviewGuideRepository _localInterviewGuideRepository =
      LocalInterviewGuideRepository();

  HybridAIService? _hybridService;
  HiringRepository? _hiringRepository;
  List<ChatSessionRecord> _sessions = const [];
  bool _isInitializingAI = false;
  bool _isLoadingSessions = true;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _configureHiringRepository();
    _loadSessions();
    if (widget.enableAIInitialization) {
      _initHybridService();
    }
  }

  void _configureHiringRepository() {
    final cloudflareAccountId = readConfig('CLOUDFLARE_ACCOUNT_ID');
    final cloudflareNamespaceId = readConfig('CLOUDFLARE_KV_NAMESPACE_ID');
    final cloudflareApiToken = readConfig('CLOUDFLARE_API_TOKEN');

    if (cloudflareAccountId.isNotEmpty &&
        cloudflareNamespaceId.isNotEmpty &&
        cloudflareApiToken.isNotEmpty) {
      final apiClient = CloudflareKvApiClient(
        accountId: cloudflareAccountId,
        namespaceId: cloudflareNamespaceId,
        apiToken: cloudflareApiToken,
      );
      _hiringRepository = HiringRepository(
        jobsApi: JobsApi(apiClient),
        candidatesApi: CandidatesApi(apiClient),
        screeningsApi: ScreeningsApi(apiClient),
      );
    }
  }

  Future<void> _loadSessions() async {
    try {
      await _sessionRepository.initialize();
      final sessions = _sessionRepository.listSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _initHybridService() async {
    final apiKey = readConfig('OPENAI_API_KEY');
    try {
      setState(() => _isInitializingAI = true);
      _hybridService = HybridAIService(cloudApiKey: apiKey);
      await _hybridService!.initialize(
        onDownloadProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize hybrid service: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializingAI = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCloudAI = _hybridService?.hasCloudAI ?? false;
    final hasLocalAI = _hybridService?.isLocalAIReady ?? false;
    final hasRecruiterData = _hiringRepository != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NgeRekrut'),
        actions: [
          PopupMenuButton<_HomeAction>(
            onSelected: _handleHomeAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _HomeAction.jobPosting,
                child: Text('Buat Lowongan'),
              ),
              PopupMenuItem(
                value: _HomeAction.candidateScreening,
                enabled: hasRecruiterData,
                child: const Text('Screening Kandidat'),
              ),
              const PopupMenuItem(
                value: _HomeAction.hiringAssistant,
                child: Text('Asisten Recruiter'),
              ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: _HomeAction.gemmaProof,
                  child: Text('Cek Gemma Lokal'),
                ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: _HomeAction.legacyChat,
                  child: Text('Buka Legacy Chat'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat Baru'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(
              hasLocalAI: hasLocalAI,
              hasCloudAI: hasCloudAI,
              hasRecruiterData: hasRecruiterData,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Percakapan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_sessions.length} sesi',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingSessions)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_sessions.isEmpty)
              _buildEmptyState()
            else
              ..._sessions.map(_buildSessionTile),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required bool hasLocalAI,
    required bool hasCloudAI,
    required bool hasRecruiterData,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18CD5B), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inbox recruiter',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kelola percakapan recruiter dari satu daftar sesi, lalu masuk ke room yang relevan saat dibutuhkan.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                label: hasLocalAI ? 'Gemma siap' : 'Gemma belum siap',
              ),
              _buildStatusChip(
                label: hasCloudAI ? 'Cloud AI aktif' : 'Cloud AI nonaktif',
              ),
              _buildStatusChip(
                label: hasRecruiterData
                    ? 'Data recruiter aktif'
                    : 'Data recruiter belum aktif',
              ),
            ],
          ),
          if (_isInitializingAI) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _downloadProgress > 0
                  ? 'Menyiapkan Gemma ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                  : 'Menyiapkan Gemma lokal...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.forum_outlined, size: 32),
          const SizedBox(height: 12),
          Text(
            'Belum ada sesi chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat sesi baru untuk mulai percakapan recruiter. Workflow lain tetap tersedia dari menu kanan atas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _createSession,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Buat Sesi Pertama'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(ChatSessionRecord session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        onTap: () => _openSession(session),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8FFF0),
          foregroundColor: const Color(0xFF0F766E),
          child: Text(
            session.title.isNotEmpty ? session.title[0].toUpperCase() : 'C',
          ),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            session.lastMessagePreview.isNotEmpty
                ? session.lastMessagePreview
                : 'Belum ada pesan',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatTime(session.updatedAt)),
            const SizedBox(height: 4),
            Text(
              '${session.messageCount} pesan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onLongPress: () => _confirmDeleteSession(session),
      ),
    );
  }

  Future<void> _createSession() async {
    await _sessionRepository.initialize();
    final session = _sessionRepository.createSession();
    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          session: session,
          aiService: service,
        ),
      ),
    );
    await _loadSessions();
  }

  Future<void> _openSession(ChatSessionRecord session) async {
    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          session: session,
          aiService: service,
        ),
      ),
    );
    await _loadSessions();
  }

  Future<void> _confirmDeleteSession(ChatSessionRecord session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus sesi?'),
        content: Text('Percakapan "${session.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    _sessionRepository.deleteSession(session.sessionId);
    await _loadSessions();
  }

  void _handleHomeAction(_HomeAction action) {
    switch (action) {
      case _HomeAction.jobPosting:
        _openJobPostingChat();
      case _HomeAction.candidateScreening:
        _openCandidateScreening();
      case _HomeAction.hiringAssistant:
        _openHiringAssistant();
      case _HomeAction.gemmaProof:
        _openGemmaProof();
      case _HomeAction.legacyChat:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FullChatScreen(
              currentUserId: 'user_123',
              sessionId: 'session_demo',
              currentUserName: 'Demo User',
            ),
          ),
        );
    }
  }

  void _openJobPostingChat() {
    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostingChatScreen(
          apiKey: readConfig('OPENAI_API_KEY'),
          aiService: service,
        ),
      ),
    );
  }

  void _openCandidateScreening() {
    final repository = _hiringRepository;
    if (repository == null) return;

    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobCandidatesScreen(
          repository: repository,
          localInterviewGuideRepository: _localInterviewGuideRepository,
          localShortlistRepository: _localShortlistRepository,
          localScorecardRepository: _localScorecardRepository,
          interviewGuideGenerationService: InterviewGuideGenerationService(
            aiService: service,
          ),
          screeningService: ResumeScreeningService(aiService: service),
          scorecardGenerationService: ScorecardGenerationService(
            aiService: service,
          ),
        ),
      ),
    );
  }

  void _openHiringAssistant() {
    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiringScreen(aiService: service),
      ),
    );
  }

  void _openGemmaProof() {
    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GemmaProofScreen(aiService: service),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    }
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

enum _HomeAction {
  jobPosting,
  candidateScreening,
  hiringAssistant,
  gemmaProof,
  legacyChat,
}
