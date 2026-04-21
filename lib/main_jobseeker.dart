import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth/auth_gate.dart';
import 'app/gemma_bootstrap.dart';
import 'app/runtime_config.dart';
import 'flavors/app_flavor_config.dart';
import 'flavors/flavor_environment.dart';
import 'flavors/flavor_firebase_options.dart';
import 'flavors/flavor_manager.dart';
import 'screens/job_seeker_home_screen.dart';
import 'services/hybrid_database_service.dart';

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

  await messaging.requestPermission(alert: true, badge: true, sound: true);

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
  await loadEnv();
  await bootstrapGemma();

  // Initialize hybrid database (libsql_dart for shared data)
  await hybridDatabase.autoInit();

  FlavorManager.init(
    AppFlavorConfig.jobSeeker,
    environment: FlavorEnvironment.fromConfig(),
  );
  // Only initialize Firebase on supported platforms
  final isSupportedPlatform =
      kIsWeb || (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
  if (isSupportedPlatform) {
    try {
      final options = FlavorFirebaseOptions.currentPlatform;
      if (options == null) {
        debugPrint(
          'Firebase disabled for job seeker flavor. '
          'Set FIREBASE_JOBSEEKER_* dart-defines before release builds.',
        );
      } else {
        await Firebase.initializeApp(options: options);
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await _initializeFirebaseMessaging();
      }
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
      title: FlavorManager.flavor.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(int.parse(FlavorManager.flavor.primaryColor)),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(
        title: 'Masuk ke NgeRekrut Jobseeker',
        description:
            'Gunakan akun Firebase Auth untuk menyimpan lamaran, lowongan tersimpan, dan profil kandidat Anda.',
        requestCalendarAccess: true,
        child: JobSeekerHomeScreen(),
      ),
    );
  }
}
