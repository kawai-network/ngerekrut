library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../langchain/chat_models/types_persist.dart' as ai;
import '../langchain/chat_models/chat_message_record.dart';
import '../objectbox_store_provider.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';
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

  const RecruiterApp({
    super.key,
    this.title = 'NgeRekrut',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18CD5B)),
        useMaterial3: true,
      ),
      home: const RecruiterHomeScreen(),
    );
  }
}

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  HybridAIService? _hybridService;
  HiringRepository? _hiringRepository;
  final LocalShortlistRepository _localShortlistRepository =
      LocalShortlistRepository();
  final LocalScorecardRepository _localScorecardRepository =
      LocalScorecardRepository();
  final LocalInterviewGuideRepository _localInterviewGuideRepository =
      LocalInterviewGuideRepository();
  bool _isInitializingAI = false;
  double _downloadProgress = 0.0;
  bool _isLoadingSessions = true;
  List<_ChatSessionSummary> _sessions = const [];

  @override
  void initState() {
    super.initState();
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
    _initChatStore();
    _initHybridService();
  }

  Future<void> _initChatStore() async {
    try {
      if (!ObjectBoxStoreProvider.isInitialized) {
        await ObjectBoxStoreProvider.initialize();
      }
      await _loadSessions();
    } catch (e) {
      debugPrint('Failed to initialize chat store: $e');
      if (mounted) {
        setState(() => _isLoadingSessions = false);
      }
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
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize hybrid service: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializingAI = false);
      }
    }
  }

  Future<void> _loadSessions() async {
    if (!ObjectBoxStoreProvider.isInitialized) {
      if (mounted) {
        setState(() => _isLoadingSessions = false);
      }
      return;
    }

    final box = ObjectBoxStoreProvider.box<ChatMessageRecord>();
    final records = box.getAll()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final grouped = <String, List<ChatMessageRecord>>{};
    for (final record in records) {
      grouped.putIfAbsent(record.sessionId, () => <ChatMessageRecord>[]).add(record);
    }

    final sessions = grouped.entries.map((entry) {
      final latest = entry.value.first;
      final firstHuman = entry.value.cast<ChatMessageRecord?>().firstWhere(
            (record) => record?.role == 'human',
            orElse: () => latest,
          );
      final titleSource = (firstHuman?.content ?? latest.content).trim();
      return _ChatSessionSummary(
        sessionId: entry.key,
        title: _sessionTitle(titleSource),
        preview: latest.content.trim(),
        messageCount: entry.value.length,
        lastActivity: DateTime.fromMillisecondsSinceEpoch(latest.createdAt),
      );
    }).toList()
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoadingSessions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCloudAI = (_hybridService?.hasCloudAI ?? false);
    final hasLocalAI = (_hybridService?.isLocalAIReady ?? false);
    final hasRecruiterData = _hiringRepository != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NgeRekrut'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'job_posting':
                  _openJobPostingChat();
                case 'screening':
                  _openCandidateScreening();
                case 'assistant':
                  _openHiringAssistant();
                case 'proof':
                  _openGemmaProof();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'job_posting',
                child: Text('Buat Lowongan'),
              ),
              const PopupMenuItem(
                value: 'screening',
                child: Text('Screening Kandidat'),
              ),
              const PopupMenuItem(
                value: 'assistant',
                child: Text('Asisten Recruiter'),
              ),
              if (kDebugMode)
                const PopupMenuItem(
                  value: 'proof',
                  child: Text('Cek Gemma Lokal'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewSession,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat Baru'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: _buildSessionBody(
            theme: theme,
            hasCloudAI: hasCloudAI,
            hasLocalAI: hasLocalAI,
            hasRecruiterData: hasRecruiterData,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionBody({
    required ThemeData theme,
    required bool hasCloudAI,
    required bool hasLocalAI,
    required bool hasRecruiterData,
  }) {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF18CD5B), Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Percakapan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke room yang sudah ada atau mulai chat baru untuk percakapan recruiter.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(
                    label: hasLocalAI ? 'Gemma siap' : 'Gemma belum siap',
                    color: hasLocalAI
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFDE68A),
                    textColor: const Color(0xFF0F172A),
                  ),
                  _buildStatusChip(
                    label: hasCloudAI ? 'Cloud aktif' : 'Cloud nonaktif',
                    color: const Color(0xFFE0F2FE),
                    textColor: const Color(0xFF0F172A),
                  ),
                  _buildStatusChip(
                    label: hasRecruiterData ? 'Data recruiter aktif' : 'Data recruiter belum aktif',
                    color: hasRecruiterData
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFE5E7EB),
                    textColor: const Color(0xFF0F172A),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isInitializingAI) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _downloadProgress > 0
                            ? 'Mengunduh model Gemma... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                            : 'Menyiapkan Gemma lokal...',
                      ),
                    ),
                  ],
                ),
                if (_downloadProgress > 0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Daftar Sesi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${_sessions.length} sesi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sessions.isEmpty)
          _buildEmptySessions(theme)
        else
          ..._sessions.map(_buildSessionTile),
      ],
    );
  }

  Widget _buildEmptySessions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 40, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            'Belum ada sesi chat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat room baru untuk mulai percakapan recruiter dan semua pesan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openNewSession,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Mulai Chat Baru'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(_ChatSessionSummary session) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: () => _openSession(session.sessionId),
        onLongPress: () => _confirmDeleteSession(session),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: const Color(0xFF0F172A),
          child: Text(
            session.title.characters.first.toUpperCase(),
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
            session.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatSessionTime(session.lastActivity),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              '${session.messageCount} msg',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  void _openJobPostingChat() {
    final service =
        _hybridService ??
        HybridAIService(
          cloudApiKey: readConfig('OPENAI_API_KEY'),
        );
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

    final service =
        _hybridService ??
        HybridAIService(
          cloudApiKey: readConfig('OPENAI_API_KEY'),
        );
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
          screeningService: ResumeScreeningService(
            aiService: service,
          ),
          scorecardGenerationService: ScorecardGenerationService(
            aiService: service,
          ),
        ),
      ),
    );
  }

  void _openHiringAssistant() {
    final service =
        _hybridService ??
        HybridAIService(
          cloudApiKey: readConfig('OPENAI_API_KEY'),
        );
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiringScreen(
          aiService: service,
        ),
      ),
    );
  }

  void _openGemmaProof() {
    final service =
        _hybridService ??
        HybridAIService(
          cloudApiKey: readConfig('OPENAI_API_KEY'),
        );
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GemmaProofScreen(
          aiService: service,
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _openNewSession() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    await _openSession(sessionId);
  }

  Future<void> _openSession(String sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullChatScreen(
          currentUserId: 'user_123',
          sessionId: sessionId,
          currentUserName: 'Recruiter',
        ),
      ),
    );
    await _loadSessions();
  }

  Future<void> _confirmDeleteSession(_ChatSessionSummary session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus sesi?'),
        content: Text('Percakapan "${session.title}" akan dihapus dari daftar sesi.'),
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

    if (confirm == true) {
      ai.ChatMessageQuery.deleteSession(session.sessionId);
      await _loadSessions();
    }
  }

  String _sessionTitle(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return 'Percakapan Baru';
    if (compact.length <= 32) return compact;
    return '${compact.substring(0, 32)}...';
  }

  String _formatSessionTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${time.day}/${time.month}';
  }
}

class _ChatSessionSummary {
  final String sessionId;
  final String title;
  final String preview;
  final int messageCount;
  final DateTime lastActivity;

  const _ChatSessionSummary({
    required this.sessionId,
    required this.title,
    required this.preview,
    required this.messageCount,
    required this.lastActivity,
  });
}
