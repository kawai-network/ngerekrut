import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'repositories/hiring_repository.dart';
import 'repositories/local_interview_guide_repository.dart';
import 'repositories/local_scorecard_repository.dart';
import 'repositories/local_shortlist_repository.dart';
import 'screens/full_chat_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.work, size: 24),
            SizedBox(width: 8),
            Text('NgeRekrut'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF18CD5B), Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'Bikin Lowongan Sekali Prompt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ketik posisi yang kamu butuh, AI akan buatkan job posting lengkap.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isInitializingAI)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
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
              // Feature buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JobPostingChatScreen(
                        // TODO: Replace with your OpenAI API key
                        apiKey: String.fromEnvironment('OPENAI_API_KEY'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Bikin Lowongan (Chat)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _hiringRepository == null
                    ? null
                    : () {
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
                        repository: _hiringRepository!,
                        localInterviewGuideRepository:
                            _localInterviewGuideRepository,
                        localShortlistRepository: _localShortlistRepository,
                        localScorecardRepository: _localScorecardRepository,
                        interviewGuideGenerationService:
                            InterviewGuideGenerationService(
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
                },
                icon: const Icon(Icons.groups_2),
                label: const Text('Recruiter Screening Flow'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
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
                label: const Text('Chat Demo (Existing)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final service =
                      _hybridService ??
                      HybridAIService(
                        cloudApiKey: const String.fromEnvironment(
                          'OPENAI_API_KEY',
                        ),
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
                },
                icon: const Icon(Icons.badge),
                label: const Text('AI Hiring Assistant'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '🤖 AI Hiring Assistant berjalan dengan Gemma secara lokal.\n\n💡 Tambahkan --dart-define=OPENAI_API_KEY=your_key jika ingin mengaktifkan fallback Cloud AI.'
                '\n\n🌐 Recruiter flow membaca data langsung dari Cloudflare KV.'
                '\nButuh --dart-define=CLOUDFLARE_ACCOUNT_ID=...'
                '\n--dart-define=CLOUDFLARE_KV_NAMESPACE_ID=...'
                '\n--dart-define=CLOUDFLARE_API_TOKEN=...'
                '${_hiringRepository == null ? '\nSaat ini akses Cloudflare KV belum dikonfigurasi.' : ''}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
