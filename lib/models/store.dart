import 'package:cloud_firestore/cloud_firestore.dart';

import 'alert_types.dart';

/// Un magasin : `stores/{id}`.
class Store {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final double radiusM; // rayon autorisé pour la prise de service
  final List<AlertType> alertTypes;

  Store({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    required this.radiusM,
    required this.alertTypes,
  });

  bool get hasLocation => lat != null && lng != null;

  factory Store.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final geo = d['location'];
    return Store(
      id: doc.id,
      name: d['name'] ?? doc.id,
      lat: geo is GeoPoint ? geo.latitude : null,
      lng: geo is GeoPoint ? geo.longitude : null,
      radiusM: (d['radiusM'] as num?)?.toDouble() ?? 200,
      alertTypes: alertTypesFrom(d['alertTypes']),
    );
  }
}
