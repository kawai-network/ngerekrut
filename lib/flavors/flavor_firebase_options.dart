import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'app_flavor_config.dart';
import 'flavor_manager.dart';

class FlavorFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    final flavorName = FlavorManager.flavor.type == AppFlavorType.recruiter
        ? 'RECRUITER'
        : 'JOBSEEKER';
    final defaults = _defaultsForCurrentPlatform;

    final apiKey = _read('FIREBASE_${flavorName}_API_KEY', defaults.apiKey);
    final appId = _read('FIREBASE_${flavorName}_APP_ID', defaults.appId);
    final messagingSenderId = _read(
      'FIREBASE_${flavorName}_MESSAGING_SENDER_ID',
      defaults.messagingSenderId,
    );
    final projectId = _read('FIREBASE_${flavorName}_PROJECT_ID', defaults.projectId);

    if ([apiKey, appId, messagingSenderId, projectId].any((value) => value.isEmpty)) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _read('FIREBASE_${flavorName}_STORAGE_BUCKET', defaults.storageBucket),
      authDomain: _read('FIREBASE_${flavorName}_AUTH_DOMAIN', defaults.authDomain),
      iosBundleId: _read('FIREBASE_${flavorName}_IOS_BUNDLE_ID', defaults.iosBundleId),
      measurementId: _read(
        'FIREBASE_${flavorName}_MEASUREMENT_ID',
        defaults.measurementId,
      ),
    );
  }

  static String _read(String key, String fallback) =>
      String.fromEnvironment(key, defaultValue: fallback);

  static _FlavorFirebaseDefaults get _defaultsForCurrentPlatform {
    if (kIsWeb) {
      return _webDefaults;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FlavorManager.flavor.type == AppFlavorType.recruiter
            ? _recruiterAndroidDefaults
            : _jobSeekerAndroidDefaults;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FlavorManager.flavor.type == AppFlavorType.recruiter
            ? _recruiterIosDefaults
            : _jobSeekerIosDefaults;
      default:
        return FlavorManager.flavor.type == AppFlavorType.recruiter
            ? _recruiterAndroidDefaults
            : _jobSeekerAndroidDefaults;
    }
  }

  static const _recruiterAndroidDefaults = _FlavorFirebaseDefaults(
    apiKey: 'AIzaSyBDYCP31wwk117yPRMkCadh6NVmbmQcvzE',
    appId: '1:997263720715:android:d03c55860a0816eddde20e',
    messagingSenderId: '997263720715',
    projectId: 'ngerekrut',
    storageBucket: 'ngerekrut.firebasestorage.app',
  );

  static const _jobSeekerAndroidDefaults = _FlavorFirebaseDefaults(
    apiKey: 'AIzaSyBDYCP31wwk117yPRMkCadh6NVmbmQcvzE',
    appId: '1:997263720715:android:acea374ebf122aeddde20e',
    messagingSenderId: '997263720715',
    projectId: 'ngerekrut',
    storageBucket: 'ngerekrut.firebasestorage.app',
  );

  static const _recruiterIosDefaults = _FlavorFirebaseDefaults(
    apiKey: 'AIzaSyCaorxn9hF-Zqm7XXLzBoZiAr6BmQOJ3Go',
    appId: '1:997263720715:ios:b91925f3d867e503dde20e',
    messagingSenderId: '997263720715',
    projectId: 'ngerekrut',
    storageBucket: 'ngerekrut.firebasestorage.app',
    iosBundleId: 'com.ngerekrut.recruiter',
  );

  static const _jobSeekerIosDefaults = _FlavorFirebaseDefaults(
    apiKey: 'AIzaSyCaorxn9hF-Zqm7XXLzBoZiAr6BmQOJ3Go',
    appId: '1:997263720715:ios:6f280722ce77134ddde20e',
    messagingSenderId: '997263720715',
    projectId: 'ngerekrut',
    storageBucket: 'ngerekrut.firebasestorage.app',
    iosBundleId: 'com.ngerekrut.jobseeker',
  );

  static const _webDefaults = _FlavorFirebaseDefaults(
    apiKey: 'AIzaSyBFHtOHvg5NtvQQN_Qc0s8-s3g4G9FDC94',
    appId: '1:997263720715:web:e2da61761ff7c12edde20e',
    messagingSenderId: '997263720715',
    projectId: 'ngerekrut',
    storageBucket: 'ngerekrut.firebasestorage.app',
    authDomain: 'ngerekrut.firebaseapp.com',
    measurementId: 'G-TW9N8MJ8SX',
  );
}

class _FlavorFirebaseDefaults {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;
  final String authDomain;
  final String iosBundleId;
  final String measurementId;

  const _FlavorFirebaseDefaults({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
    this.authDomain = '',
    this.iosBundleId = '',
    this.measurementId = '',
  });
}
