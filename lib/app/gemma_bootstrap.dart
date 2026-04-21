import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../services/supabase_log_service.dart';
import 'runtime_config.dart';

/// Best-effort plugin bootstrap. Failures here must not block app startup.
Future<void> bootstrapGemma() async {
  if (kIsWeb) {
    debugPrint('[GemmaBootstrap] Skipped on web');
    return;
  }

  try {
    await FlutterGemma.initialize(
      huggingFaceToken: readConfig('HUGGINGFACE_TOKEN'),
    );
    debugPrint('[GemmaBootstrap] Plugin initialized');
  } catch (e, st) {
    debugPrint('[GemmaBootstrap] Initialization failed: $e');
    debugPrintStack(stackTrace: st);
    unawaited(
      SupabaseLogService.instance.reportError(
        eventType: 'gemma_bootstrap_failed',
        error: e,
        stackTrace: st,
        metadata: {'component': 'flutter_gemma'},
      ),
    );
  }
}
