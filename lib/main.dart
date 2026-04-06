import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/full_chat_screen.dart';
import 'screens/job_posting_chat_screen.dart';
import 'screens/hiring_screen.dart';
import 'services/hybrid_ai_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initHybridService();
  }

  Future<void> _initHybridService() async {
    final apiKey = const String.fromEnvironment('OPENAI_API_KEY');
    try {
      _hybridService = HybridAIService(cloudApiKey: apiKey);
      await _hybridService!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize hybrid service: $e');
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
              const Text(
                '🤖 AI Hiring Assistant berjalan dengan Gemma secara lokal.\n\n💡 Tambahkan --dart-define=OPENAI_API_KEY=your_key jika ingin mengaktifkan fallback Cloud AI.',
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
