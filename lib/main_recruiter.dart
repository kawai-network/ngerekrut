import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'flavors/app_flavor_config.dart';
import 'flavors/flavor_environment.dart';
import 'flavors/flavor_firebase_options.dart';
import 'flavors/flavor_manager.dart';
import 'main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = FlavorFirebaseOptions.currentPlatform;
  if (options == null) {
    return;
  }
  await Firebase.initializeApp(options: options);
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

  FlavorManager.init(
    AppFlavorConfig.recruiter,
    environment: FlavorEnvironment.fromConfig(),
  );
  // Only initialize Firebase on supported platforms
  final isSupportedPlatform = kIsWeb ||
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  if (isSupportedPlatform) {
    try {
      final options = FlavorFirebaseOptions.currentPlatform;
      if (options == null) {
        debugPrint(
          'Firebase disabled for recruiter flavor. '
          'Set FIREBASE_RECRUITER_* dart-defines before release builds.',
        );
      } else {
        await Firebase.initializeApp(options: options);
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
        await _initializeFirebaseMessaging();
      }
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
      title: FlavorManager.flavor.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(int.parse(FlavorManager.flavor.primaryColor)),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
