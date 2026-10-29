import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/store.dart';

class StoreService {
  final _stores = FirebaseFirestore.instance.collection('stores');

  Stream<Store?> watch(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _stores.doc(id).snapshots().map((d) => d.exists ? Store.fromDoc(d) : null);
  }

  /// Magasins d'un manager. On lit toute la collection (40 magasins) puis on
  /// filtre : la requête « whereIn » de Firestore est limitée à 30 valeurs.
  Future<List<Store>> list(List<String> ids) async {
    if (ids.isEmpty) return [];
    final wanted = ids.toSet();
    final snap = await _stores.get();
    return snap.docs.where((d) => wanted.contains(d.id)).map(Store.fromDoc).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
}
