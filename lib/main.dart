import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'repositories/hiring_repository.dart';
import 'repositories/local_interview_guide_repository.dart';
import 'repositories/local_scorecard_repository.dart';
import 'repositories/local_shortlist_repository.dart';
import 'screens/full_chat_screen.dart';
import 'screens/gemma_proof_screen.dart';
import 'screens/job_candidates_screen.dart';
import 'screens/job_posting_chat_screen.dart';
import 'screens/hiring_screen.dart';
import 'services/api/candidates_api.dart';
import 'services/api/cloudflare_kv_api_client.dart';
import 'services/api/jobs_api.dart';
import 'services/api/screenings_api.dart';
import 'services/hybrid_ai_service.dart';
import 'services/interview_guide_generation_service.dart';
import 'services/resume_screening_service.dart';
import 'services/scorecard_generation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> _initializeFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  debugPrint('FCM token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.messageId}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('FCM opened app from notification: ${message.messageId}');
  });

  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('FCM token refreshed: $newToken');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  await FlutterGemma.initialize(
    huggingFaceToken: _readConfig('HUGGINGFACE_TOKEN'),
  );
  // Only initialize Firebase on supported platforms
  final isSupportedPlatform = kIsWeb ||
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  if (isSupportedPlatform) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _initializeFirebaseMessaging();
    } on UnsupportedError catch (e) {
      // Platform not configured in firebase_options.dart
      debugPrint('Firebase not configured for this platform: $e');
    } on Exception catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
  runApp(const MyApp());
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Development setup may rely on --dart-define only.
  }
}

String _readConfig(String key) {
  const dartDefineValues = {
    'CLOUDFLARE_ACCOUNT_ID': String.fromEnvironment('CLOUDFLARE_ACCOUNT_ID'),
    'CLOUDFLARE_KV_NAMESPACE_ID': String.fromEnvironment(
      'CLOUDFLARE_KV_NAMESPACE_ID',
    ),
    'CLOUDFLARE_API_TOKEN': String.fromEnvironment('CLOUDFLARE_API_TOKEN'),
    'OPENAI_API_KEY': String.fromEnvironment('OPENAI_API_KEY'),
    'HUGGINGFACE_TOKEN': String.fromEnvironment('HUGGINGFACE_TOKEN'),
  };

  final envValue = dotenv.isInitialized ? dotenv.maybeGet(key) : null;
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  return dartDefineValues[key] ?? '';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NgeRekrut',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18CD5B)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Home screen dengan pilihan fitur.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  void initState() {
    super.initState();
    final cloudflareAccountId = _readConfig('CLOUDFLARE_ACCOUNT_ID');
    final cloudflareNamespaceId = _readConfig('CLOUDFLARE_KV_NAMESPACE_ID');
    final cloudflareApiToken = _readConfig('CLOUDFLARE_API_TOKEN');

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
    _initHybridService();
  }

  Future<void> _initHybridService() async {
    final apiKey = _readConfig('OPENAI_API_KEY');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCloudAI = (_hybridService?.hasCloudAI ?? false);
    final hasLocalAI = (_hybridService?.isLocalAIReady ?? false);
    final hasRecruiterData = _hiringRepository != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NgeRekrut'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Asisten rekrutmen berbasis AI lokal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kelola lowongan dan screening kandidat dari satu tempat.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gunakan Gemma lokal untuk membuat lowongan, menyusun panduan interview, dan membantu proses screening recruiter.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(
                        label: hasLocalAI ? 'Gemma siap' : 'Gemma belum siap',
                        color: hasLocalAI ? const Color(0xFFD1FAE5) : const Color(0xFFFDE68A),
                        textColor: const Color(0xFF0F172A),
                      ),
                      _buildStatusChip(
                        label: hasCloudAI ? 'Cloud AI aktif' : 'Cloud AI opsional',
                        color: const Color(0xFFE0F2FE),
                        textColor: const Color(0xFF0F172A),
                      ),
                      _buildStatusChip(
                        label: hasRecruiterData ? 'Data recruiter aktif' : 'Data recruiter belum aktif',
                        color: hasRecruiterData ? const Color(0xFFDBEAFE) : const Color(0xFFE5E7EB),
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
            Text(
              'Workflow Utama',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildPrimaryActionCard(
              context: context,
              icon: Icons.edit_note,
              title: 'Buat Lowongan',
              description:
                  'Tulis posisi yang dibutuhkan, lalu biarkan AI menyusun lowongan lengkap dalam bahasa Indonesia.',
              accentColor: const Color(0xFF18CD5B),
              actionLabel: 'Mulai Buat Lowongan',
              onTap: _openJobPostingChat,
            ),
            const SizedBox(height: 12),
            _buildPrimaryActionCard(
              context: context,
              icon: Icons.fact_check_outlined,
              title: 'Screening Kandidat',
              description:
                  'Lihat kandidat per lowongan, jalankan shortlist lokal, dan buka hasil screening yang tersimpan.',
              accentColor: const Color(0xFF0F766E),
              actionLabel: hasRecruiterData ? 'Buka Screening Kandidat' : 'Butuh Integrasi Data Recruiter',
              onTap: hasRecruiterData ? _openCandidateScreening : null,
            ),
            const SizedBox(height: 12),
            _buildPrimaryActionCard(
              context: context,
              icon: Icons.support_agent,
              title: 'Asisten Recruiter',
              description:
                  'Gunakan skill recruiter untuk bantu job description, scorecard interview, pertanyaan STAR, dan analisis kandidat.',
              accentColor: const Color(0xFF2563EB),
              actionLabel: 'Buka Asisten Recruiter',
              onTap: _openHiringAssistant,
            ),
            const SizedBox(height: 24),
            Text(
              'Status Sistem',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gemma Lokal',
                    value: hasLocalAI ? 'Aktif' : (_isInitializingAI ? 'Menyiapkan' : 'Belum siap'),
                    hint: hasLocalAI
                        ? 'Siap dipakai offline'
                        : 'Dipakai untuk job posting dan bantuan recruiter',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Cloud AI',
                    value: hasCloudAI ? 'Aktif' : 'Nonaktif',
                    hint: hasCloudAI
                        ? 'Dipakai sebagai fallback'
                        : 'Opsional, tidak wajib untuk flow lokal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              title: 'Sumber Data Recruiter',
              value: hasRecruiterData ? 'Terhubung' : 'Belum dikonfigurasi',
              hint: hasRecruiterData
                  ? 'Lowongan dan kandidat dibaca dari Cloudflare KV'
                  : 'Tambahkan konfigurasi Cloudflare agar screening kandidat bisa dipakai',
              fullWidth: true,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Tools Debug',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Dipakai untuk verifikasi internal selama development',
                ),
                children: [
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openGemmaProof,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Cek Gemma Lokal'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
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
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Buka Legacy Chat'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              hasRecruiterData
                  ? 'Aplikasi siap dipakai untuk alur lowongan dan screening recruiter.'
                  : 'Aktifkan Cloudflare KV jika ingin memakai data lowongan dan kandidat yang tersimpan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
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
          cloudApiKey: _readConfig('OPENAI_API_KEY'),
        );
    _hybridService ??= service;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostingChatScreen(
          apiKey: _readConfig('OPENAI_API_KEY'),
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
          cloudApiKey: _readConfig('OPENAI_API_KEY'),
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
          cloudApiKey: _readConfig('OPENAI_API_KEY'),
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
          cloudApiKey: _readConfig('OPENAI_API_KEY'),
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

  Widget _buildPrimaryActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required String actionLabel,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String hint,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
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
}
