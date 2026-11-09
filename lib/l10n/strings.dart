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
  'loginId': {'fr': 'Identifiant', 'en': 'User ID'},
  'loginIdHint': {'fr': 'ex. meya', 'en': 'e.g. meya'},
  'showPassword': {'fr': 'Afficher le mot de passe', 'en': 'Show password'},
  'errFillAll': {'fr': 'Remplissez tous les champs.', 'en': 'Fill in all fields.'},
  'errLoginFormat': {'fr': 'Identifiant invalide : lettres, chiffres, point, tiret.', 'en': 'Invalid ID: letters, digits, dot, dash.'},
  'errRelogin': {'fr': 'Reconnectez-vous puis réessayez.', 'en': 'Sign in again, then retry.'},
  'changePassword': {'fr': 'Changer le mot de passe', 'en': 'Change password'},
  'currentPassword': {'fr': 'Mot de passe actuel', 'en': 'Current password'},
  'newPassword': {'fr': 'Nouveau mot de passe', 'en': 'New password'},
  'confirmPassword': {'fr': 'Confirmer le nouveau mot de passe', 'en': 'Confirm new password'},
  'pwRule': {'fr': 'Au moins 6 caractères.', 'en': 'At least 6 characters.'},
  'pwTooShort': {'fr': 'Le mot de passe doit contenir au moins 6 caractères.', 'en': 'The password must have at least 6 characters.'},
  'pwMismatch': {'fr': 'Les deux nouveaux mots de passe ne sont pas identiques.', 'en': 'The two new passwords do not match.'},
  'passwordChanged': {'fr': 'Mot de passe modifié.', 'en': 'Password changed.'},
  'save': {'fr': 'Enregistrer', 'en': 'Save'},
  'lastUsed': {'fr': 'dernier utilisé', 'en': 'last used'},
  'ringtone': {'fr': 'Sonnerie', 'en': 'Ringtone'},
  // Poste de caisse (PC, sans identifiant ni mot de passe)
  'setupTitle': {'fr': 'Installer ce poste de caisse', 'en': 'Set up this till'},
  'setupIntro': {'fr': 'À faire une seule fois. Le code du magasin est donné par le manager.', 'en': 'Done once. The store code is given by the manager.'},
  'storeCode': {'fr': 'Code du magasin', 'en': 'Store code'},
  'storeCodeHint': {'fr': 'Ex. : KM06-7F3K9P', 'en': 'E.g. KM06-7F3K9P'},
  'tillNumber': {'fr': 'Numéro de caisse', 'en': 'Till number'},
  'cashierNameOpt': {'fr': 'Nom du caissier (facultatif)', 'en': 'Cashier name (optional)'},
  'startPost': {'fr': 'Valider', 'en': 'Confirm'},
  'badCode': {'fr': 'Code inconnu. Vérifiez-le auprès du manager.', 'en': 'Unknown code. Check it with the manager.'},
  'needTill': {'fr': 'Indiquez le numéro de caisse (1 à 4 caractères).', 'en': 'Enter the till number (1 to 4 characters).'},
  'connectFailed': {'fr': 'Pas de connexion au serveur. Vérifiez internet.', 'en': 'Cannot reach the server. Check the internet.'},
  'retry': {'fr': 'Réessayer', 'en': 'Retry'},
  'changeCashier': {'fr': 'Changer de caissier', 'en': 'Change cashier'},
  'cashierName': {'fr': 'Nom du caissier', 'en': 'Cashier name'},
  'changePost': {'fr': 'Changer de poste…', 'en': 'Change till…'},
  'changePostConfirm': {'fr': 'Ce PC ne sera plus relié à ce poste. Il faudra retaper un code de magasin.', 'en': 'This PC will be unlinked from this till. A store code will be needed again.'},
  'continue': {'fr': 'Continuer', 'en': 'Continue'},
  'onDutyNow': {'fr': 'En service', 'en': 'On duty'},
  'noneOnDuty': {'fr': 'Aucun manager en service', 'en': 'No manager on duty'},
  'keysHint': {'fr': 'Touches 1 à 9 · Ctrl + Entrée pour envoyer · Échap pour réduire', 'en': 'Keys 1 to 9 · Ctrl + Enter to send · Esc to minimise'},
  'clickOutside': {'fr': 'Un clic en dehors réduit la fenêtre en bulle.', 'en': 'Clicking outside shrinks the window to a bubble.'},
  'tillCodes': {'fr': 'Codes des PC de caisse', 'en': 'Till PC codes'},
  'tillCodesIntro': {'fr': 'À taper une seule fois sur chaque PC de caisse. Ne le donnez qu’au personnel.', 'en': 'Typed once on each till PC. Share it with staff only.'},
  'noCodes': {'fr': 'Aucun code pour le moment.', 'en': 'No codes yet.'},
  'copied': {'fr': 'Copié', 'en': 'Copied'},
  'updateAvailable': {'fr': 'Une nouvelle version de l’app est disponible.', 'en': 'A new version of the app is available.'},
  'update': {'fr': 'Mettre à jour', 'en': 'Update'},
  'later': {'fr': 'Plus tard', 'en': 'Later'},
  'testTone': {'fr': 'Écouter', 'en': 'Play'},
  'toneTestTitle': {'fr': '🔔 Essai de sonnerie', 'en': '🔔 Ringtone test'},
  'toneTestBody': {'fr': 'Voici le son des alertes des caisses.', 'en': 'This is how till alerts will sound.'},
  'close': {'fr': 'Fermer', 'en': 'Close'},
  'signOut': {'fr': 'Se déconnecter', 'en': 'Sign out'},
  'noProfile': {
    'fr': "Ce compte n'a pas encore de profil (caissier ou manager).\nDemandez à l'administrateur de le configurer.",
    'en': 'This account has no profile yet (cashier or manager).\nAsk the administrator to set it up.',
  },
  // Erreurs de connexion
  'errCredentials': {'fr': 'Identifiant ou mot de passe incorrect.', 'en': 'Wrong user ID or password.'},
  'errEmail': {'fr': 'Adresse email invalide.', 'en': 'Invalid email address.'},
  'errNetwork': {'fr': 'Pas de connexion internet.', 'en': 'No internet connection.'},
  'errTooMany': {'fr': 'Trop de tentatives. Réessayez dans quelques minutes.', 'en': 'Too many attempts. Try again in a few minutes.'},
  'errGeneric': {'fr': 'Connexion impossible. Réessayez.', 'en': 'Could not sign in. Try again.'},

  // Caissier
  'register': {'fr': 'Caisse {n}', 'en': 'Till {n}'},
  // Poste de caisse (app Windows, sans mot de passe)
  'setupLead': {'fr': 'À faire une seule fois : choisissez le magasin et le numéro de caisse. Un manager validera ce poste depuis son téléphone.', 'en': 'Only once: choose the store and till number. A manager will approve this till from their phone.'},
  'store': {'fr': 'Magasin', 'en': 'Store'},
  'chooseStore': {'fr': 'Choisissez le magasin', 'en': 'Choose the store'},
  'registerNo': {'fr': 'Numéro de caisse', 'en': 'Till number'},
  'registerNoBad': {'fr': 'Entrez le numéro de caisse (1 à 4 chiffres).', 'en': 'Enter the till number (1 to 4 digits).'},
  'requestPost': {'fr': 'Demander la validation', 'en': 'Request approval'},
  'waitTitle': {'fr': 'En attente de validation', 'en': 'Waiting for approval'},
  'waitLead': {'fr': 'Demandez à un manager du magasin d’ouvrir Alerte Manager sur son téléphone et de valider ce poste. Vérifiez que le code est le même :', 'en': 'Ask a store manager to open Alerte Manager on their phone and approve this till. Check that the code matches:'},
  'refusedTitle': {'fr': 'Poste refusé', 'en': 'Till refused'},
  'refusedLead': {'fr': 'Un manager a refusé ce poste. Vérifiez le magasin et le numéro de caisse, puis refaites la demande.', 'en': 'A manager refused this till. Check the store and till number, then ask again.'},
  'newRequest': {'fr': 'Refaire la demande', 'en': 'Ask again'},
  'offline': {'fr': 'Pas de connexion Internet. Nouvel essai…', 'en': 'No Internet connection. Retrying…'},
  'managersOnDuty': {'fr': 'Managers en service', 'en': 'Managers on duty'},
  'settings': {'fr': 'Réglages', 'en': 'Settings'},
  // Côté manager : validation des postes
  'newPosts': {'fr': 'Nouveau poste de caisse à valider', 'en': 'New till to approve'},
  'postLine': {'fr': 'Caisse {n} · code {code}', 'en': 'Till {n} · code {code}'},
  'approve': {'fr': 'Valider', 'en': 'Approve'},
  'refuse': {'fr': 'Refuser', 'en': 'Refuse'},
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
