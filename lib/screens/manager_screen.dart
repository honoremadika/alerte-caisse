import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../models/app_user.dart';
import '../models/store.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/duty_background.dart';
import '../services/duty_service.dart';
import '../services/notification_service.dart';
import '../services/store_service.dart';
import '../services/station_service.dart';
import '../services/update_service.dart';
import 'history_screen.dart';
import 'password_screen.dart';

/// Écran du manager (Android / iPhone).
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final _alerts = AlertService();
  final _duty = DutyService();
  List<Store> _stores = [];
  bool _busy = false;
  String? _lastStore; // dernier magasin utilisé sur ce téléphone
  Timer? _ticker;

  AppUser get me => widget.user;

  /// Magasin affiché : celui du service en cours, sinon le dernier utilisé
  /// sur ce téléphone, sinon le premier.
  String get _storeId =>
      (me.isOnDutyNow ? me.dutyStoreId : null) ??
      (_lastStore != null && me.storeIds.contains(_lastStore) ? _lastStore : null) ??
      (me.storeIds.isNotEmpty ? me.storeIds.first : '');

  @override
  void initState() {
    super.initState();
    NotificationService.instance.registerManager(me.uid);
    AuthService().saveLang(me.uid, AppLang.instance.value).catchError((_) {});
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _lastStore = p.getString('lastStore'));
    });
    UpdateService.available().then((yes) {
      if (!yes || !mounted) return;
      final m = ScaffoldMessenger.of(context);
      m.showMaterialBanner(MaterialBanner(
        leading: const Icon(Icons.system_update),
        content: Text(tr('updateAvailable')),
        actions: [
          TextButton(onPressed: m.hideCurrentMaterialBanner, child: Text(tr('later'))),
          FilledButton(
            onPressed: () {
              m.hideCurrentMaterialBanner();
              UpdateService.download();
            },
            child: Text(tr('update')),
          ),
        ],
      ));
    });
    StoreService().list(me.storeIds).then((s) {
      if (mounted) setState(() => _stores = s);
      // Déjà en service (téléphone redémarré, app relancée) : on relance l'écoute.
      if (me.isOnDutyNow && me.dutyStoreId != null) {
        DutyBackground.start(
          storeId: me.dutyStoreId!,
          storeName: _storeName(me.dutyStoreId!),
          lang: AppLang.instance.value,
          until: me.dutyUntil!,
        ).catchError((_) {});
      }
    }).catchError((_) {});
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _storeName(String id) =>
      _stores.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? id;

  void _fail() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('actionFailed'))));
  }

  Future<void> _logout() async {
    // Même sans réseau, la déconnexion doit aboutir et l'écoute s'arrêter.
    try {
      if (me.onDuty) await _duty.end(me.uid).timeout(const Duration(seconds: 6));
    } catch (_) {}
    try {
      await DutyBackground.stop();
    } catch (_) {}
    try {
      await NotificationService.instance.unregisterManager(me.uid).timeout(const Duration(seconds: 6));
    } catch (_) {}
    await AuthService().signOut();
  }

  Future<void> _endDuty() async {
    try {
      await _duty.end(me.uid);
    } catch (_) {
      _fail();
    }
  }

  Future<void> _startDuty() async {
    if (_stores.isEmpty) return;
    // Le dernier magasin utilisé sur CE téléphone est proposé en premier.
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('lastStore');
    final ordered = [
      ..._stores.where((s) => s.id == last),
      ..._stores.where((s) => s.id != last),
    ];
    if (!mounted) return;
    Store? store = ordered.length == 1 ? ordered.first : null;
    store ??= await showDialog<Store>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('chooseStore')),
        children: ordered
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      s.id == last ? '${s.name}  ·  ${tr('lastUsed')}' : s.name,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: s.id == last ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
    if (store == null) return;
    final chosen = store;
    await prefs.setString('lastStore', chosen.id);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _lastStore = chosen.id;
    });
    try {
      final err = await _duty.start(me, chosen);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (_) {
      _fail();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Codes à taper une seule fois sur les PC de caisse de ses magasins.
  Future<void> _showTillCodes() async {
    final Map<String, String> codes;
    final List<Store> stores;
    try {
      codes = await StationService.instance.codesFor(widget.user.storeIds);
      stores = _stores.isNotEmpty ? _stores : await StoreService().list(widget.user.storeIds);
    } catch (_) {
      _fail();
      return;
    }
    if (!mounted) return;
    final rows = stores.where((s) => codes.containsKey(s.id)).toList();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('tillCodes')),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('tillCodesIntro')),
            const SizedBox(height: 8),
            if (rows.isEmpty) Text(tr('noCodes')),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final st in rows)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(st.name),
                    subtitle: SelectableText(codes[st.id]!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: codes[st.id]!));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copied'))));
                      },
                    ),
                  ),
              ]),
            ),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close')))],
      ),
    );
  }

  Future<void> _chooseTone() async {
    var current = await DutyBackground.tone();
    if (!mounted) return;
    final en = AppLang.instance.value == 'en';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr('ringtone')),
          contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: NotificationService.tones
                .map((t) => RadioListTile<String>(
                      value: t,
                      groupValue: current,
                      title: Text(NotificationService.toneLabels[t]![en ? 1 : 0]),
                      secondary: IconButton(
                        tooltip: tr('testTone'),
                        icon: const Icon(Icons.play_circle_outline),
                        onPressed: () => NotificationService.preview(
                            t, tr('toneTestTitle'), tr('toneTestBody')),
                      ),
                      onChanged: (v) async {
                        if (v == null) return;
                        await DutyBackground.setTone(v);
                        setD(() => current = v);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close'))),
          ],
        ),
      ),
    );
  }

  Future<void> _take(CaisseAlert a) async {
    // La sonnerie s'arrête tout de suite sur ce téléphone, même si le réseau est lent.
    await NotificationService.dismiss(a.id);
    try {
      final other = await _alerts.take(a.id, me);
      if (other != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('alreadyTaken', {'name': other}))));
      }
    } catch (_) {
      _fail();
    }
  }

  Future<void> _resolve(CaisseAlert a) async {
    await NotificationService.dismiss(a.id);
    try {
      await _alerts.resolve(a.id, me);
    } catch (_) {
      _fail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('openAlerts')),
        actions: [
          IconButton(
            tooltip: tr('history'),
            icon: const Icon(Icons.history),
            onPressed: _storeId.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HistoryScreen(storeId: _storeId))),
          ),
          PopupMenuButton<String>(
            tooltip: tr('menu'),
            onSelected: (v) async {
              switch (v) {
                case 'tone':
                  _chooseTone();
                case 'codes':
                  _showTillCodes();
                case 'lang':
                  final l = AppLang.instance.value == 'fr' ? 'en' : 'fr';
                  await AppLang.instance.set(l);
                  AuthService().saveLang(me.uid, l).catchError((_) {});
                case 'password':
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const PasswordScreen()));
                case 'logout':
                  _logout();
              }
            },
            itemBuilder: (_) => [
              if (DutyBackground.supported)
                _menuItem('tone', Icons.music_note, tr('ringtone')),
              _menuItem('codes', Icons.point_of_sale, tr('tillCodes')),
              _menuItem('lang', Icons.language,
                  AppLang.instance.value == 'fr' ? 'English' : 'Français'),
              _menuItem('password', Icons.key, tr('changePassword')),
              _menuItem('logout', Icons.logout, tr('signOut')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _DutyBar(
            user: me,
            storeName: me.dutyStoreId != null ? _storeName(me.dutyStoreId!) : '',
            busy: _busy,
            onStart: _startDuty,
            onEnd: _endDuty,
          ),
          Expanded(
            child: _storeId.isEmpty
                ? const SizedBox.shrink()
                : StreamBuilder<List<CaisseAlert>>(
                    stream: _alerts.active(_storeId),
                    builder: (context, snap) {
                      if (snap.hasError) return Center(child: Text(tr('connError')));
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final alerts = snap.data!;
                      if (alerts.isEmpty) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle, size: 64, color: Colors.green),
                            const SizedBox(height: 12),
                            Text(tr('allGood'), style: const TextStyle(fontSize: 18)),
                          ]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: alerts.length,
                        itemBuilder: (_, i) => _AlertCard(
                          alert: alerts[i],
                          lang: lang,
                          meId: me.uid,
                          onTake: () => _take(alerts[i]),
                          onResolve: () => _resolve(alerts[i]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

PopupMenuItem<String> _menuItem(String value, IconData icon, String label) => PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ]),
    );

/// Bandeau « En service / Hors service ».
class _DutyBar extends StatelessWidget {
  const _DutyBar({
    required this.user,
    required this.storeName,
    required this.busy,
    required this.onStart,
    required this.onEnd,
  });
  final AppUser user;
  final String storeName;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final on = user.isOnDutyNow;
    final color = on ? Colors.green : Colors.grey;
    return Material(
      color: color.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(children: [
          Icon(on ? Icons.notifications_active : Icons.notifications_off, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(on ? tr('onDutyAt', {'store': storeName}) : tr('offDuty'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                on
                    ? tr('dutyExpires', {'time': DateFormat.Hm().format(user.dutyUntil!)})
                    : tr('offDutyInfo'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : on
                  ? TextButton(onPressed: onEnd, child: Text(tr('endDuty')))
                  : FilledButton(onPressed: onStart, child: Text(tr('startDuty'))),
        ]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.lang,
    required this.meId,
    required this.onTake,
    required this.onResolve,
  });
  final CaisseAlert alert;
  final String lang;
  final String meId;
  final VoidCallback onTake;
  final VoidCallback onResolve;

  String _since(DateTime? t) {
    if (t == null) return tr('justNow');
    final m = DateTime.now().difference(t).inMinutes;
    return m < 1 ? tr('justNow') : tr('minAgo', {'m': '$m'});
  }

  @override
  Widget build(BuildContext context) {
    final open = alert.status == 'open';
    final mine = alert.takenBy == meId;
    final color = open ? Colors.red : Colors.orange;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.point_of_sale, color: color),
              const SizedBox(width: 8),
              Text(tr('register', {'n': alert.register}),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(_since(alert.createdAt)),
            ]),
            const SizedBox(height: 8),
            Text(alert.typeLabel(lang), style: const TextStyle(fontSize: 17)),
            if (alert.message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('« ${alert.message} »'),
            ],
            const SizedBox(height: 4),
            Text(tr('cashier', {'name': alert.cashierName}),
                style: Theme.of(context).textTheme.bodySmall),
            if (!open) ...[
              const SizedBox(height: 6),
              Text(
                mine ? tr('takenByYou') : tr('takenBy', {'name': alert.takenByName ?? '—'}),
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: open
                  ? FilledButton.icon(
                      onPressed: onTake,
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.directions_run),
                      label: Text(tr('imComing')),
                    )
                  : mine
                      ? FilledButton.icon(
                          onPressed: onResolve,
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.check),
                          label: Text(tr('resolved')),
                        )
                      : OutlinedButton.icon(
                          onPressed: onResolve,
                          icon: const Icon(Icons.check),
                          label: Text(tr('resolved')),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
