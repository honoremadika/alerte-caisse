import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/station.dart';
import '../services/desktop_overlay.dart';
import '../services/station_service.dart';
import '../widgets/caisse_theme.dart';
import 'cashier_screen.dart';

/// App Caisse (PC) : pas d'identifiant ni de mot de passe.
/// Session anonyme + poste ouvert une seule fois avec le code du magasin.
class CaisseGate extends StatefulWidget {
  const CaisseGate({super.key});

  @override
  State<CaisseGate> createState() => _CaisseGateState();
}

class _CaisseGateState extends State<CaisseGate> {
  final _stations = StationService.instance;
  bool _loading = true;
  bool _failed = false;
  String? _sid;
  String _name = '';
  bool _resetting = false;
  bool _serverOff = false; // connexion des postes désactivée côté serveur

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _failed = false;
      _serverOff = false;
    });
    try {
      // Ancienne version : un compte caissier était connecté sur ce PC. On passe au poste.
      final u = FirebaseAuth.instance.currentUser;
      if (u != null && !u.isAnonymous) await FirebaseAuth.instance.signOut();
      await _stations.ensureSession();
      _sid = await _stations.savedId();
      if (_sid != null) {
        try {
          await _stations.rebindIfNeeded(_sid!);
        } on FirebaseException catch (e) {
          // Poste supprimé ou refusé côté serveur : on repart sur l'écran du code.
          if (e.code == 'permission-denied' || e.code == 'not-found') {
            await _stations.forget();
            _sid = null;
          } else {
            rethrow;
          }
        }
      }
      _name = await _stations.cashierName();
    } on FirebaseAuthException catch (e) {
      _failed = true;
      _serverOff = e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation';
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reset() async {
    if (_resetting) return;
    _resetting = true;
    try {
      await _stations.forget();
      if (mounted) setState(() => _sid = null);
      await DesktopOverlay.expand();
    } finally {
      _resetting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const CaissePage(child: Center(child: CircularProgressIndicator()));
    if (_failed) {
      return CaissePage(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, size: 40, color: CaisseColors.muted),
            const SizedBox(height: 12),
            Text(tr(_serverOff ? 'postsDisabled' : 'connectFailed'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _start, child: Text(tr('retry'))),
          ]),
        ),
      );
    }
    if (_sid == null) {
      return StationSetupScreen(onDone: (sid, name) => setState(() {
            _sid = sid;
            _name = name;
          }));
    }
    return StreamBuilder<Station?>(
      stream: _stations.watch(_sid!),
      builder: (context, snap) {
        if (snap.hasError) {
          // Poste supprimé ou plus accessible : on en ouvre un nouveau.
          final e = snap.error;
          if (e is FirebaseException && e.code == 'permission-denied') {
            WidgetsBinding.instance.addPostFrameCallback((_) => _reset());
          }
          return const CaissePage(child: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const CaissePage(child: Center(child: CircularProgressIndicator()));
        }
        final s = snap.data;
        if (s == null || s.isRefused) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _reset());
          return const CaissePage(child: Center(child: CircularProgressIndicator()));
        }
        if (!s.isApproved) {
          // Poste créé avec l'ancienne méthode (validation par un manager).
          return CaissePage(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('waitTitle'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(tr('waitLead'), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(s.code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 6)),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _reset, child: Text(tr('changePost'))),
              ]),
            ),
          );
        }
        return CashierScreen(
          user: _stations.asCashier(s, _name),
          stationId: s.id,
          onRename: (v) async {
            await _stations.setCashierName(v);
            if (mounted) setState(() => _name = v.trim());
          },
          onChangePost: _reset,
        );
      },
    );
  }
}

/// Écran d'installation du poste : code du magasin + numéro de caisse.
class StationSetupScreen extends StatefulWidget {
  const StationSetupScreen({super.key, required this.onDone});
  final void Function(String sid, String name) onDone;

  @override
  State<StationSetupScreen> createState() => _StationSetupScreenState();
}

class _StationSetupScreenState extends State<StationSetupScreen> {
  final _code = TextEditingController();
  final _till = TextEditingController();
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    final till = _till.text.trim();
    if (StationService.normalizeCode(_code.text).length < 6) {
      setState(() => _error = tr('badCode'));
      return;
    }
    if (till.isEmpty || till.length > 4) {
      setState(() => _error = tr('needTill'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sid = await StationService.instance.joinWithCode(_code.text, till);
      await StationService.instance.setCashierName(_name.text);
      widget.onDone(sid, _name.text.trim());
    } on StateError {
      setState(() => _error = tr('badCode'));
    } on FirebaseException catch (e) {
      setState(() => _error = e.code == 'permission-denied' ? tr('badCode') : tr('connectFailed'));
    } catch (_) {
      setState(() => _error = tr('connectFailed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CaissePage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(tr('setupTitle'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tr('setupIntro'), style: const TextStyle(color: CaisseColors.muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2),
            decoration: caisseInput(tr('storeCode'), hint: tr('storeCodeHint'), icon: Icons.vpn_key_outlined),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _till,
            maxLength: 4,
            decoration: caisseInput(tr('tillNumber'), hint: '1', icon: Icons.point_of_sale),
            onSubmitted: (_) => _submit(),
          ),
          TextField(
            controller: _name,
            maxLength: 30,
            decoration: caisseInput(tr('cashierNameOpt'), icon: Icons.person_outline),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: CaisseColors.alarmSoft, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: CaisseColors.accent, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: CaisseColors.side),
              child: Text(_busy ? '…' : tr('startPost'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
