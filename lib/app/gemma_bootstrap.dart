import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

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
  }
}
