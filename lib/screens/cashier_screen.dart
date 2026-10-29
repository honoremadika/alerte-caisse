import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../models/alert_types.dart';
import '../models/app_user.dart';
import '../models/store.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/desktop_overlay.dart';
import '../services/store_service.dart';
import '../widgets/lang_menu.dart';
import 'password_screen.dart';

/// Écran du caissier. Sur ordinateur : une bulle flottante au-dessus du
/// logiciel de caisse, qui s'ouvre en panneau (clic ou Ctrl+Alt+A).
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CaisseAlert>>(
      stream: AlertService().activeFor(user),
      builder: (context, snap) {
        final mine = snap.data ?? const <CaisseAlert>[];
        if (!DesktopOverlay.isDesktop) {
          return _CashierPanel(user: user, mine: mine);
        }
        return ValueListenableBuilder<bool>(
          valueListenable: DesktopOverlay.expanded,
          builder: (context, open, _) => open
              ? _CashierPanel(user: user, mine: mine)
              : _Bubble(mine: mine),
        );
      },
    );
  }
}

/// Bulle rouge (rien en cours), orange (en attente), verte (« Honey arrive »).
class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine});
  final List<CaisseAlert> mine;

  @override
  Widget build(BuildContext context) {
    final taken = mine.where((a) => a.status == 'taken').toList();
    final waiting = mine.any((a) => a.status == 'open');
    final Color color;
    final Widget content;
    if (taken.isNotEmpty) {
      color = Colors.green.shade700;
      final name = taken.first.takenByName ?? '';
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.directions_run, color: Colors.white, size: 26),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ]);
    } else if (waiting) {
      color = Colors.orange.shade800;
      content = const Icon(Icons.hourglass_top, color: Colors.white, size: 30);
    } else {
      color = Colors.red.shade700;
      content = const Icon(Icons.campaign, color: Colors.white, size: 34);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Tooltip(
          message: tr('shortcutHint', {'key': DesktopOverlay.hotKeyLabel}),
          child: GestureDetector(
            onTap: DesktopOverlay.expand,
            onPanStart: (_) => DesktopOverlay.startDrag(),
            child: Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black38)],
              ),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _CashierPanel extends StatefulWidget {
  const _CashierPanel({required this.user, required this.mine});
  final AppUser user;
  final List<CaisseAlert> mine;

  @override
  State<_CashierPanel> createState() => _CashierPanelState();
}

class _CashierPanelState extends State<_CashierPanel> {
  final _service = AlertService();
  final _message = TextEditingController();
  String? _typeKey;
  bool _sending = false;

  Future<void> _send(List<AlertType> types) async {
    final type = types.firstWhere((t) => t.key == _typeKey, orElse: () => types.first);
    setState(() => _sending = true);
    try {
      await _service.send(cashier: widget.user, type: type, message: _message.text);
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('sent')),
        backgroundColor: Colors.green,
      ));
      // Le panneau se réduit seul pour libérer l'écran de caisse.
      Future.delayed(const Duration(milliseconds: 1500), DesktopOverlay.collapse);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('sendFailed'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    final theme = Theme.of(context);
    return StreamBuilder<Store?>(
      stream: StoreService().watch(widget.user.storeId),
      builder: (context, storeSnap) {
        final store = storeSnap.data;
        final types = store?.alertTypes ?? defaultAlertTypes;
        _typeKey ??= types.first.key;

        return Scaffold(
          appBar: AppBar(
            // Glisser la barre du haut pour déplacer la fenêtre.
            flexibleSpace: DesktopOverlay.dragArea(child: const SizedBox.expand()),
            titleSpacing: 12,
            title: Text(
              '${tr('register', {'n': widget.user.register})} · ${widget.user.name}'
              '${store != null ? '\n${store.name}' : ''}',
              style: const TextStyle(fontSize: 15, height: 1.25),
            ),
            actions: [
              LangMenu(),
              IconButton(
                tooltip: tr('changePassword'),
                icon: const Icon(Icons.key),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PasswordScreen())),
              ),
              IconButton(
                tooltip: tr('signOut'),
                icon: const Icon(Icons.logout),
                onPressed: AuthService().signOut,
              ),
              if (DesktopOverlay.isDesktop)
                IconButton(
                  tooltip: '${tr('hide')} (${DesktopOverlay.hotKeyLabel})',
                  icon: const Icon(Icons.close_fullscreen),
                  onPressed: DesktopOverlay.collapse,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StreamBuilder<int>(
                stream: _service.managersOnDuty(widget.user.storeId),
                builder: (context, s) => (s.data ?? 1) > 0
                    ? const SizedBox.shrink()
                    : Card(
                        color: Colors.orange.withOpacity(0.15),
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber, color: Colors.orange),
                          title: Text(tr('noManager')),
                        ),
                      ),
              ),
              Text(tr('whatProblem'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: types.map((t) => ChoiceChip(
                      avatar: Icon(t.icon, size: 18),
                      label: Text(t.label(lang)),
                      selected: _typeKey == t.key,
                      onSelected: (_) => setState(() => _typeKey = t.key),
                    )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                maxLength: 140,
                decoration: InputDecoration(
                  labelText: tr('details'),
                  hintText: tr('detailsHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(
                height: 76,
                child: FilledButton.icon(
                  onPressed: _sending ? null : () => _send(types),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.campaign, size: 30),
                  label: Text(_sending ? tr('sending') : tr('send')),
                ),
              ),
              if (DesktopOverlay.isDesktop) ...[
                const SizedBox(height: 6),
                Text(tr('shortcutHint', {'key': DesktopOverlay.hotKeyLabel}),
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 20),
              Text(tr('myAlerts'), style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              if (widget.mine.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text(tr('noAlerts')))
              else
                ...widget.mine.map((a) => _MyAlertTile(
                    alert: a, lang: lang, onCancel: () => _service.cancel(a.id))),
            ],
          ),
        );
      },
    );
  }
}

class _MyAlertTile extends StatelessWidget {
  const _MyAlertTile({required this.alert, required this.lang, required this.onCancel});
  final CaisseAlert alert;
  final String lang;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final taken = alert.status == 'taken';
    final time = alert.createdAt != null ? DateFormat.Hm().format(alert.createdAt!) : '…';
    return Card(
      color: (taken ? Colors.green : Colors.orange).withOpacity(0.15),
      child: ListTile(
        leading: Icon(taken ? Icons.directions_run : Icons.hourglass_top,
            color: taken ? Colors.green : Colors.orange),
        title: Text('${alert.typeLabel(lang)} · $time'),
        // Le caissier voit le NOM du manager qui arrive.
        subtitle: Text(
          taken ? tr('isComing', {'name': alert.takenByName ?? '—'}) : tr('waiting'),
          style: taken ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
        trailing: taken ? null : TextButton(onPressed: onCancel, child: Text(tr('cancel'))),
      ),
    );
  }
}
