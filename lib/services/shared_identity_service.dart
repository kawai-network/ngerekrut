library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SharedIdentityService {
  const SharedIdentityService._();

  static const List<String> _calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

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
    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate(
      scopeHint: _calendarScopes,
    );
    await googleUser.authorizationClient.authorizeScopes(_calendarScopes);
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
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
