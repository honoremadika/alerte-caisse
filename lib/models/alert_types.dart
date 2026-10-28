import 'package:flutter/material.dart';

/// Un type de problème proposé au caissier.
class AlertType {
  final String key;
  final String fr;
  final String en;
  final IconData icon;
  const AlertType(this.key, this.fr, this.en, this.icon);

  String label(String lang) => lang == 'en' ? en : fr;
}

/// Liste par défaut. Un magasin peut la remplacer depuis Firestore
/// (champ `alertTypes` du document `stores/{id}`), voir README.
const defaultAlertTypes = <AlertType>[
  AlertType('suppression_article', "Suppression d'article", 'Delete item', Icons.remove_shopping_cart),
  AlertType('annulation_facture', 'Annulation de facture', 'Cancel invoice', Icons.receipt_long),
  AlertType('modification_quantite', 'Modification de quantité', 'Change quantity', Icons.exposure),
  AlertType('recherche_f1', 'Recherche F1', 'F1 search', Icons.search),
  AlertType('authentification', 'Authentification manager', 'Manager authentication', Icons.badge),
  AlertType('reclamation_client', 'Réclamation client', 'Customer complaint', Icons.record_voice_over),
  AlertType('remboursement', 'Remboursement', 'Refund', Icons.undo),
  AlertType('monnaie', 'Besoin de monnaie', 'Need change', Icons.payments),
  AlertType('panne', 'Panne matérielle', 'Hardware failure', Icons.build),
  AlertType('autre', 'Autre', 'Other', Icons.help_outline),
];

/// Icônes possibles quand la liste vient de Firestore (champ `icon`).
const _iconsByName = <String, IconData>{
  'remove_shopping_cart': Icons.remove_shopping_cart,
  'receipt_long': Icons.receipt_long,
  'exposure': Icons.exposure,
  'badge': Icons.badge,
  'record_voice_over': Icons.record_voice_over,
  'undo': Icons.undo,
  'payments': Icons.payments,
  'build': Icons.build,
  'shield': Icons.shield,
  'local_offer': Icons.local_offer,
  'help_outline': Icons.help_outline,
};

/// Lit `[{key, fr, en, icon}]` depuis Firestore ; liste par défaut sinon.
List<AlertType> alertTypesFrom(dynamic raw) {
  if (raw is! List || raw.isEmpty) return defaultAlertTypes;
  final list = <AlertType>[];
  for (final e in raw) {
    if (e is Map && e['key'] is String) {
      list.add(AlertType(
        e['key'],
        (e['fr'] ?? e['key']).toString(),
        (e['en'] ?? e['fr'] ?? e['key']).toString(),
        _iconsByName[e['icon']] ?? Icons.warning_amber,
      ));
    }
  }
  return list.isEmpty ? defaultAlertTypes : list;
}

/// Libellé d'un type d'après sa clé (pour l'historique).
String alertTypeLabel(String key, String lang, [List<AlertType>? types]) {
  for (final t in types ?? defaultAlertTypes) {
    if (t.key == key) return t.label(lang);
  }
  for (final t in defaultAlertTypes) {
    if (t.key == key) return t.label(lang);
  }
  return lang == 'en' ? 'Alert' : 'Alerte';
}
