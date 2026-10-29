import 'dart:async';

import 'package:flutter/material.dart';
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
import '../widgets/lang_menu.dart';
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
  Timer? _ticker;

  AppUser get me => widget.user;

  /// Magasin affiché : celui du service en cours, sinon le premier.
  String get _storeId =>
      (me.isOnDutyNow ? me.dutyStoreId : null) ??
      (me.storeIds.isNotEmpty ? me.storeIds.first : '');

  @override
  void initState() {
    super.initState();
    NotificationService.instance.registerManager(me.uid);
    AuthService().saveLang(me.uid, AppLang.instance.value);
    StoreService().list(me.storeIds).then((s) {
      if (mounted) setState(() => _stores = s);
      // Déjà en service (téléphone redémarré, app relancée) : on relance l'écoute.
      if (me.isOnDutyNow && me.dutyStoreId != null) {
        DutyBackground.start(
          storeId: me.dutyStoreId!,
          storeName: _storeName(me.dutyStoreId!),
          lang: AppLang.instance.value,
          until: me.dutyUntil!,
        );
      }
    });
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

  Future<void> _logout() async {
    if (me.onDuty) await _duty.end(me.uid);
    await DutyBackground.stop();
    await NotificationService.instance.unregisterManager(me.uid);
    await AuthService().signOut();
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
    await prefs.setString('lastStore', store.id);
    setState(() => _busy = true);
    final err = await _duty.start(me, store);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _take(CaisseAlert a) async {
    final other = await _alerts.take(a.id, me);
    await NotificationService.dismiss(a.id);
    if (other != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('alreadyTaken', {'name': other}))));
    }
  }

  Future<void> _resolve(CaisseAlert a) async {
    await _alerts.resolve(a.id, me);
    await NotificationService.dismiss(a.id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLang.instance.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('openAlerts')),
        actions: [
          LangMenu(onChanged: (l) => AuthService().saveLang(me.uid, l)),
          IconButton(
            tooltip: tr('history'),
            icon: const Icon(Icons.history),
            onPressed: _storeId.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HistoryScreen(storeId: _storeId))),
          ),
          IconButton(
            tooltip: tr('changePassword'),
            icon: const Icon(Icons.key),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PasswordScreen())),
          ),
          IconButton(
            tooltip: tr('signOut'),
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
            onEnd: () => _duty.end(me.uid),
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
