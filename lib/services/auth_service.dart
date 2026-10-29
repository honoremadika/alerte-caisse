import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';

/// Connexion par IDENTIFIANT (ex. « meya ») ou par email.
/// L'identifiant est traduit en email grâce à la collection `logins/{id}`
/// (lisible avant connexion), remplie par l'outil tools/donnees.js.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static final _idPattern = RegExp(r'^[a-z0-9._-]{2,40}$');

  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<String> _emailFor(String login) async {
    final l = login.trim().toLowerCase();
    if (l.contains('@')) return l;
    if (!_idPattern.hasMatch(l)) {
      throw FirebaseAuthException(code: 'invalid-login');
    }
    final doc = await _db.collection('logins').doc(l).get();
    final email = doc.data()?['email'];
    if (email is String && email.contains('@')) return email;
    throw FirebaseAuthException(code: 'user-not-found');
  }

  Future<void> signIn(String login, String password) async {
    final email = await _emailFor(login);
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Changer son mot de passe : il faut redonner l'actuel (exigence Firebase).
  Future<void> changePassword(String current, String next) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    final cred = EmailAuthProvider.credential(email: user.email!, password: current);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(next);
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AppUser?> profile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> saveLang(String uid, String lang) =>
      _db.collection('users').doc(uid).update({'lang': lang});

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return tr('errCredentials');
        case 'invalid-login':
          return tr('errLoginFormat');
        case 'weak-password':
          return tr('pwTooShort');
        case 'network-request-failed':
          return tr('errNetwork');
        case 'too-many-requests':
          return tr('errTooMany');
        case 'requires-recent-login':
          return tr('errRelogin');
      }
    }
    if (e is FirebaseException && e.code == 'unavailable') return tr('errNetwork');
    return tr('errGeneric');
  }
}
