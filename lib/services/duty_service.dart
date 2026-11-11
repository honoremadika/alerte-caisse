import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/store.dart';
import 'duty_background.dart';

/// Prise de service : seuls les managers « en service » dans un magasin
/// reçoivent ses alertes. Le manager choisit son magasin dans la liste
/// (pas de GPS : aucune permission de localisation demandée).
class DutyService {
  /// Durée d'un service : il se termine tout seul ensuite, pour qu'un
  /// manager rentré chez lui sans « Terminer » ne soit plus réveillé.
  static const shift = Duration(hours: 12);

  final _users = FirebaseFirestore.instance.collection('users');

  /// Renvoie null si OK, sinon un message d'erreur à afficher.
  Future<String?> start(AppUser manager, Store store) async {
    final until = DateTime.now().add(shift);
    await _users.doc(manager.uid).update({
      'onDuty': true,
      'dutyStoreId': store.id,
      'dutyUntil': Timestamp.fromDate(until),
    });
    // Version gratuite : le téléphone écoute lui-même les alertes du magasin.
    await DutyBackground.start(
      storeId: store.id,
      storeName: store.name,
      lang: AppLang.instance.value,
      until: until,
    );
    return null;
  }

  Future<void> end(String uid) async {
    try {
      await DutyBackground.stop();
    } catch (_) {}
    await _users.doc(uid).update({
      'onDuty': false,
      'dutyUntil': FieldValue.delete(),
    });
  }
}
