library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../dev/mock_recruiter_data_seed.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/local_interview_guide_repository.dart';
import '../repositories/local_job_post_repository.dart';
import '../repositories/local_scorecard_repository.dart';
import '../repositories/local_shortlist_repository.dart';
import '../screens/full_chat_screen.dart';
import '../screens/gemma_proof_screen.dart';
import '../screens/hiring_screen.dart';
import '../screens/job_candidates_screen.dart';
import '../ai/assistants/assistant_manager.dart';
import '../ai/assistants/assistant_base.dart';
import '../ai/assistants/assistant_context.dart';
import '../screens/assistant_chat_screen.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../screens/local_assessment_list_screen.dart';
import '../screens/local_interview_list_screen.dart';
import '../screens/local_job_post_list_screen.dart';
import '../screens/local_screening_list_screen.dart';
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
  final LocalShortlistRepository _localShortlistRepository =
      LocalShortlistRepository();
  final LocalJobPostRepository _localJobPostRepository =
      LocalJobPostRepository();
  final LocalScorecardRepository _localScorecardRepository =
      LocalScorecardRepository();
  final LocalInterviewGuideRepository _localInterviewGuideRepository =
      LocalInterviewGuideRepository();

  HybridAIService? _hybridService;
  HiringRepository? _hiringRepository;
  int _selectedIndex = 0;
  bool _isInitializingAI = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _configureHiringRepository();
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
    final body = [
      LocalJobPostListScreen(
        jobPostRepository: _localJobPostRepository,
        shortlistRepository: _localShortlistRepository,
        scorecardRepository: _localScorecardRepository,
        interviewGuideRepository: _localInterviewGuideRepository,
      ),
      LocalScreeningListScreen(
        jobPostRepository: _localJobPostRepository,
        shortlistRepository: _localShortlistRepository,
      ),
      LocalAssessmentListScreen(
        jobPostRepository: _localJobPostRepository,
        shortlistRepository: _localShortlistRepository,
      ),
      LocalInterviewListScreen(
        jobPostRepository: _localJobPostRepository,
        scorecardRepository: _localScorecardRepository,
        interviewGuideRepository: _localInterviewGuideRepository,
      ),
    ][_selectedIndex];

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
                child: const Text('Screening Kandidat API'),
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
                  value: _HomeAction.seedMockData,
                  child: Text('Seed Mock Data'),
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
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStatusCard(
              hasLocalAI: hasLocalAI,
              hasCloudAI: hasCloudAI,
              hasRecruiterData: hasRecruiterData,
            ),
          ),
          const SizedBox(height: 8),
          // Assistant hint card
          if (_hybridService != null) _buildAssistantHint(hasLocalAI, hasCloudAI),
          const SizedBox(height: 8),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            label: 'Lowongan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Screening',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            label: 'Tes',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            label: 'Interview',
          ),
        ],
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

  Widget _buildFab() {
    final assistant = AssistantManager.getAssistantForTab(_selectedIndex);
    if (assistant == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _openAssistantChat(),
      icon: Icon(assistant.icon),
      label: Text('${assistant.fabLabel}'),
      backgroundColor: assistant.themeColor,
    );
  }

  Widget _buildAssistantHint(bool hasLocalAI, bool hasCloudAI) {
    final assistant = AssistantManager.getAssistantForTab(_selectedIndex);
    if (assistant == null) return const SizedBox.shrink();

    final aiStatus = hasLocalAI
        ? '🧠 Local AI siap'
        : hasCloudAI
            ? '☁️ Cloud AI aktif'
            : 'AI belum siap';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: assistant.themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assistant.themeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(assistant.icon, size: 18, color: assistant.themeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${assistant.name} siap membantu • $aiStatus',
              style: TextStyle(
                color: assistant.themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAssistantChat() {
    final assistant = AssistantManager.getAssistantForTab(_selectedIndex);
    if (assistant == null) return;

    final service = _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;

    // Build context (async to fetch actual data)
    _buildAssistantContext().then((assistantContext) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AssistantChatScreen(
            assistant: assistant,
            aiService: service,
            context: assistantContext,
          ),
        ),
      );
    });
  }

  /// Build assistant context based on the current tab.
  Future<AssistantContext> _buildAssistantContext() async {
    switch (_selectedIndex) {
      case 0: // Lowongan
        final jobs = await _localJobPostRepository.list();
        final firstJob = jobs.isNotEmpty ? jobs.first : null;

        if (firstJob == null) {
          return const AssistantContext(
            extraData: {
              'tab': 'lowongan',
              'hint': 'Belum ada lowongan. Pengguna bisa membuat lowongan baru.',
            },
          );
        }

        final shortlist = await _localShortlistRepository.getLatestForJob(firstJob.id);

        return AssistantContext(
          selectedJob: AssistantJobContext(
            id: firstJob.id,
            title: firstJob.title,
            department: firstJob.department,
            location: firstJob.location,
            description: firstJob.description,
            requirements: firstJob.requirements,
            status: firstJob.status,
            shortlistCount: shortlist?.rankedCandidates.length ?? 0,
          ),
          extraData: {
            'tab': 'lowongan',
            'totalJobs': jobs.length,
            'hint': 'Pengguna sedang melihat daftar lowongan. Lowongan pertama: ${firstJob.title}',
          },
        );

      case 1: // Screening
        final jobs = await _localJobPostRepository.list();
        final screenings = <_ScreeningData>[];

        for (final job in jobs) {
          final shortlist = await _localShortlistRepository.getLatestForJob(job.id);
          if (shortlist != null && shortlist.rankedCandidates.isNotEmpty) {
            screenings.add(_ScreeningData(job: job, shortlist: shortlist));
          }
        }

        final candidates = <AssistantCandidateContext>[];
        if (screenings.isNotEmpty) {
          final topShortlist = screenings.first.shortlist;
          for (final entry in topShortlist.topCandidates.take(3)) {
            candidates.add(AssistantCandidateContext(
              id: entry.id,
              name: entry.name,
              title: screenings.first.job.title,
              score: entry.totalScore,
              recommendation: entry.recommendation,
              strengths: entry.strengths,
              redFlags: entry.redFlags,
              summary: entry.summary,
            ));
          }
        }

        return AssistantContext(
          candidates: candidates,
          extraData: {
            'tab': 'screening',
            'totalScreenings': screenings.length,
            'hint': 'Pengguna sedang melihat hasil screening kandidat. ${screenings.length} lowongan memiliki screening.',
          },
        );

      case 2: // Tes
        final jobs = await _localJobPostRepository.list();
        int readyForTest = 0;

        for (final job in jobs) {
          final shortlist = await _localShortlistRepository.getLatestForJob(job.id);
          if (shortlist != null) {
            readyForTest += shortlist.rankedCandidates.length;
          }
        }

        return const AssistantContext(
          extraData: {
            'tab': 'assessment',
            'hint': 'Pengguna sedang melihat asesmen yang siap untuk kandidat.',
          },
        );

      case 3: // Interview
        final guides = await _localInterviewGuideRepository.listAll();
        final scorecards = await _localScorecardRepository.listAll();

        return AssistantContext(
          extraData: {
            'tab': 'interview',
            'totalGuides': guides.length,
            'totalScorecards': scorecards.length,
            'hint': 'Pengguna sedang melihat panduan interview dan scorecard. ${guides.length} guides, ${scorecards.length} scorecards.',
          },
        );

      default:
        return const AssistantContext();
    }
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
      case _HomeAction.seedMockData:
        _seedMockData();
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

  Future<void> _seedMockData() async {
    await MockRecruiterDataSeed.seed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock recruiter data berhasil diisi ke ObjectBox.'),
      ),
    );
  }
}

/// Helper class to hold job + shortlist data for screening context.
class _ScreeningData {
  final RecruiterJob job;
  final RecruiterShortlistResult shortlist;

  const _ScreeningData({required this.job, required this.shortlist});
}

enum _HomeAction {
  jobPosting,
  candidateScreening,
  hiringAssistant,
  gemmaProof,
  seedMockData,
  legacyChat,
}
