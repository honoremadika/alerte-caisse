import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'application : 'fr' ou 'en'. Mémorisée sur l'appareil.
class AppLang extends ValueNotifier<String> {
  AppLang._() : super('fr');
  static final instance = AppLang._();
  static const supported = ['fr', 'en'];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('lang');
    if (saved != null && supported.contains(saved)) {
      value = saved;
    } else {
      final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      value = sys == 'en' ? 'en' : 'fr';
    }
  }

  Future<void> set(String lang) async {
    if (!supported.contains(lang)) return;
    value = lang;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', lang);
  }
}

/// Raccourci : tr('send') -> texte dans la langue courante.
String tr(String key, [Map<String, String> params = const {}]) {
  final lang = AppLang.instance.value;
  var s = _t[key]?[lang] ?? _t[key]?['fr'] ?? key;
  params.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

const Map<String, Map<String, String>> _t = {
  'appName': {'fr': 'Alerte Caisse', 'en': 'Till Alert'},
  'appCaisseTitle': {'fr': 'Alerte Caisse · Poste', 'en': 'Till Alert · Station'},
  'appManagerTitle': {'fr': 'Alerte Caisse · Manager', 'en': 'Till Alert · Manager'},
  'wrongAppCaisse': {
    'fr': "Ce compte est un compte manager. Utilisez l'app Manager sur votre téléphone.",
    'en': 'This is a manager account. Use the Manager app on your phone.',
  },
  'wrongAppManager': {
    'fr': "Ce compte est un compte caissier. Utilisez l'app Caisse sur l'ordinateur de la caisse.",
    'en': "This is a cashier account. Use the Till app on the till computer.",
  },
  'language': {'fr': 'Langue', 'en': 'Language'},
  'email': {'fr': 'Email', 'en': 'Email'},
  'password': {'fr': 'Mot de passe', 'en': 'Password'},
  'signIn': {'fr': 'Se connecter', 'en': 'Sign in'},
  'signOut': {'fr': 'Se déconnecter', 'en': 'Sign out'},
  'noProfile': {
    'fr': "Ce compte n'a pas encore de profil (caissier ou manager).\nDemandez à l'administrateur de le configurer.",
    'en': 'This account has no profile yet (cashier or manager).\nAsk the administrator to set it up.',
  },
  // Erreurs de connexion
  'errCredentials': {'fr': 'Email ou mot de passe incorrect.', 'en': 'Wrong email or password.'},
  'errEmail': {'fr': 'Adresse email invalide.', 'en': 'Invalid email address.'},
  'errNetwork': {'fr': 'Pas de connexion internet.', 'en': 'No internet connection.'},
  'errTooMany': {'fr': 'Trop de tentatives. Réessayez dans quelques minutes.', 'en': 'Too many attempts. Try again in a few minutes.'},
  'errGeneric': {'fr': 'Connexion impossible. Réessayez.', 'en': 'Could not sign in. Try again.'},

  // Caissier
  'register': {'fr': 'Caisse {n}', 'en': 'Till {n}'},
  'whatProblem': {'fr': 'Quel est le problème ?', 'en': "What's the problem?"},
  'details': {'fr': 'Précision (facultatif)', 'en': 'Details (optional)'},
  'detailsHint': {'fr': 'Ex. : article 3, client pressé…', 'en': 'E.g. item 3, customer waiting…'},
  'send': {'fr': "ENVOYER L'ALERTE", 'en': 'SEND ALERT'},
  'sending': {'fr': 'Envoi…', 'en': 'Sending…'},
  'sent': {'fr': 'Alerte envoyée aux managers', 'en': 'Alert sent to managers'},
  'sendFailed': {'fr': "Échec de l'envoi. Vérifiez la connexion internet.", 'en': 'Sending failed. Check the internet connection.'},
  'myAlerts': {'fr': 'Mes alertes en cours', 'en': 'My open alerts'},
  'noAlerts': {'fr': 'Aucune alerte en cours.', 'en': 'No open alerts.'},
  'waiting': {'fr': 'En attente d\'un manager…', 'en': 'Waiting for a manager…'},
  'isComing': {'fr': '{name} arrive', 'en': '{name} is on the way'},
  'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
  'hide': {'fr': 'Réduire', 'en': 'Minimise'},
  'shortcutHint': {'fr': 'Raccourci : {key}', 'en': 'Shortcut: {key}'},
  'noManager': {
    'fr': 'Aucun manager en service dans ce magasin pour le moment.',
    'en': 'No manager on duty in this store right now.',
  },

  // Manager
  'openAlerts': {'fr': 'Alertes en cours', 'en': 'Open alerts'},
  'history': {'fr': 'Historique', 'en': 'History'},
  'allGood': {'fr': 'Tout va bien. Aucune alerte.', 'en': 'All good. No alerts.'},
  'connError': {'fr': 'Erreur de connexion.', 'en': 'Connection error.'},
  'imComing': {'fr': "J'arrive", 'en': "I'm coming"},
  'resolved': {'fr': 'Problème résolu', 'en': 'Problem solved'},
  'cashier': {'fr': 'Caissier : {name}', 'en': 'Cashier: {name}'},
  'takenByYou': {'fr': 'Vous avez pris en charge', 'en': 'You are handling this'},
  'takenBy': {'fr': '{name} arrive — sonnerie arrêtée', 'en': '{name} is on the way — ringing stopped'},
  'alreadyTaken': {'fr': '{name} a déjà pris cette alerte.', 'en': '{name} already took this alert.'},
  'justNow': {'fr': "à l'instant", 'en': 'just now'},
  'minAgo': {'fr': 'il y a {m} min', 'en': '{m} min ago'},

  // Prise de service
  'onDuty': {'fr': 'En service', 'en': 'On duty'},
  'offDuty': {'fr': 'Hors service', 'en': 'Off duty'},
  'onDutyAt': {'fr': 'En service · {store}', 'en': 'On duty · {store}'},
  'offDutyInfo': {
    'fr': 'Vous ne recevez pas les alertes. Prenez votre service quand vous êtes au magasin.',
    'en': "You won't receive alerts. Go on duty when you are at the store.",
  },
  'startDuty': {'fr': 'Prendre mon service', 'en': 'Go on duty'},
  'endDuty': {'fr': 'Terminer mon service', 'en': 'End my shift'},
  'chooseStore': {'fr': 'Dans quel magasin êtes-vous ?', 'en': 'Which store are you in?'},
  'tooFar': {
    'fr': 'Vous êtes à {d} m du magasin. Rapprochez-vous (moins de {r} m) pour prendre votre service.',
    'en': 'You are {d} m from the store. Get closer (under {r} m) to go on duty.',
  },
  'locationNeeded': {
    'fr': 'Autorisez la localisation pour vérifier que vous êtes au magasin.',
    'en': 'Allow location access so we can check you are at the store.',
  },
  'dutyExpires': {'fr': 'Fin automatique à {time}', 'en': 'Ends automatically at {time}'},

  // Historique
  'alertsCount': {'fr': 'Alertes', 'en': 'Alerts'},
  'avgReaction': {'fr': 'Réaction moyenne', 'en': 'Average response'},
  'reaction': {'fr': 'Réaction : {d} ({name})', 'en': 'Response: {d} ({name})'},
  'solvedIn': {'fr': 'Résolu en {d}', 'en': 'Solved in {d}'},
  'st_open': {'fr': 'En attente', 'en': 'Waiting'},
  'st_taken': {'fr': 'En cours', 'en': 'In progress'},
  'st_resolved': {'fr': 'Résolue', 'en': 'Solved'},
  'st_cancelled': {'fr': 'Annulée', 'en': 'Cancelled'},
};
