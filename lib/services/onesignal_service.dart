/// OneSignal Push Notification Service
///
/// Handles push notifications via OneSignal
library;

import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'shared_identity_service.dart';
import 'hybrid_database_service.dart';
import '../app/runtime_config.dart';

class OneSignalService {
  OneSignalService._internal();

  static final OneSignalService instance = OneSignalService._internal();

  bool _initialized = false;
  String? _currentUserId;
  String? _currentSubscriptionId;

  /// Get current OneSignal subscription ID (device token)
  String? get subscriptionId => _currentSubscriptionId;

  /// Get current OneSignal user ID
  String? get userId => _currentUserId;

  /// Initialize OneSignal
  Future<void> initialize() async {
    if (_initialized) return;

    final appId = readConfig('ONESIGNAL_APP_ID');
    if (appId.isEmpty) {
      debugPrint('ONESIGNAL_APP_ID not configured');
      return;
    }

    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      await OneSignal.initialize(appId);

      // Request permission
      await OneSignal.Notifications.requestPermission(true);

      // Get current subscription
      final subscription = await OneSignal.User.pushSubscription;
      if (subscription != null) {
        _currentSubscriptionId = subscription.id;
        if (_currentSubscriptionId != null && _currentSubscriptionId!.isNotEmpty) {
          _saveSubscriptionForCurrentUser(_currentSubscriptionId!);
        }
      }

      _initialized = true;
      debugPrint('OneSignal setup complete');
    } catch (e) {
      debugPrint('OneSignal initialization error: $e');
    }
  }

  /// Set external user ID (Firebase Auth UID)
  Future<void> setExternalUserId(String uid) async {
    try {
      await OneSignal.User.addAlias('external_id', uid);
      _currentUserId = uid;
      debugPrint('OneSignal external user ID set: $uid');

      // Save subscription to database
      final subscription = await OneSignal.User.pushSubscription;
      if (subscription != null && subscription.id != null && subscription.id!.isNotEmpty) {
        _currentSubscriptionId = subscription.id;
        await _saveSubscriptionForCurrentUser(subscription.id!);
      }
    } catch (e) {
      debugPrint('Error setting external user ID: $e');
    }
  }

  /// Remove external user ID (when logging out)
  Future<void> removeExternalUserId() async {
    try {
      await OneSignal.User.removeAlias('external_id');
      _currentUserId = null;
      debugPrint('OneSignal external user ID removed');
    } catch (e) {
      debugPrint('Error removing external user ID: $e');
    }
  }

  /// Save OneSignal subscription ID to database
  Future<void> _saveSubscriptionForCurrentUser(String subscriptionId) async {
    try {
      final firebaseUserId = SharedIdentityService.currentUser?.uid;
      if (firebaseUserId == null || firebaseUserId.isEmpty) {
        debugPrint('No Firebase user logged in, skipping subscription save');
        return;
      }

      final platform = _getPlatform();
      await hybridDatabase.saveFcmToken(
        userId: firebaseUserId,
        token: subscriptionId, // Using same table for OneSignal subscription ID
        platform: platform,
      );
      debugPrint('OneSignal subscription saved for user: $firebaseUserId');
    } catch (e) {
      debugPrint('Error saving OneSignal subscription: $e');
    }
  }

  /// Get platform string
  String _getPlatform() {
    // OneSignal handles this internally, just return a placeholder
    return 'onesignal';
  }

  /// Clear subscription when logging out
  Future<void> clearSubscription() async {
    await removeExternalUserId();
    _currentSubscriptionId = null;
  }

  /// Add a tag (for filtering notifications)
  Future<void> addTag(String key, String value) async {
    try {
      await OneSignal.User.addTagWithKey(key, value);
      debugPrint('OneSignal tag added: $key=$value');
    } catch (e) {
      debugPrint('Error adding tag: $e');
    }
  }

  /// Delete a tag
  Future<void> deleteTag(String key) async {
    try {
      await OneSignal.User.removeTag(key);
      debugPrint('OneSignal tag deleted: $key');
    } catch (e) {
      debugPrint('Error deleting tag: $e');
    }
  }

  /// Disable push notifications
  Future<void> disableNotifications() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      await subscription.optOut();
      debugPrint('OneSignal notifications disabled');
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
    }
  }

  /// Enable push notifications
  Future<void> enableNotifications() async {
    try {
      final subscription = OneSignal.User.pushSubscription;
      await subscription.optIn();
      debugPrint('OneSignal notifications enabled');
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
    }
  }
}

/// Direct OneSignal API for sending notifications (from client)
///
/// Note: In production, you should send notifications from your backend
/// using OneSignal REST API to keep your API key secure.
class OneSignalDirectApi {
  OneSignalDirectApi._internal();

  static final OneSignalDirectApi instance = OneSignalDirectApi._internal();

  final String _baseUrl = 'https://onesignal.com/api/v1/notifications';

  /// Get OneSignal App ID from environment
  String? get _appId => readConfig('ONESIGNAL_APP_ID');
  String? get _apiKey => readConfig('ONESIGNAL_API_KEY');

  /// Send notification to specific devices
  Future<Map<String, dynamic>> sendNotification({
    required List<String> subscriptionIds, // OneSignal subscription IDs
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final appId = _appId;
    final apiKey = _apiKey;

    if (appId == null || appId.isEmpty) {
      return {'success': false, 'error': 'ONESIGNAL_APP_ID not configured'};
    }

    if (apiKey == null || apiKey.isEmpty) {
      return {'success': false, 'error': 'ONESIGNAL_API_KEY not configured'};
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'include_player_ids': subscriptionIds,
          'headings': {'en': title},
          'contents': {'en': body},
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'success': true, 'data': result};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send notification to users with specific alias (Firebase UID)
  Future<Map<String, dynamic>> sendNotificationToUser({
    required String externalUserId, // Firebase UID
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final appId = _appId;
    final apiKey = _apiKey;

    if (appId == null || appId.isEmpty) {
      return {'success': false, 'error': 'ONESIGNAL_APP_ID not configured'};
    }

    if (apiKey == null || apiKey.isEmpty) {
      return {'success': false, 'error': 'ONESIGNAL_API_KEY not configured'};
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $apiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'include_external_user_ids': [externalUserId],
          'headings': {'en': title},
          'contents': {'en': body},
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'success': true, 'data': result};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
