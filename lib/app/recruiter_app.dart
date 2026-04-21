library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../dev/mock_recruiter_data_seed.dart';
import '../repositories/hiring_repository.dart';
import '../repositories/interview_guide_artifact_repository.dart';
import '../repositories/job_application_repository.dart';
import '../repositories/job_posting_repository.dart';
import '../repositories/scorecard_artifact_repository.dart';
import '../repositories/shortlist_artifact_repository.dart';
import '../screens/full_chat_screen.dart';
import '../screens/gemma_proof_screen.dart';
import '../screens/hiring_screen.dart';
import '../screens/job_candidates_screen.dart';
import '../ai/assistants/assistant_manager.dart';
import '../ai/assistants/assistant_context.dart';
import '../screens/assistant_chat_screen.dart';
import '../models/recruiter_job.dart';
import '../models/recruiter_shortlist.dart';
import '../screens/recruiter_interview_list_screen.dart';
import '../screens/recruiter_application_inbox_screen.dart';
import '../screens/recruiter_job_post_list_screen.dart';
import '../screens/recruiter_screening_list_screen.dart';
import '../screens/job_posting_chat_screen.dart';
import '../services/api/candidates_api.dart';
import '../services/api/cloudflare_kv_api_client.dart';
import '../services/api/jobs_api.dart';
import '../services/api/screenings_api.dart';
import '../services/hybrid_ai_service.dart';
import '../services/interview_guide_generation_service.dart';
import '../services/resume_screening_service.dart';
import '../services/scorecard_generation_service.dart';
import '../services/shared_identity_service.dart';
import '../services/onesignal_service.dart';
import 'runtime_config.dart';

class RecruiterApp extends StatelessWidget {
  final String title;
  final bool enableAIInitialization;
  final Widget? homeOverride;

  const RecruiterApp({
    super.key,
    this.title = 'NgeRekrut',
    this.enableAIInitialization = true,
    this.homeOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18CD5B)),
        useMaterial3: true,
      ),
      home:
          homeOverride ??
          RecruiterHomeScreen(enableAIInitialization: enableAIInitialization),
    );
  }
}

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key, this.enableAIInitialization = true});

  final bool enableAIInitialization;

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  final ShortlistArtifactRepository _shortlistArtifactRepository =
      ShortlistArtifactRepository();
  final JobPostingRepository _jobPostingRepository = JobPostingRepository();
  final JobApplicationRepository _jobApplicationRepository =
      JobApplicationRepository();
  final ScorecardArtifactRepository _scorecardArtifactRepository =
      ScorecardArtifactRepository();
  final InterviewGuideArtifactRepository _interviewGuideArtifactRepository =
      InterviewGuideArtifactRepository();

  HybridAIService? _hybridService;
  HiringRepository? _hiringRepository;
  int _selectedIndex = 0;
  bool _isInitializingAI = false;
  bool _isLoadingDashboard = true;
  double _downloadProgress = 0.0;
  _RecruiterDashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _configureHiringRepository();
    _refreshDashboard();
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

  Future<void> _refreshDashboard() async {
    if (mounted) {
      setState(() => _isLoadingDashboard = true);
    }

    final jobs = await _jobPostingRepository.getAll();
    final scorecards = await _scorecardArtifactRepository.listAll();
    final guides = await _interviewGuideArtifactRepository.listAll();
    final activeJobs = jobs.where((job) => _isActiveJob(job.status)).length;
    final draftJobs = jobs
        .where((job) => job.status.toLowerCase() == 'draft')
        .length;
    final jobsWithApplicants = <_DashboardJobSummary>[];
    final candidateActions = <_DashboardCandidateAction>[];

    var totalReviewCandidates = 0;
    var readyForInterview = 0;

    for (final job in jobs) {
      final applications = await _jobApplicationRepository.getByJobId(job.id);
      final shortlist = await _shortlistArtifactRepository.getLatestForJob(
        job.id,
      );
      final rankedCount = shortlist?.rankedCandidates.length ?? 0;
      final topCount = shortlist?.topCandidates.length ?? 0;
      final reviewCount = shortlist == null ? 0 : rankedCount - topCount;

      totalReviewCandidates += rankedCount;
      readyForInterview += topCount;

      if (shortlist != null || _isActiveJob(job.status)) {
        jobsWithApplicants.add(
          _DashboardJobSummary(
            job: job,
            applicantCount: applications.length,
            reviewCount: reviewCount < 0 ? 0 : reviewCount,
            interviewCount: topCount,
            summary: shortlist?.summary,
          ),
        );
      }

      if (shortlist != null) {
        for (final entry in shortlist.topCandidates.take(3)) {
          candidateActions.add(
            _DashboardCandidateAction(
              jobTitle: job.title,
              candidateName: entry.candidateName,
              recommendation: entry.recommendation,
              score: entry.totalScore.round(),
              highlights: entry.strengths.take(2).toList(),
              needsAttention:
                  entry.redFlags.isNotEmpty || entry.gaps.isNotEmpty,
            ),
          );
        }
      }
    }

    jobsWithApplicants.sort((a, b) {
      final aUrgency = a.reviewCount + a.interviewCount;
      final bUrgency = b.reviewCount + b.interviewCount;
      return bUrgency.compareTo(aUrgency);
    });
    candidateActions.sort((a, b) => b.score.compareTo(a.score));

    final priorityCards = <_DashboardPriority>[];

    if (jobs.isEmpty) {
      priorityCards.add(
        const _DashboardPriority(
          title: 'Buat lowongan pertama',
          description:
              'Mulai dari posisi yang paling mendesak agar kandidat bisa mulai masuk.',
          icon: Icons.add_circle_outline,
          tone: _DashboardPriorityTone.primary,
        ),
      );
    } else {
      if (activeJobs > 0) {
        priorityCards.add(
          _DashboardPriority(
            title: '$activeJobs lowongan aktif',
            description:
                'Pantau posisi yang sedang dibuka dan pastikan kandidat terus bergerak.',
            icon: Icons.work_outline,
            tone: _DashboardPriorityTone.primary,
          ),
        );
      }
      if (totalReviewCandidates > readyForInterview) {
        priorityCards.add(
          _DashboardPriority(
            title:
                '${totalReviewCandidates - readyForInterview} kandidat perlu review',
            description:
                'Ada kandidat yang sudah dinilai tetapi belum diputuskan langkah berikutnya.',
            icon: Icons.fact_check_outlined,
            tone: _DashboardPriorityTone.warning,
          ),
        );
      }
      if (readyForInterview > 0) {
        priorityCards.add(
          _DashboardPriority(
            title: '$readyForInterview kandidat siap interview',
            description:
                'Lanjutkan kandidat teratas ke tahap interview agar hiring tidak melambat.',
            icon: Icons.record_voice_over_outlined,
            tone: _DashboardPriorityTone.success,
          ),
        );
      }
      if (draftJobs > 0) {
        priorityCards.add(
          _DashboardPriority(
            title: '$draftJobs lowongan masih draft',
            description:
                'Lengkapi lowongan yang belum selesai agar bisa segera dipublikasikan.',
            icon: Icons.edit_note,
            tone: _DashboardPriorityTone.neutral,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _dashboardData = _RecruiterDashboardData(
        activeJobs: activeJobs,
        totalJobs: jobs.length,
        reviewCandidates: totalReviewCandidates,
        readyForInterview: readyForInterview,
        interviewArtifacts: scorecards.length + guides.length,
        jobs: jobsWithApplicants.take(4).toList(),
        priorities: priorityCards.take(3).toList(),
        candidateActions: candidateActions.take(4).toList(),
      );
      _isLoadingDashboard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasRecruiterData = _hiringRepository != null;
    final hasCloudAI = _hybridService?.hasCloudAI ?? false;
    final hasLocalAI = _hybridService?.isLocalAIReady ?? false;
    final body = [
      _RecruiterDashboardScreen(
        isLoading: _isLoadingDashboard,
        data: _dashboardData,
        aiReady: hasLocalAI || hasCloudAI,
        isInitializingAI: _isInitializingAI,
        downloadProgress: _downloadProgress,
        onRefresh: _refreshDashboard,
        onCreateJobPosting: () {
          _openJobPostingChat();
        },
        onReviewCandidates: hasRecruiterData
            ? () {
                _openCandidateScreening();
              }
            : () {
                setState(() => _selectedIndex = 2);
              },
        onOpenJobs: () {
          setState(() => _selectedIndex = 1);
        },
        onOpenInterview: () {
          setState(() => _selectedIndex = 3);
        },
        onOpenAssistant: () {
          _openHiringAssistant();
        },
      ),
      RecruiterJobPostListScreen(
        jobPostRepository: _jobPostingRepository,
        shortlistRepository: _shortlistArtifactRepository,
        scorecardRepository: _scorecardArtifactRepository,
        interviewGuideRepository: _interviewGuideArtifactRepository,
      ),
      RecruiterScreeningListScreen(
        jobPostRepository: _jobPostingRepository,
        shortlistRepository: _shortlistArtifactRepository,
      ),
      RecruiterInterviewListScreen(
        jobPostRepository: _jobPostingRepository,
        shortlistRepository: _shortlistArtifactRepository,
        scorecardRepository: _scorecardArtifactRepository,
        interviewGuideRepository: _interviewGuideArtifactRepository,
      ),
      const RecruiterApplicationInboxScreen(),
    ][_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForTab()),
        actions: [
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  _openJobPostingChat();
                },
                icon: const Icon(Icons.add),
                label: const Text('Buat Lowongan'),
              ),
            ),
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
                child: const Text('Tarik Kandidat dari API'),
              ),
              const PopupMenuItem(
                value: _HomeAction.hiringAssistant,
                child: Text('Template Hiring'),
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
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _HomeAction.signOut,
                child: Text('Keluar'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            label: 'Lowongan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Kandidat',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            label: 'Interview',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            label: 'Lamaran',
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    if (_selectedIndex == 0) {
      return FloatingActionButton.extended(
        onPressed: () {
          _openJobPostingChat();
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Lowongan'),
      );
    }

    final assistant = AssistantManager.getAssistantForTab(_selectedIndex);
    if (assistant == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _openAssistantChat(),
      icon: Icon(assistant.icon),
      label: Text(assistant.fabLabel),
      backgroundColor: assistant.themeColor,
    );
  }

  void _openAssistantChat() {
    final assistant = AssistantManager.getAssistantForTab(_selectedIndex);
    if (assistant == null) return;

    final service =
        _hybridService ??
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
      case 1: // Lowongan
        final jobs = await _jobPostingRepository.getAll();
        final firstJob = jobs.isNotEmpty ? jobs.first : null;

        if (firstJob == null) {
          return const AssistantContext(
            extraData: {
              'tab': 'lowongan',
              'hint':
                  'Belum ada lowongan. Pengguna bisa membuat lowongan baru.',
            },
          );
        }

        final shortlist = await _shortlistArtifactRepository.getLatestForJob(
          firstJob.id,
        );

        return AssistantContext(
          selectedJob: AssistantJobContext(
            id: firstJob.id,
            title: firstJob.title,
            unitLabel: firstJob.unitLabel,
            location: firstJob.location,
            description: firstJob.description,
            requirements: firstJob.requirements,
            status: firstJob.status,
            shortlistCount: shortlist?.rankedCandidates.length ?? 0,
          ),
          extraData: {
            'tab': 'lowongan',
            'totalJobs': jobs.length,
            'hint':
                'Pengguna sedang melihat daftar lowongan. Lowongan pertama: ${firstJob.title}',
          },
        );

      case 2: // Kandidat
        final jobs = await _jobPostingRepository.getAll();
        final screenings = <_ScreeningData>[];

        for (final job in jobs) {
          final shortlist = await _shortlistArtifactRepository.getLatestForJob(
            job.id,
          );
          if (shortlist != null && shortlist.rankedCandidates.isNotEmpty) {
            screenings.add(_ScreeningData(job: job, shortlist: shortlist));
          }
        }

        final candidates = <AssistantCandidateContext>[];
        if (screenings.isNotEmpty) {
          final topShortlist = screenings.first.shortlist;
          for (final entry in topShortlist.topCandidates.take(3)) {
            candidates.add(
              AssistantCandidateContext(
                id: entry.candidateId,
                name: entry.candidateName,
                title: screenings.first.job.title,
                score: entry.totalScore.toInt(),
                recommendation: entry.recommendation,
                strengths: entry.strengths,
                redFlags: entry.redFlags,
                summary: entry.rationale,
              ),
            );
          }
        }

        return AssistantContext(
          candidates: candidates,
          extraData: {
            'tab': 'screening',
            'totalScreenings': screenings.length,
            'hint':
                'Pengguna sedang melihat hasil screening kandidat. ${screenings.length} lowongan memiliki screening.',
          },
        );

      case 3: // Interview
        final guides = await _interviewGuideArtifactRepository.listAll();
        final scorecards = await _scorecardArtifactRepository.listAll();

        return AssistantContext(
          extraData: {
            'tab': 'interview',
            'totalGuides': guides.length,
            'totalScorecards': scorecards.length,
            'hint':
                'Pengguna sedang melihat panduan interview dan scorecard. ${guides.length} guides, ${scorecards.length} scorecards.',
          },
        );

      default:
        final jobs = await _jobPostingRepository.getAll();
        final readyForReview = _dashboardData?.reviewCandidates ?? 0;
        return AssistantContext(
          extraData: {
            'tab': 'dashboard',
            'totalJobs': jobs.length,
            'readyForReview': readyForReview,
            'hint':
                'Pengguna sedang melihat dashboard rekrutmen dan membutuhkan prioritas operasional.',
          },
        );
    }
  }

  Future<void> _handleHomeAction(_HomeAction action) async {
    switch (action) {
      case _HomeAction.jobPosting:
        await _openJobPostingChat();
        return;
      case _HomeAction.candidateScreening:
        await _openCandidateScreening();
        return;
      case _HomeAction.hiringAssistant:
        await _openHiringAssistant();
        return;
      case _HomeAction.gemmaProof:
        await _openGemmaProof();
        return;
      case _HomeAction.seedMockData:
        await _seedMockData();
        return;
      case _HomeAction.legacyChat:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FullChatScreen(
              currentUserId: 'user_123',
              sessionId: 'session_demo',
              currentUserName: 'Demo User',
            ),
          ),
        );
        return;
      case _HomeAction.signOut:
        // Clear OneSignal subscription before signing out
        await OneSignalService.instance.clearSubscription();
        await SharedIdentityService.signOut();
        return;
    }
  }

  Future<void> _openJobPostingChat() async {
    final service =
        _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostingChatScreen(
          apiKey: readConfig('OPENAI_API_KEY'),
          aiService: service,
        ),
      ),
    );
    await _refreshDashboard();
  }

  Future<void> _openCandidateScreening() async {
    final repository = _hiringRepository;
    if (repository == null) return;

    final service =
        _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobCandidatesScreen(
          repository: repository,
          interviewGuideArtifactRepository: _interviewGuideArtifactRepository,
          shortlistArtifactRepository: _shortlistArtifactRepository,
          scorecardArtifactRepository: _scorecardArtifactRepository,
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
    await _refreshDashboard();
  }

  Future<void> _openHiringAssistant() async {
    final service =
        _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HiringScreen(aiService: service)),
    );
  }

  Future<void> _openGemmaProof() async {
    final service =
        _hybridService ??
        HybridAIService(cloudApiKey: readConfig('OPENAI_API_KEY'));
    _hybridService ??= service;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GemmaProofScreen(aiService: service),
      ),
    );
  }

  Future<void> _seedMockData() async {
    await MockRecruiterDataSeed.seed();
    await _refreshDashboard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data contoh recruiter berhasil ditambahkan.'),
      ),
    );
  }

  String _titleForTab() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Rekrutmen';
      case 1:
        return 'Lowongan';
      case 2:
        return 'Kandidat';
      case 3:
        return 'Interview';
      case 4:
        return 'Lamaran';
      default:
        return 'NgeRekrut';
    }
  }

  bool _isActiveJob(String status) {
    return JobPostingRepository.isPublishedStatus(status);
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
  signOut,
}

class _RecruiterDashboardData {
  final int activeJobs;
  final int totalJobs;
  final int reviewCandidates;
  final int readyForInterview;
  final int interviewArtifacts;
  final List<_DashboardJobSummary> jobs;
  final List<_DashboardPriority> priorities;
  final List<_DashboardCandidateAction> candidateActions;

  const _RecruiterDashboardData({
    required this.activeJobs,
    required this.totalJobs,
    required this.reviewCandidates,
    required this.readyForInterview,
    required this.interviewArtifacts,
    required this.jobs,
    required this.priorities,
    required this.candidateActions,
  });
}

class _DashboardJobSummary {
  final RecruiterJob job;
  final int applicantCount;
  final int reviewCount;
  final int interviewCount;
  final String? summary;

  const _DashboardJobSummary({
    required this.job,
    required this.applicantCount,
    required this.reviewCount,
    required this.interviewCount,
    this.summary,
  });
}

class _DashboardCandidateAction {
  final String candidateName;
  final String jobTitle;
  final String recommendation;
  final int score;
  final List<String> highlights;
  final bool needsAttention;

  const _DashboardCandidateAction({
    required this.candidateName,
    required this.jobTitle,
    required this.recommendation,
    required this.score,
    required this.highlights,
    required this.needsAttention,
  });
}

enum _DashboardPriorityTone { primary, success, warning, neutral }

class _DashboardPriority {
  final String title;
  final String description;
  final IconData icon;
  final _DashboardPriorityTone tone;

  const _DashboardPriority({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });
}

class _RecruiterDashboardScreen extends StatelessWidget {
  const _RecruiterDashboardScreen({
    required this.isLoading,
    required this.data,
    required this.aiReady,
    required this.isInitializingAI,
    required this.downloadProgress,
    required this.onRefresh,
    required this.onCreateJobPosting,
    required this.onReviewCandidates,
    required this.onOpenJobs,
    required this.onOpenInterview,
    required this.onOpenAssistant,
  });

  final bool isLoading;
  final _RecruiterDashboardData? data;
  final bool aiReady;
  final bool isInitializingAI;
  final double downloadProgress;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateJobPosting;
  final VoidCallback onReviewCandidates;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenInterview;
  final VoidCallback onOpenAssistant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dashboard = data;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF12372A), Color(0xFF1C6758)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantau hiring tanpa buka banyak layar.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Lihat kondisi lowongan, kandidat yang perlu diputuskan, lalu lanjutkan aksi paling penting hari ini.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DashboardHeroChip(
                      label: aiReady ? 'AI siap membantu' : 'AI belum siap',
                    ),
                    if (isInitializingAI)
                      _DashboardHeroChip(
                        label: downloadProgress > 0
                            ? 'Menyiapkan AI ${(downloadProgress * 100).toStringAsFixed(0)}%'
                            : 'Menyiapkan AI',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onCreateJobPosting,
                      icon: const Icon(Icons.add),
                      label: const Text('Buat Lowongan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF12372A),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onReviewCandidates,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Review Kandidat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ringkasan hari ini',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (isLoading || dashboard == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(
                  label: 'Lowongan aktif',
                  value: '${dashboard.activeJobs}',
                  helper: '${dashboard.totalJobs} total lowongan',
                  icon: Icons.work_outline,
                  color: const Color(0xFF166534),
                ),
                _MetricCard(
                  label: 'Perlu review',
                  value: '${dashboard.reviewCandidates}',
                  helper: 'kandidat menunggu keputusan',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFFB45309),
                ),
                _MetricCard(
                  label: 'Siap interview',
                  value: '${dashboard.readyForInterview}',
                  helper: 'kandidat unggulan',
                  icon: Icons.record_voice_over_outlined,
                  color: const Color(0xFF0F766E),
                ),
                _MetricCard(
                  label: 'Dokumen interview',
                  value: '${dashboard.interviewArtifacts}',
                  helper: 'panduan dan penilaian tersimpan',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF4338CA),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Prioritas hari ini',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (dashboard.priorities.isEmpty)
              _EmptySection(
                title: 'Belum ada prioritas mendesak',
                description:
                    'Mulai dengan membuat lowongan atau tarik data kandidat terbaru.',
              )
            else
              ...dashboard.priorities.map((item) => _PriorityCard(item: item)),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Lowongan aktif',
              actionLabel: 'Lihat semua',
              onPressed: onOpenJobs,
            ),
            const SizedBox(height: 12),
            if (dashboard.jobs.isEmpty)
              _EmptySection(
                title: 'Belum ada lowongan aktif',
                description:
                    'Buat lowongan baru agar pipeline kandidat mulai berjalan.',
              )
            else
              ...dashboard.jobs.map((item) => _JobSummaryCard(item: item)),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Kandidat yang perlu keputusan',
              actionLabel: 'Buka kandidat',
              onPressed: onReviewCandidates,
            ),
            const SizedBox(height: 12),
            if (dashboard.candidateActions.isEmpty)
              _EmptySection(
                title: 'Belum ada kandidat prioritas',
                description:
                    'Jalankan penilaian kandidat untuk menampilkan kandidat unggulan di sini.',
              )
            else
              ...dashboard.candidateActions.map(
                (item) => _CandidateActionCard(item: item),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Butuh bantuan cepat?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan template cepat untuk bikin lowongan, merangkum hasil kandidat, atau menyiapkan panduan interview.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onOpenAssistant,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Buka Template'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenInterview,
                        icon: const Icon(Icons.record_voice_over_outlined),
                        label: const Text('Lihat Interview'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            helper,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroChip extends StatelessWidget {
  const _DashboardHeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.item});

  final _DashboardPriority item;

  @override
  Widget build(BuildContext context) {
    final tone = switch (item.tone) {
      _DashboardPriorityTone.primary => const Color(0xFFDCFCE7),
      _DashboardPriorityTone.success => const Color(0xFFCCFBF1),
      _DashboardPriorityTone.warning => const Color(0xFFFEF3C7),
      _DashboardPriorityTone.neutral => const Color(0xFFF3F4F6),
    };
    final iconColor = switch (item.tone) {
      _DashboardPriorityTone.primary => const Color(0xFF166534),
      _DashboardPriorityTone.success => const Color(0xFF0F766E),
      _DashboardPriorityTone.warning => const Color(0xFFB45309),
      _DashboardPriorityTone.neutral => const Color(0xFF4B5563),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(item.description, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.item});

  final _DashboardJobSummary item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.job.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(status: item.job.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                if ((item.job.unitLabel ?? '').isNotEmpty) item.job.unitLabel!,
                if ((item.job.location ?? '').isNotEmpty) item.job.location!,
              ].join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InlineMetric(
                  label: 'Pelamar',
                  value: '${item.applicantCount}',
                ),
                _InlineMetric(
                  label: 'Perlu review',
                  value: '${item.reviewCount}',
                ),
                _InlineMetric(
                  label: 'Siap interview',
                  value: '${item.interviewCount}',
                ),
              ],
            ),
            if ((item.summary ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item.summary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateActionCard extends StatelessWidget {
  const _CandidateActionCard({required this.item});

  final _DashboardCandidateAction item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: item.needsAttention
              ? const Color(0xFFFEF3C7)
              : const Color(0xFFDCFCE7),
          child: Icon(
            item.needsAttention
                ? Icons.priority_high
                : Icons.check_circle_outline,
            color: item.needsAttention
                ? const Color(0xFFB45309)
                : const Color(0xFF166534),
          ),
        ),
        title: Text(
          item.candidateName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${item.jobTitle} • score ${item.score} • ${item.recommendation}${item.highlights.isEmpty ? '' : '\n${item.highlights.join(', ')}'}',
            style: const TextStyle(height: 1.4),
          ),
        ),
        isThreeLine: item.highlights.isNotEmpty,
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final background = switch (normalized) {
      'published' => const Color(0xFFDCFCE7),
      'draft' => const Color(0xFFF3F4F6),
      'closed' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFE0F2FE),
    };
    final foreground = switch (normalized) {
      'published' => const Color(0xFF166534),
      'draft' => const Color(0xFF4B5563),
      'closed' => const Color(0xFFB91C1C),
      _ => const Color(0xFF1D4ED8),
    };
    final label = switch (normalized) {
      'published' => 'Aktif',
      'draft' => 'Draft',
      'closed' => 'Ditutup',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
