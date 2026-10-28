import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  Stream<AppUser?> profile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  /// Mémorise la langue sur le profil : le serveur envoie les
  /// notifications dans la langue de chaque manager.
  Future<void> saveLang(String uid, String lang) =>
      _db.collection('users').doc(uid).update({'lang': lang});

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return tr('errCredentials');
        case 'invalid-email':
          return tr('errEmail');
        case 'network-request-failed':
          return tr('errNetwork');
        case 'too-many-requests':
          return tr('errTooMany');
      }
    }
    return tr('errGeneric');
  }
}
