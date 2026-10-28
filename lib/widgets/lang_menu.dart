import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Bouton « FR / EN » pour changer la langue de l'application.
class LangMenu extends StatelessWidget {
  const LangMenu({super.key, this.onChanged});

  /// Appelé après le changement (ex. : enregistrer la langue sur le profil).
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    return PopupMenuButton<String>(
      tooltip: tr('language'),
      initialValue: lang,
      onSelected: (v) async {
        await AppLang.instance.set(v);
        onChanged?.call(v);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'fr', child: Text('Français')),
        PopupMenuItem(value: 'en', child: Text('English')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 4),
          Text(lang.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
