import 'dart:io' show Platform;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/station.dart';

/// Poste de caisse sans identifiant ni mot de passe :
///  1. le PC ouvre une session anonyme (rien à taper) ;
///  2. une seule fois, on tape le code du magasin (ex. KM06-7F3K9P) et le n° de caisse ;
///  3. le poste est accepté tout de suite et envoie ses alertes, même après redémarrage.
class StationService {
  StationService._();
  static final instance = StationService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  static const _kId = 'stationId';
  static const _kUid = 'stationUid';
  static const _kName = 'cashierName';

  Future<User> ensureSession() async {
    var u = _auth.currentUser;
    if (u == null) {
      // Au démarrage, Windows peut mettre un instant à retrouver la session gardée.
      try {
        u = await _auth.authStateChanges().first.timeout(const Duration(seconds: 4));
      } catch (_) {}
      u ??= _auth.currentUser;
    }
    if (u != null) return u;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<String?> savedId() async => (await SharedPreferences.getInstance()).getString(_kId);

  /// Après une nouvelle session (Windows réinstallé, session perdue), on relie
  /// le poste à la nouvelle session : pas besoin d'une nouvelle validation.
  Future<void> rebindIfNeeded(String sid) async {
    final uid = (await ensureSession()).uid;
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kUid) == uid) return;
    final batch = _db.batch()
      ..update(_db.collection('stations').doc(sid), {'uid': uid})
      ..set(_db.collection('stationUids').doc(uid), {'sid': sid});
    await batch.commit();
    await p.setString(_kUid, uid);
  }

  /// Demande de poste : magasin + numéro de caisse. Renvoie l'identifiant.
  Future<String> request(String storeId, String register) async {
    final uid = (await ensureSession()).uid;
    final ref = _db.collection('stations').doc(); // identifiant aléatoire (secret)
    final code = (1000 + Random.secure().nextInt(9000)).toString();
    String pc = '';
    try {
      pc = Platform.localHostname;
    } catch (_) {}
    final batch = _db.batch()
      ..set(ref, {
        'storeId': storeId,
        'register': register.trim(),
        'uid': uid,
        'code': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (pc.isNotEmpty) 'pcName': pc.length > 40 ? pc.substring(0, 40) : pc,
      })
      ..set(_db.collection('stationUids').doc(uid), {'sid': ref.id});
    await batch.commit();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, ref.id);
    await p.setString(_kUid, uid);
    return ref.id;
  }

  /// Normalise un code tapé : « km06 7f3k9p » -> « KM06-7F3K9P ».
  static String normalizeCode(String raw) {
    final c = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final m = RegExp(r'^(KM\d{2})([A-Z0-9]{6})$').firstMatch(c);
    return m == null ? c : '${m.group(1)}-${m.group(2)}';
  }

  /// Poste ouvert avec le code du magasin. Lève 'bad-code' si le code est inconnu.
  Future<String> joinWithCode(String rawCode, String register) async {
    final uid = (await ensureSession()).uid;
    final code = normalizeCode(rawCode);
    if (code.length < 6) throw StateError('bad-code');
    final snap = await _db.collection('stationCodes').doc(code).get();
    final storeId = (snap.data()?['storeId'] ?? '').toString();
    if (!snap.exists || storeId.isEmpty) throw StateError('bad-code');
    final ref = _db.collection('stations').doc(); // identifiant aléatoire (secret)
    String pc = '';
    try {
      pc = Platform.localHostname;
    } catch (_) {}
    final batch = _db.batch()
      ..set(ref, {
        'storeId': storeId,
        'register': register.trim(),
        'uid': uid,
        'code': code,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        if (pc.isNotEmpty) 'pcName': pc.length > 40 ? pc.substring(0, 40) : pc,
      })
      ..set(_db.collection('stationUids').doc(uid), {'sid': ref.id});
    await batch.commit();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kId, ref.id);
    await p.setString(_kUid, uid);
    return ref.id;
  }

  /// Côté manager : code de poste de chacun de ses magasins.
  Future<Map<String, String>> codesFor(List<String> storeIds) async {
    final out = <String, String>{};
    await Future.wait(storeIds.map((id) async {
      try {
        final d = await _db.collection('storeCodes').doc(id).get();
        final c = d.data()?['code'];
        if (c != null) out[id] = c.toString();
      } catch (_) {}
    }));
    return out;
  }

  /// Oublier ce poste (PC déplacé dans un autre magasin, demande refusée).
  Future<void> forget() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kUid);
  }

  Stream<Station?> watch(String sid) => _db
      .collection('stations')
      .doc(sid)
      .snapshots()
      .map((d) => d.exists ? Station.fromDoc(d) : null);

  /// Nom du caissier (facultatif), gardé sur ce PC.
  Future<String> cashierName() async =>
      (await SharedPreferences.getInstance()).getString(_kName) ?? '';
  Future<void> setCashierName(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kName, v.trim());

  /// Le poste vu comme un « caissier » pour l'envoi des alertes.
  AppUser asCashier(Station s, String name) => AppUser(
        uid: _auth.currentUser?.uid ?? '',
        name: name.trim().isEmpty ? 'Caisse ${s.register}' : name.trim(),
        role: 'cashier',
        register: s.register,
        storeId: s.storeId,
        storeIds: const [],
        onDuty: false,
      );

  // ---------- Côté manager ----------

  /// Postes en attente de validation dans un magasin.
  Stream<List<Station>> pending(String storeId) => _db
      .collection('stations')
      .where('storeId', isEqualTo: storeId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map(Station.fromDoc).toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0))));

  Future<void> decide(Station s, AppUser manager, bool approve) =>
      _db.collection('stations').doc(s.id).update({
        'status': approve ? 'approved' : 'refused',
        'approvedBy': manager.uid,
        'approvedByName': manager.name,
        'approvedAt': FieldValue.serverTimestamp(),
      });
}
