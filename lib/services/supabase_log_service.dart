import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/runtime_config.dart';
import '../flavors/flavor_manager.dart';
import 'shared_identity_service.dart';

class SupabaseLogService {
  SupabaseLogService._();

  static final SupabaseLogService instance = SupabaseLogService._();
  bool _initialized = false;
  Future<void>? _initializationFuture;

  static const String _defaultSupabaseUrl =
      'https://rprdvmnxdmlhlbgdkhkx.supabase.co';
  static const String _defaultSupabasePublishableKey =
      'sb_publishable__0zRF8LyDQaGtFF2IJSt9g_YX33se4o';

  String get _supabaseUrl {
    final configured = readConfig('SUPABASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    return _defaultSupabaseUrl;
  }

  String get _supabaseAnonKey {
    final anonConfigured = readConfig('SUPABASE_ANON_KEY');
    if (anonConfigured.isNotEmpty) {
      return anonConfigured;
    }
    final configured = readConfig('SUPABASE_PUBLISHABLE_KEY');
    if (configured.isNotEmpty) {
      return configured;
    }
    return _defaultSupabasePublishableKey;
  }

  bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  Future<void> initialize() async {
    if (!isConfigured || _initialized) {
      return;
    }

    final inFlight = _initializationFuture;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future =
        Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey).then((
          _,
        ) {
          _initialized = true;
        });
    _initializationFuture = future;

    try {
      await future;
    } finally {
      _initializationFuture = null;
    }
  }

  void prime() {
    unawaited(initialize());
  }

  Future<void> log({
    required String level,
    required String eventType,
    required String message,
    String? screen,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isConfigured) {
      return;
    }

    final payload = <String, dynamic>{
      'level': level,
      'event_type': eventType,
      'message': message,
      if (screen != null && screen.isNotEmpty) 'screen': screen,
      'metadata': _sanitizeJson(<String, dynamic>{
        ..._baseMetadata(),
        if (metadata != null) ...metadata,
      }),
    };

    try {
      await initialize();
      await Supabase.instance.client.from('app_logs').insert(payload);
    } catch (e, st) {
      debugPrint(
        '[SupabaseLogService] Failed to send log '
        'eventType=$eventType level=$level error=$e payload=$payload',
      );
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> reportError({
    required String eventType,
    required Object error,
    StackTrace? stackTrace,
    String? screen,
    bool fatal = false,
    Map<String, dynamic>? metadata,
  }) {
    return log(
      level: fatal ? 'fatal' : 'error',
      eventType: eventType,
      message: error.toString(),
      screen: screen,
      metadata: <String, dynamic>{
        'error_type': error.runtimeType.toString(),
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
        if (metadata != null) ...metadata,
      },
    );
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String? _currentUserId() {
    try {
      return SharedIdentityService.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String? _currentFlavor() {
    try {
      return FlavorManager.flavor.type.name;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _baseMetadata() {
    return <String, dynamic>{
      'platform': _platformLabel(),
      'build_mode': kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
      'user_id': _currentUserId(),
      'flavor': _currentFlavor(),
      'captured_at': DateTime.now().toIso8601String(),
    };
  }

  Object? _sanitizeJson(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _sanitizeJson(nestedValue)),
      );
    }

    if (value is Iterable) {
      return value.map(_sanitizeJson).toList(growable: false);
    }

    return value.toString();
  }
}
