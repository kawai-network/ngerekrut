library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'supabase_log_service.dart';

class SharedIdentityService {
  const SharedIdentityService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static bool _googleInitialized = false;

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  static User? get currentUser => _auth.currentUser;

  static String get currentUid {
    final uid = currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User not authenticated');
    }
    return uid;
  }

  static String get jobseekerUserId => currentUid;

  static String get recruiterUserId => currentUid;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Stream<User?> idTokenChanges() => _auth.idTokenChanges();

  static Future<IdTokenResult?> getIdTokenResult() async =>
      currentUser?.getIdTokenResult();

  static Future<UserCredential> signInWithGoogle() async {
    return signInWithGoogleCalendarAccess(requestCalendarAccess: false);
  }

  static Future<UserCredential> signInWithGoogleCalendarAccess({
    required bool requestCalendarAccess,
  }) async {
    try {
      await _ensureGoogleInitialized();
      // Keep account authentication separate from Calendar authorization.
      // Calendar permission is requested later by GoogleCalendarService
      // when the user explicitly uses Calendar sync features.
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google Sign-In tidak mengembalikan ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, st) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'google_sign_in_failed',
          error: e,
          stackTrace: st,
          screen: 'SignInScreen',
          metadata: {
            'provider': 'google',
            'request_calendar_access': requestCalendarAccess,
            'firebase_code': e.code,
            'firebase_message': e.message,
          },
        ),
      );
      rethrow;
    } catch (e, st) {
      unawaited(
        SupabaseLogService.instance.reportError(
          eventType: 'google_sign_in_failed',
          error: e,
          stackTrace: st,
          screen: 'SignInScreen',
          metadata: {
            'provider': 'google',
            'request_calendar_access': requestCalendarAccess,
          },
        ),
      );
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
