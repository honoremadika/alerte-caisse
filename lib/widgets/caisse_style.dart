import 'package:flutter/material.dart';

import '../services/desktop_overlay.dart';

/// Couleurs de l'app Caisse : les mêmes que l'app web (public/app.html).
class CS {
  final bool dark;
  const CS._(this.dark);
  static CS of(BuildContext context) => CS._(Theme.of(context).brightness == Brightness.dark);

  Color get bg => dark ? const Color(0xFF0F1216) : const Color(0xFFEEF0F3);
  Color get surface => dark ? const Color(0xFF191D23) : Colors.white;
  Color get surface2 => dark ? const Color(0xFF21262E) : const Color(0xFFF4F5F8);
  Color get line => dark ? const Color(0xFF313843) : const Color(0xFFD9DDE4);
  Color get fg => dark ? const Color(0xFFE8EBF0) : const Color(0xFF1A1E25);
  Color get muted => dark ? const Color(0xFF9AA3B1) : const Color(0xFF5C6472);
  Color get accent => dark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
  Color get ok => dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
  Color get okSoft => dark ? const Color(0xFF1C3220) : const Color(0xFFE3F1E4);
  Color get warn => dark ? const Color(0xFFF0A63A) : const Color(0xFFB85F00);
  Color get warnSoft => dark ? const Color(0xFF382A13) : const Color(0xFFFCEFDC);
  Color get alarmSoft => dark ? const Color(0xFF3C1B1B) : const Color(0xFFFBE4E4);
  Color get side => dark ? const Color(0xFF0A1A2A) : const Color(0xFF10263D);
  Color get side2 => dark ? const Color(0xFF10283F) : const Color(0xFF183552);
  Color get sideFg => dark ? const Color(0xFFDFE8F2) : const Color(0xFFE7EEF6);
  Color get sideMuted => dark ? const Color(0xFF8AA0B7) : const Color(0xFF9FB3C8);
}

/// Logo rond rouge avec la cloche.
class BellLogo extends StatelessWidget {
  const BellLogo({super.key, this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle),
        child: Icon(Icons.notifications_active, color: Colors.white, size: size * 0.55),
      );
}

/// Barre du haut bleu nuit, déplaçable à la souris.
class CaisseHeader extends StatelessWidget {
  const CaisseHeader({super.key, required this.title, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = CS.of(context);
    return DesktopOverlay.dragArea(
      child: Container(
        color: c.side,
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(children: [
          const BellLogo(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.sideFg, fontSize: 19, fontWeight: FontWeight.w800, height: 1.15)),
              if (subtitle != null)
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.sideMuted, fontSize: 13)),
            ]),
          ),
          ...actions,
          if (DesktopOverlay.isDesktop)
            IconButton(
              tooltip: '${'—'} ${DesktopOverlay.hotKeyLabel}',
              onPressed: DesktopOverlay.collapse,
              icon: Icon(Icons.remove, color: c.sideFg),
            ),
        ]),
      ),
    );
  }
}

/// Gros bouton rouge « Envoyer l'alerte » avec effet d'enfoncement.
class BigRedButton extends StatefulWidget {
  const BigRedButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  State<BigRedButton> createState() => _BigRedButtonState();
}

class _BigRedButtonState extends State<BigRedButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final c = CS.of(context);
    final enabled = widget.onPressed != null;
    final shadow = Color.lerp(c.accent, Colors.black, 0.4)!;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 64,
          margin: EdgeInsets.only(top: _down ? 3 : 0, bottom: _down ? 0 : 3),
          decoration: BoxDecoration(
            color: enabled ? c.accent : c.accent.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: shadow, offset: Offset(0, _down ? 2 : 5))],
          ),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.campaign, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(widget.label.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ]),
        ),
      ),
    );
  }
}

/// Champ de formulaire au style de l'app web.
InputDecoration caisseInput(BuildContext context, String label, {String? hint}) {
  final c = CS.of(context);
  OutlineInputBorder b(Color col) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: col, width: 1.5));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: c.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: b(c.line),
    enabledBorder: b(c.line),
    focusedBorder: b(c.accent),
  );
}
