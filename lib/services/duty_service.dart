import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/store.dart';
import 'duty_background.dart';

/// Prise de service : seuls les managers « en service » dans un magasin
/// reçoivent ses alertes. La prise de service vérifie une seule fois
/// que le téléphone est à moins de 200 m du magasin (pas de suivi GPS
/// permanent : pas de batterie vidée, pas de vie privée exposée).
class DutyService {
  /// Durée d'un service : il se termine tout seul ensuite, pour qu'un
  /// manager rentré chez lui sans « Terminer » ne soit plus réveillé.
  static const shift = Duration(hours: 12);

  final _users = FirebaseFirestore.instance.collection('users');

  /// Renvoie null si OK, sinon un message d'erreur à afficher.
  Future<String?> start(AppUser manager, Store store) async {
    if (store.hasLocation) {
      final err = await _checkDistance(store);
      if (err != null) return err;
    }
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
    await DutyBackground.stop();
    await _users.doc(uid).update({
      'onDuty': false,
      'dutyUntil': FieldValue.delete(),
    });
  }

  Future<String?> _checkDistance(Store store) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return tr('locationNeeded');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return tr('locationNeeded');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final d = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, store.lat!, store.lng!);
      // On tolère l'imprécision du GPS en intérieur (jusqu'à 100 m).
      final margin = min(pos.accuracy, 100.0);
      if (d - margin > store.radiusM) {
        return tr('tooFar', {
          'd': d.round().toString(),
          'r': store.radiusM.round().toString(),
        });
      }
      return null;
    } catch (_) {
      return tr('locationNeeded');
    }
  }
}
