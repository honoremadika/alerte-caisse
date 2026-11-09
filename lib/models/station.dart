import 'package:cloud_firestore/cloud_firestore.dart';

/// Poste de caisse (ordinateur) : `stations/{id}`.
/// Créé par le PC, validé une seule fois par un manager du magasin.
class Station {
  final String id;
  final String storeId;
  final String register;
  final String code; // 4 chiffres affichés sur le PC et sur le téléphone du manager
  final String status; // pending | approved | refused
  final String? approvedByName;
  final String? pcName;
  final DateTime? createdAt;

  Station({
    required this.id,
    required this.storeId,
    required this.register,
    required this.code,
    required this.status,
    this.approvedByName,
    this.pcName,
    this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRefused => status == 'refused';

  factory Station.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final c = d['createdAt'];
    return Station(
      id: doc.id,
      storeId: (d['storeId'] ?? '').toString(),
      register: (d['register'] ?? '').toString(),
      code: (d['code'] ?? '').toString(),
      status: (d['status'] ?? 'pending').toString(),
      approvedByName: d['approvedByName']?.toString(),
      pcName: d['pcName']?.toString(),
      createdAt: c is Timestamp ? c.toDate() : null,
    );
  }
}
