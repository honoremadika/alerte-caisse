import 'package:cloud_firestore/cloud_firestore.dart';

/// Profil stocké dans `users/{uid}`.
///  - caissier : role 'cashier', storeId, register
///  - manager  : role 'manager', storeIds (magasins où il peut travailler),
///               onDuty / dutyStoreId / dutyUntil (prise de service)
class AppUser {
  final String uid;
  final String name;
  final String role;
  final String register;
  final String storeId;
  final List<String> storeIds;
  final bool onDuty;
  final String? dutyStoreId;
  final DateTime? dutyUntil;

  AppUser({
    required this.uid,
    required this.name,
    required this.role,
    required this.register,
    required this.storeId,
    required this.storeIds,
    required this.onDuty,
    this.dutyStoreId,
    this.dutyUntil,
  });

  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';

  /// En service et pas encore expiré.
  bool get isOnDutyNow =>
      onDuty && dutyUntil != null && dutyUntil!.isAfter(DateTime.now());

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final until = d['dutyUntil'];
    return AppUser(
      uid: doc.id,
      name: d['name'] ?? '—',
      role: d['role'] ?? 'cashier',
      register: (d['register'] ?? '').toString(),
      storeId: d['storeId'] ?? '',
      storeIds: List<String>.from(d['storeIds'] ?? const []),
      onDuty: d['onDuty'] == true,
      dutyStoreId: d['dutyStoreId'],
      dutyUntil: until is Timestamp ? until.toDate() : null,
    );
  }
}
