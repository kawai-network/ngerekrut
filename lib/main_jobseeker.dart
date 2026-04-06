import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'flavors/app_flavor_config.dart';
import 'flavors/flavor_manager.dart';
import 'screens/job_seeker_home_screen.dart';

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
  
  // Initialize job seeker flavor
  FlavorManager.init(AppFlavorConfig.jobSeeker);
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorManager.flavor.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(int.parse(FlavorManager.flavor.primaryColor)),
        ),
        useMaterial3: true,
      ),
      home: const JobSeekerHomeScreen(),
    );
  }
}
