import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alert.dart';
import '../models/alert_types.dart';
import '../models/app_user.dart';

class AlertService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _alerts => _db.collection('alerts');

  List<CaisseAlert> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(CaisseAlert.fromDoc).toList();

  /// Le caissier envoie une alerte à SON magasin uniquement.
  Future<void> send({
    required AppUser cashier,
    required AlertType type,
    String message = '',
  }) {
    return _alerts.add({
      'storeId': cashier.storeId,
      'type': type.key,
      'typeFr': type.fr,
      'typeEn': type.en,
      'message': message.trim(),
      'register': cashier.register,
      'cashierId': cashier.uid,
      'cashierName': cashier.name,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Alertes en cours d'un magasin (écran manager).
  Stream<List<CaisseAlert>> active(String storeId) => _alerts
      .where('storeId', isEqualTo: storeId)
      .where('status', whereIn: ['open', 'taken'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_map);

  /// Alertes en cours d'un caissier (le filtre magasin est exigé par les règles).
  Stream<List<CaisseAlert>> activeFor(AppUser cashier) => _alerts
      .where('storeId', isEqualTo: cashier.storeId)
      .where('cashierId', isEqualTo: cashier.uid)
      .where('status', whereIn: ['open', 'taken'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_map);

  /// Historique d'un magasin (300 dernières alertes).
  Stream<List<CaisseAlert>> history(String storeId) => _alerts
      .where('storeId', isEqualTo: storeId)
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots()
      .map(_map);

  /// Nombre de managers en service dans un magasin (pour avertir le caissier).
  Stream<int> managersOnDuty(String storeId) => _db
      .collection('users')
      .where('role', isEqualTo: 'manager')
      .where('onDuty', isEqualTo: true)
      .where('dutyStoreId', isEqualTo: storeId)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).where((u) => u.isOnDutyNow).length);

  /// « J'arrive ». Un seul manager peut prendre l'alerte.
  /// Renvoie null si c'est bon, sinon le nom de celui qui l'a déjà prise.
  /// Le serveur arrête alors la sonnerie sur les autres téléphones.
  Future<String?> take(String alertId, AppUser manager) {
    final ref = _alerts.doc(alertId);
    return _db.runTransaction<String?>((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data();
      if (d == null) return '—';
      if (d['status'] != 'open') return (d['takenByName'] ?? '—').toString();
      tx.update(ref, {
        'status': 'taken',
        'takenAt': FieldValue.serverTimestamp(),
        'takenBy': manager.uid,
        'takenByName': manager.name,
      });
      return null;
    });
  }

  Future<void> resolve(String alertId, AppUser manager) =>
      _alerts.doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': manager.uid,
        'resolvedByName': manager.name,
      });

  Future<void> cancel(String alertId) => _alerts.doc(alertId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
}
