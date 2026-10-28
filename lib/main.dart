// Point d'entrée par défaut : choisit l'app selon l'appareil.
// Pour forcer une app : lib/main_caisse.dart ou lib/main_manager.dart.
import 'app.dart';
import 'services/desktop_overlay.dart';

Future<void> main() =>
    runAlerteApp(DesktopOverlay.isDesktop ? AppMode.caisse : AppMode.manager);
