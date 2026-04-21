library;

import 'package:firebase_auth/firebase_auth.dart';

class SharedIdentityService {
  const SharedIdentityService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

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

  static Future<void> signOut() => _auth.signOut();
}
