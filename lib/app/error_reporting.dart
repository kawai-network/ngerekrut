import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/supabase_log_service.dart';

Future<void> runWithErrorReporting({
  required String appEntrypoint,
  required String appFlavor,
  required Future<void> Function() body,
}) async {
  final previousFlutterErrorHandler = FlutterError.onError;

  FlutterError.onError = (details) {
    previousFlutterErrorHandler?.call(details);
    if (previousFlutterErrorHandler == null) {
      FlutterError.presentError(details);
    }

    unawaited(
      SupabaseLogService.instance.reportError(
        eventType: 'flutter_error',
        error: details.exception,
        stackTrace: details.stack,
        fatal: true,
        metadata: {
          'library': details.library,
          'context': details.context?.toDescription(),
          'information_collector': details.informationCollector?.call().join(
            '\n',
          ),
          'app_entrypoint': appEntrypoint,
          'app_flavor': appFlavor,
        },
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(
      SupabaseLogService.instance.reportError(
        eventType: 'platform_dispatcher_error',
        error: error,
        stackTrace: stackTrace,
        fatal: true,
        metadata: {'app_entrypoint': appEntrypoint, 'app_flavor': appFlavor},
      ),
    );
    return false;
  };

  await runZonedGuarded(body, (error, stackTrace) {
    unawaited(
      SupabaseLogService.instance.reportError(
        eventType: 'zone_uncaught_error',
        error: error,
        stackTrace: stackTrace,
        fatal: true,
        metadata: {'app_entrypoint': appEntrypoint, 'app_flavor': appFlavor},
      ),
    );
  });
}
