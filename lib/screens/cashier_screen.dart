import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../models/alert_types.dart';
import '../models/app_user.dart';
import '../models/store.dart';
import '../services/alert_service.dart';
import '../services/desktop_overlay.dart';
import '../services/store_service.dart';
import '../widgets/caisse_theme.dart';

/// Poste de caisse. Sur ordinateur : une bulle toujours visible au-dessus du
/// logiciel de caisse ; un clic sur la bulle (ou Ctrl+Alt+A) ouvre le panneau,
/// un clic en dehors du panneau le réduit à nouveau en bulle.
class CashierScreen extends StatelessWidget {
  const CashierScreen({
    super.key,
    required this.user,
    this.stationId,
    this.onRename,
    this.onChangePost,
  });
  final AppUser user;
  final String? stationId;
  final Future<void> Function(String name)? onRename;
  final VoidCallback? onChangePost;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CaisseAlert>>(
      stream: AlertService().activeFor(user),
      builder: (context, snap) {
        final mine = snap.data ?? const <CaisseAlert>[];
        final panel = _CashierPanel(
          user: user,
          mine: mine,
          stationId: stationId,
          onRename: onRename,
          onChangePost: onChangePost,
        );
        if (!DesktopOverlay.isDesktop) return panel;
        return ValueListenableBuilder<bool>(
          valueListenable: DesktopOverlay.expanded,
          builder: (context, open, _) => open ? panel : _Bubble(mine: mine),
        );
      },
    );
  }
}

/// Bulle : rouge (rien en cours), orange (en attente), verte (« Honey arrive »).
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
      color = CaisseColors.ok;
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.directions_run, color: Colors.white, size: 24),
        Text(taken.first.takenByName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      ]);
    } else if (waiting) {
      color = CaisseColors.warn;
      content = const Icon(Icons.hourglass_top, color: Colors.white, size: 28);
    } else {
      color = CaisseColors.accent;
      content = const Icon(Icons.notifications_active, color: Colors.white, size: 30);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Tooltip(
          message: 'Alerte Caisse · ${DesktopOverlay.hotKeyLabel}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: DesktopOverlay.expand,
              onPanStart: (_) => DesktopOverlay.startDrag(),
              child: Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38, offset: Offset(0, 2))],
                ),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CashierPanel extends StatefulWidget {
  const _CashierPanel({
    required this.user,
    required this.mine,
    this.stationId,
    this.onRename,
    this.onChangePost,
  });
  final AppUser user;
  final List<CaisseAlert> mine;
  final String? stationId;
  final Future<void> Function(String name)? onRename;
  final VoidCallback? onChangePost;

  @override
  State<_CashierPanel> createState() => _CashierPanelState();
}

class _CashierPanelState extends State<_CashierPanel> {
  final _service = AlertService();
  final _message = TextEditingController();
  final _messageFocus = FocusNode();
  late final Stream<Store?> _store = StoreService().watch(widget.user.storeId);
  late final Stream<List<String>> _onDuty = _service.managersOnDutyNames(widget.user.storeId);
  List<AlertType> _types = defaultAlertTypes;
  String? _typeKey;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    DesktopOverlay.collapseOnBlur = true;
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    DesktopOverlay.collapseOnBlur = false;
    HardwareKeyboard.instance.removeHandler(_onKey);
    _message.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  /// 1 à 9 : choisir le problème · Ctrl+Entrée : envoyer · Échap : réduire.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !DesktopOverlay.expanded.value || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false; // une fenêtre de dialogue est ouverte
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      DesktopOverlay.collapse();
      return true;
    }
    if (ctrl && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      if (!_sending) _send();
      return true;
    }
    if (_messageFocus.hasFocus || ctrl) return false;
    final c = e.character;
    final n = c == null ? null : int.tryParse(c);
    if (n != null && n >= 1 && n <= _types.length && n <= 9) {
      setState(() => _typeKey = _types[n - 1].key);
      return true;
    }
    return false;
  }

  Future<void> _send() async {
    final type = _types.firstWhere((t) => t.key == _typeKey, orElse: () => _types.first);
    setState(() => _sending = true);
    try {
      await _service.send(
          cashier: widget.user, type: type, message: _message.text, stationId: widget.stationId);
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('sent')),
        backgroundColor: CaisseColors.ok,
        duration: const Duration(seconds: 2),
      ));
      // Le panneau se réduit seul pour libérer l'écran de caisse.
      Future.delayed(const Duration(milliseconds: 1400), DesktopOverlay.collapse);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('sendFailed')),
        backgroundColor: CaisseColors.accent,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _rename() async {
    final c = TextEditingController(text: widget.user.name.startsWith('Caisse ') ? '' : widget.user.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('changeCashier')),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 30,
          decoration: caisseInput(tr('cashierName'), icon: Icons.person_outline),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('save'))),
        ],
      ),
    );
    if (v != null) await widget.onRename?.call(v);
  }

  Future<void> _changePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('changePost')),
        content: Text(tr('changePostConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('continue'))),
        ],
      ),
    );
    if (ok == true) widget.onChangePost?.call();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    return StreamBuilder<Store?>(
      stream: _store,
      builder: (context, storeSnap) {
        final store = storeSnap.data;
        _types = store?.alertTypes ?? defaultAlertTypes;
        _typeKey ??= _types.first.key;

        return CaissePage(
          canMinimise: true,
          menu: PopupMenuButton<String>(
            tooltip: tr('settings'),
            icon: const Icon(Icons.more_vert, color: CaisseColors.sideFg, size: 20),
            onSelected: (v) => v == 'name' ? _rename() : _changePost(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'name', child: Text(tr('changeCashier'))),
              PopupMenuItem(value: 'post', child: Text(tr('changePost'))),
            ],
          ),
          header: _Header(user: widget.user, store: store, onDuty: _onDuty, onTapName: _rename),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            children: [
              Text(tr('whatProblem'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 560 ? 3 : 2;
                final w = (c.maxWidth - 8 * (cols - 1)) / cols;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _types.length; i++)
                      SizedBox(
                        width: w,
                        child: _TypeTile(
                          n: i < 9 ? i + 1 : null,
                          type: _types[i],
                          lang: lang,
                          selected: _typeKey == _types[i].key,
                          onTap: () => setState(() => _typeKey = _types[i].key),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                focusNode: _messageFocus,
                maxLength: 140,
                decoration: caisseInput(tr('details'), hint: tr('detailsHint'), icon: Icons.edit_note),
                onSubmitted: (_) => _sending ? null : _send(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: CaisseColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: .5),
                  ),
                  icon: const Icon(Icons.campaign, size: 26),
                  label: Text(_sending ? tr('sending') : tr('send')),
                ),
              ),
              const SizedBox(height: 6),
              Text('${tr('keysHint')} · ${DesktopOverlay.hotKeyLabel}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: CaisseColors.muted)),
              if (widget.mine.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(tr('myAlerts'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ...widget.mine.map((a) => _MyAlertCard(
                    alert: a, lang: lang, onCancel: () => _service.cancel(a.id))),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.store, required this.onDuty, required this.onTapName});
  final AppUser user;
  final Store? store;
  final Stream<List<String>> onDuty;
  final VoidCallback onTapName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: CaisseColors.side2, borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('register', {'n': user.register}),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 2),
              Text(store?.name ?? '…', style: const TextStyle(color: CaisseColors.sideFg, fontSize: 13)),
              InkWell(
                onTap: onTapName,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person, size: 14, color: CaisseColors.sideMuted),
                    const SizedBox(width: 4),
                    Text(user.name, style: const TextStyle(color: CaisseColors.sideMuted, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: CaisseColors.sideMuted),
                  ]),
                ),
              ),
            ]),
          ),
          StreamBuilder<List<String>>(
            stream: onDuty,
            builder: (context, s) {
              final names = s.data;
              final none = names != null && names.isEmpty;
              return Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: none ? CaisseColors.warnSoft : CaisseColors.okSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(none ? tr('noneOnDuty') : tr('onDutyNow'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: none ? CaisseColors.warn : CaisseColors.ok)),
                  if (names != null && names.isNotEmpty)
                    Text(names.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: CaisseColors.fg, fontWeight: FontWeight.w600)),
                ]),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.n, required this.type, required this.lang, required this.selected, required this.onTap});
  final int? n;
  final AlertType type;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CaisseColors.alarmSoft : CaisseColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? CaisseColors.accent : CaisseColors.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? CaisseColors.accent : CaisseColors.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(n?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : CaisseColors.muted)),
            ),
            const SizedBox(width: 8),
            Icon(type.icon, size: 18, color: selected ? CaisseColors.accent : CaisseColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(type.label(lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MyAlertCard extends StatelessWidget {
  const _MyAlertCard({required this.alert, required this.lang, required this.onCancel});
  final CaisseAlert alert;
  final String lang;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final taken = alert.status == 'taken';
    final time = alert.createdAt != null ? DateFormat.Hm().format(alert.createdAt!) : '…';
    final color = taken ? CaisseColors.ok : CaisseColors.warn;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: taken ? CaisseColors.okSoft : CaisseColors.warnSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(children: [
        Icon(taken ? Icons.directions_run : Icons.hourglass_top, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${alert.typeLabel(lang)} · $time', style: const TextStyle(fontWeight: FontWeight.w700)),
            // Le caissier voit le NOM du manager qui arrive.
            Text(taken ? tr('isComing', {'name': alert.takenByName ?? '—'}) : tr('waiting'),
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ]),
        ),
        if (!taken) TextButton(onPressed: onCancel, child: Text(tr('cancel'))),
      ]),
    );
  }
}
