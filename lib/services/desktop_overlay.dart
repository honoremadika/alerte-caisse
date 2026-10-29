import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Positions et taille choisies par le caissier (gardées après redémarrage).
  static Offset? _panelPos;
  static Size? _panelSize;
  static Offset? _bubblePos;

  static Future<void> _loadPlaces() async {
    final p = await SharedPreferences.getInstance();
    Offset? off(String k) {
      final x = p.getDouble('${k}X'), y = p.getDouble('${k}Y');
      return (x != null && y != null) ? Offset(x, y) : null;
    }
    _panelPos ??= off('panel');
    _bubblePos ??= off('bubble');
    final w = p.getDouble('panelW'), h = p.getDouble('panelH');
    if (_panelSize == null && w != null && h != null) _panelSize = Size(w, h);
  }

  static Future<void> _savePlaces() async {
    final p = await SharedPreferences.getInstance();
    if (_panelPos != null) {
      await p.setDouble('panelX', _panelPos!.dx);
      await p.setDouble('panelY', _panelPos!.dy);
    }
    if (_panelSize != null) {
      await p.setDouble('panelW', _panelSize!.width);
      await p.setDouble('panelH', _panelSize!.height);
    }
    if (_bubblePos != null) {
      await p.setDouble('bubbleX', _bubblePos!.dx);
      await p.setDouble('bubbleY', _bubblePos!.dy);
    }
  }

  static Future<void> expand() async {
    if (!isDesktop) return;
    await _loadPlaces();
    if (!expanded.value) _bubblePos = await windowManager.getPosition();
    expanded.value = true;
    // Panneau : déplaçable (barre du haut) et redimensionnable (bords).
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const Size(380, 480));
    await windowManager.setSize(_panelSize ?? panelSize);
    if (_panelPos != null) {
      await windowManager.setPosition(_panelPos!);
    } else {
      await windowManager.setAlignment(Alignment.bottomRight);
    }
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> collapse() async {
    if (!isDesktop) return;
    if (expanded.value) {
      _panelPos = await windowManager.getPosition();
      _panelSize = await windowManager.getSize();
    }
    expanded.value = false;
    await windowManager.setMinimumSize(bubbleSize);
    await windowManager.setResizable(false);
    await windowManager.setSize(bubbleSize);
    if (_bubblePos != null) {
      await windowManager.setPosition(_bubblePos!);
    } else {
      await windowManager.setAlignment(Alignment.centerRight);
    }
    await windowManager.setAlwaysOnTop(true);
    await _savePlaces();
  }

  /// Glisser la bulle pour la déplacer sur l'écran.
  static Future<void> startDrag() async {
    await windowManager.startDragging();
  }

  /// Zone qui permet de déplacer la fenêtre en la faisant glisser
  /// (la fenêtre n'a pas de barre de titre Windows).
  static Widget dragArea({required Widget child}) =>
      isDesktop ? DragToMoveArea(child: child) : child;
}
