import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_gate.dart';
import 'app/error_reporting.dart';
import 'app/recruiter_app.dart';
import 'app/gemma_bootstrap.dart';
import 'app/runtime_config.dart';
import 'flavors/app_flavor_config.dart';
import 'flavors/flavor_environment.dart';
import 'flavors/flavor_firebase_options.dart';
import 'flavors/flavor_manager.dart';
import 'services/hybrid_database_service.dart';
import 'services/onesignal_service.dart';
import 'services/shared_identity_service.dart';
import 'services/supabase_log_service.dart';

Future<void> _initializeOneSignal() async {
  // Initialize OneSignal
  await OneSignalService.instance.initialize();

  // Set external user ID when Firebase Auth state changes
  SharedIdentityService.authStateChanges().listen((user) {
    if (user != null) {
      OneSignalService.instance.setExternalUserId(user.uid);
      // Set recruiter tag
      OneSignalService.instance.addTag('user_type', 'recruiter');
    } else {
      OneSignalService.instance.removeExternalUserId();
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  SupabaseLogService.instance.prime();
  await runWithErrorReporting(
    appEntrypoint: 'main_recruiter',
    appFlavor: AppFlavorType.recruiter.name,
    body: () async {
      await bootstrapGemma();

      // Initialize hybrid database (libsql_dart for shared data)
      await hybridDatabase.autoInit();

      FlavorManager.init(
        AppFlavorConfig.recruiter,
        environment: FlavorEnvironment.fromConfig(),
      );

      // Initialize Firebase (Auth only)
      final isSupportedPlatform =
          kIsWeb || (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
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
            // Initialize OneSignal for push notifications
            await _initializeOneSignal();
          }
        } on Exception catch (e, st) {
          debugPrint('Firebase initialization failed: $e');
          unawaited(
            SupabaseLogService.instance.reportError(
              eventType: 'firebase_initialization_failed',
              error: e,
              stackTrace: st,
              fatal: false,
              metadata: {
                'app_entrypoint': 'main_recruiter',
                'app_flavor': AppFlavorType.recruiter.name,
              },
            ),
          );
        }
      }

      runApp(
        const RecruiterApp(
          title: 'NgeRekrut Recruiter',
          homeOverride: AuthGate(
            title: 'Masuk ke NgeRekrut Recruiter',
            description:
                'Gunakan akun Firebase Auth untuk mengelola lowongan, lamaran, dan kandidat.',
            requestCalendarAccess: true,
            child: RecruiterHomeScreen(),
          ),
        ),
      );
    },
  );
}
