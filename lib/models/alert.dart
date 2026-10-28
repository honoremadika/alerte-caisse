import 'package:cloud_firestore/cloud_firestore.dart';

/// Statuts : open (en attente), taken (un manager arrive), resolved, cancelled.
class CaisseAlert {
  final String id;
  final String storeId;
  final String type;
  final String typeFr;
  final String typeEn;
  final String message;
  final String register;
  final String cashierId;
  final String cashierName;
  final String status;
  final DateTime? createdAt;
  final DateTime? takenAt;
  final String? takenBy;
  final String? takenByName;
  final DateTime? resolvedAt;

  CaisseAlert({
    required this.id,
    required this.storeId,
    required this.type,
    required this.typeFr,
    required this.typeEn,
    required this.message,
    required this.register,
    required this.cashierId,
    required this.cashierName,
    required this.status,
    this.createdAt,
    this.takenAt,
    this.takenBy,
    this.takenByName,
    this.resolvedAt,
  });

  /// Le libellé est copié dans l'alerte à l'envoi : l'historique reste juste
  /// même si la liste des problèmes du magasin change plus tard.
  String typeLabel(String lang) => lang == 'en' ? typeEn : typeFr;

  Duration? get reactionTime =>
      (createdAt != null && takenAt != null) ? takenAt!.difference(createdAt!) : null;

  Duration? get resolutionTime =>
      (createdAt != null && resolvedAt != null) ? resolvedAt!.difference(createdAt!) : null;

  static DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;

  factory CaisseAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CaisseAlert(
      id: doc.id,
      storeId: d['storeId'] ?? '',
      type: d['type'] ?? 'autre',
      typeFr: d['typeFr'] ?? 'Alerte',
      typeEn: d['typeEn'] ?? d['typeFr'] ?? 'Alert',
      message: d['message'] ?? '',
      register: (d['register'] ?? '').toString(),
      cashierId: d['cashierId'] ?? '',
      cashierName: d['cashierName'] ?? '',
      status: d['status'] ?? 'open',
      createdAt: _date(d['createdAt']),
      takenAt: _date(d['takenAt']),
      takenBy: d['takenBy'],
      takenByName: d['takenByName'],
      resolvedAt: _date(d['resolvedAt']),
    );
  }
}
