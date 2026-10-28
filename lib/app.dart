import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart'; // généré par `flutterfire configure`
import 'l10n/strings.dart';
import 'models/app_user.dart';
import 'screens/cashier_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manager_screen.dart';
import 'services/auth_service.dart';
import 'services/desktop_overlay.dart';
import 'services/notification_service.dart';

/// Deux applications distinctes partagent ce code :
///  - AppMode.caisse  : ordinateur du caissier (lib/main_caisse.dart)
///  - AppMode.manager : téléphone du manager  (lib/main_manager.dart)
enum AppMode { caisse, manager }

Future<void> runAlerteApp(AppMode mode) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR');
  await initializeDateFormatting('en_GB');
  await AppLang.instance.load();

  if (mode == AppMode.caisse && DesktopOverlay.isDesktop) {
    await DesktopOverlay.init();
    await DesktopOverlay.expand();
  }
  if (mode == AppMode.manager && NotificationService.isSupported) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.init();
  }
  runApp(AlerteCaisseApp(mode: mode));
}

class AlerteCaisseApp extends StatelessWidget {
  const AlerteCaisseApp({super.key, required this.mode});
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    // Couleur différente pour reconnaître les deux apps d'un coup d'œil.
    final seed = mode == AppMode.caisse ? const Color(0xFF10263D) : const Color(0xFFC62828);
    return ValueListenableBuilder<String>(
      valueListenable: AppLang.instance,
      builder: (context, lang, _) => MaterialApp(
        title: mode == AppMode.caisse ? '${tr('appName')} · Caisse' : '${tr('appName')} · Manager',
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
        home: AuthGate(mode: mode),
      ),
    );
  }
}

/// Connexion puis vérification du rôle : un compte manager ne peut pas
/// ouvrir l'app Caisse, et inversement.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.mode});
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _Loading();
        final user = snap.data;
        if (user == null) return LoginScreen(mode: mode);

        return StreamBuilder<AppUser?>(
          stream: auth.profile(user.uid),
          builder: (context, p) {
            if (p.connectionState == ConnectionState.waiting) return const _Loading();
            final profile = p.data;
            if (profile == null) return _Blocked(text: tr('noProfile'), onLogout: auth.signOut);
            if (mode == AppMode.caisse && !profile.isCashier) {
              return _Blocked(text: tr('wrongAppCaisse'), onLogout: auth.signOut);
            }
            if (mode == AppMode.manager && !profile.isManager) {
              return _Blocked(text: tr('wrongAppManager'), onLogout: auth.signOut);
            }
            return mode == AppMode.caisse
                ? CashierScreen(user: profile)
                : ManagerScreen(user: profile);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Blocked extends StatelessWidget {
  const _Blocked({required this.text, required this.onLogout});
  final String text;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.block, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onLogout, child: Text(tr('signOut'))),
          ]),
        ),
      ),
    );
  }
}
