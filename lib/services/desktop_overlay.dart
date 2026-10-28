import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';

/// Ordinateur caissier : l'app vit dans une petite bulle rouge toujours
/// au-dessus du logiciel de caisse (même en plein écran fenêtré).
/// Un clic sur la bulle ou le raccourci clavier ouvre le panneau d'alerte.
class DesktopOverlay {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static const bubbleSize = Size(76, 76);
  static const panelSize = Size(460, 640);

  /// Raccourci global : Ctrl + Alt + A (fonctionne même quand le
  /// logiciel de caisse a le focus).
  static final hotKey = HotKey(
    key: PhysicalKeyboardKey.keyA,
    modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );
  static const hotKeyLabel = 'Ctrl + Alt + A';

  /// true = panneau ouvert, false = bulle.
  static final expanded = ValueNotifier<bool>(false);

  static Future<void> init() async {
    if (!isDesktop) return;
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: bubbleSize,
      backgroundColor: Color(0x00000000),
      skipTaskbar: true,
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Alerte Caisse',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setAlignment(Alignment.centerRight);
      await windowManager.show();
    });

    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(hotKey, keyDownHandler: (_) => toggle());

    // Démarre avec Windows : rien à lancer à la main sur les caisses.
    // (Sur Mac, cette option demande une configuration Xcode en plus :
    // on la saute pour les tests.)
    if (Platform.isWindows) {
      try {
        launchAtStartup.setup(
          appName: 'Alerte Caisse',
          appPath: Platform.resolvedExecutable,
        );
        await launchAtStartup.enable();
      } catch (_) {}
    }
  }

  static Future<void> toggle() => expanded.value ? collapse() : expand();

  static Future<void> expand() async {
    if (!isDesktop) return;
    expanded.value = true;
    await windowManager.setSize(panelSize);
    await windowManager.setAlignment(Alignment.bottomRight);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> collapse() async {
    if (!isDesktop) return;
    expanded.value = false;
    await windowManager.setSize(bubbleSize);
    await windowManager.setAlignment(Alignment.centerRight);
    await windowManager.setAlwaysOnTop(true);
  }

  /// Glisser la bulle pour la déplacer sur l'écran.
  static Future<void> startDrag() => windowManager.startDragging();
}
