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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openJobPostingChat,
              icon: const Icon(Icons.add),
              label: const Text('Buat Lowongan'),
            )
          : null,
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

enum _HomeAction {
  jobPosting,
  candidateScreening,
  hiringAssistant,
  gemmaProof,
  seedMockData,
  legacyChat,
}
