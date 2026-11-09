import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/desktop_overlay.dart';

/// Couleurs de l'app Caisse : les mêmes que l'app web (alerte-caisse.web.app/caisse).
class CaisseColors {
  static const bg = Color(0xFFEEF0F3);
  static const surface = Colors.white;
  static const surface2 = Color(0xFFF4F5F8);
  static const line = Color(0xFFD9DDE4);
  static const fg = Color(0xFF1A1E25);
  static const muted = Color(0xFF5C6472);
  static const accent = Color(0xFFC62828);
  static const ok = Color(0xFF2E7D32);
  static const okSoft = Color(0xFFE3F1E4);
  static const warn = Color(0xFFB85F00);
  static const warnSoft = Color(0xFFFCEFDC);
  static const alarmSoft = Color(0xFFFBE4E4);
  static const side = Color(0xFF10263D);
  static const side2 = Color(0xFF183552);
  static const sideFg = Color(0xFFE7EEF6);
  static const sideMuted = Color(0xFF9FB3C8);
}

ThemeData caisseTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CaisseColors.side,
      primary: CaisseColors.side,
      error: CaisseColors.accent,
      surface: CaisseColors.surface,
    ),
    scaffoldBackgroundColor: CaisseColors.bg,
    fontFamily: 'Segoe UI',
    visualDensity: VisualDensity.compact,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: CaisseColors.fg, displayColor: CaisseColors.fg),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

InputDecoration caisseInput(String label, {String? hint, IconData? icon}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: CaisseColors.surface,
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CaisseColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CaisseColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CaisseColors.side, width: 2)),
    );

/// Page de l'app Caisse : barre bleu nuit en haut (on la fait glisser pour
/// déplacer la fenêtre), langue FR/EN et bouton « réduire en bulle ».
class CaissePage extends StatelessWidget {
  const CaissePage({super.key, required this.child, this.header, this.menu, this.canMinimise = false});
  final Widget child;
  final Widget? header; // bloc bleu nuit sous la barre (poste, caissier…)
  final Widget? menu;
  final bool canMinimise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CaisseColors.bg,
      body: Column(children: [
        Container(
          color: CaisseColors.side,
          child: Column(children: [
            SizedBox(
              height: 42,
              child: Row(children: [
                Expanded(
                  child: DesktopOverlay.dragArea(
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.only(left: 14),
                      alignment: Alignment.centerLeft,
                      child: const Row(children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Alerte Caisse',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
                const _LangSwitch(),
                if (menu != null) menu!,
                if (canMinimise && DesktopOverlay.isDesktop)
                  IconButton(
                    tooltip: '${tr('hide')} (Échap)',
                    onPressed: DesktopOverlay.collapse,
                    icon: const Icon(Icons.remove, color: CaisseColors.sideFg, size: 20),
                  ),
                const SizedBox(width: 4),
              ]),
            ),
            if (header != null) header!,
          ]),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch();
  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    Widget b(String v) => InkWell(
          onTap: () => AppLang.instance.set(v),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: lang == v ? CaisseColors.sideFg : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(v.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: lang == v ? CaisseColors.side : CaisseColors.sideMuted)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: CaisseColors.side2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [b('fr'), b('en')]),
    );
  }
}
