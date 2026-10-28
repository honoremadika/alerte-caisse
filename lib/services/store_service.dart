import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store.dart';

class StoreService {
  final _stores = FirebaseFirestore.instance.collection('stores');

  Stream<Store?> watch(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _stores.doc(id).snapshots().map((d) => d.exists ? Store.fromDoc(d) : null);
  }

  /// Magasins d'un manager (30 maximum, limite Firestore).
  Future<List<Store>> list(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap = await _stores
        .where(FieldPath.documentId, whereIn: ids.take(30).toList())
        .get();
    return snap.docs.map(Store.fromDoc).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
