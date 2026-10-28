import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

/// VERSION GRATUITE (Firebase Spark, sans Cloud Functions).
///
/// Pendant le service, le téléphone Android garde un « service de premier
/// plan » (notification permanente « En service ») qui écoute les alertes du
/// magasin en temps réel et fait sonner le téléphone lui-même, même si l'app
/// est fermée ou l'écran verrouillé. Il gère aussi :
///  - l'arrêt de la sonnerie quand un autre manager répond (« Honey arrive »)
///  - les relances toutes les minutes (5 au maximum)
///  - la fin automatique du service.

const _kStore = 'ac_store';
const _kLang = 'ac_lang';
const _kUntil = 'ac_until';

class DutyBackground {
  static bool get supported => !kIsWeb && Platform.isAndroid;
  static bool _ready = false;

  static void _init() {
    if (_ready) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alertes_caisse_service',
        channelName: 'Service en cours',
        channelDescription: 'Affichée pendant que vous êtes en service',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _ready = true;
  }

  /// Démarre (ou redémarre) l'écoute pour ce magasin.
  static Future<void> start({
    required String storeId,
    required String storeName,
    required String lang,
    required DateTime until,
  }) async {
    if (!supported) return;
    _init();
    if (await FlutterForegroundTask.checkNotificationPermission() !=
        NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    // Sans cela, certains Android (Tecno, Infinix, Xiaomi…) coupent l'écoute.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    await FlutterForegroundTask.saveData(key: _kStore, value: storeId);
    await FlutterForegroundTask.saveData(key: _kLang, value: lang);
    await FlutterForegroundTask.saveData(key: _kUntil, value: until.millisecondsSinceEpoch);

    final title = lang == 'en' ? 'On duty · $storeName' : 'En service · $storeName';
    final text = lang == 'en'
        ? 'Till alerts will ring on this phone.'
        : 'Les alertes des caisses sonneront sur ce téléphone.';
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await FlutterForegroundTask.startService(
      serviceId: 4242,
      notificationTitle: title,
      notificationText: text,
      callback: dutyTaskCallback,
    );
  }

  static Future<void> stop() async {
    if (!supported) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

@pragma('vm:entry-point')
void dutyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_DutyTaskHandler());
}

class _DutyTaskHandler extends TaskHandler {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Map<String, Map<String, dynamic>> _open = {};
  final Map<String, DateTime> _lastRing = {};
  final Map<String, int> _relances = {};
  String _lang = 'fr';
  int _until = 0;
  String? _uid;

  String _t(String fr, String en) => _lang == 'en' ? en : fr;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final store = await FlutterForegroundTask.getData<String>(key: _kStore) ?? '';
    _lang = await FlutterForegroundTask.getData<String>(key: _kLang) ?? 'fr';
    _until = await FlutterForegroundTask.getData<int>(key: _kUntil) ?? 0;
    if (store.isEmpty) return;

    _sub = FirebaseFirestore.instance
        .collection('alerts')
        .where('storeId', isEqualTo: store)
        .where('status', whereIn: ['open', 'taken'])
        .snapshots()
        .listen(_onSnapshot, onError: (_) {});
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final ch in snap.docChanges) {
      final id = ch.doc.id;
      final d = ch.doc.data() ?? const {};
      if (ch.type == DocumentChangeType.removed) {
        // résolue ou annulée
        if (_open.remove(id) != null) NotificationService.dismiss(id);
        _forget(id);
        continue;
      }
      final status = d['status'];
      if (status == 'open') {
        final created = (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        // Une alerte de plus de 10 minutes au moment de la prise de service ne sonne pas.
        if (!_open.containsKey(id) &&
            DateTime.now().difference(created) < const Duration(minutes: 10)) {
          _open[id] = d;
          _ring(id, d, 0);
        }
      } else if (status == 'taken') {
        if (_open.remove(id) != null) {
          final name = (d['takenByName'] ?? '').toString();
          if (d['takenBy'] == _uid) {
            NotificationService.dismiss(id);
          } else {
            // La sonnerie s'arrête et on dit qui arrive.
            NotificationService.showStopped(
              id,
              _t('$name arrive · Caisse ${d['register']}', '$name is on the way · Till ${d['register']}'),
              _t('Alerte prise en charge, la sonnerie est arrêtée.', 'Alert taken, ringing stopped.'),
            );
          }
        }
        _forget(id);
      }
    }
  }

  void _forget(String id) {
    _lastRing.remove(id);
    _relances.remove(id);
  }

  void _ring(String id, Map<String, dynamic> d, int relance) {
    final reg = d['register'] ?? '';
    final label = _lang == 'en' ? (d['typeEn'] ?? d['typeFr'] ?? '') : (d['typeFr'] ?? '');
    final msg = (d['message'] ?? '').toString();
    NotificationService.showAlarm({
      'alertId': id,
      'title': relance > 0
          ? _t('🚨 RELANCE $relance · Caisse $reg', '🚨 REMINDER $relance · Till $reg')
          : _t('🚨 Caisse $reg', '🚨 Till $reg'),
      'body': '$label — ${d['cashierName'] ?? ''}${msg.isNotEmpty ? ' : $msg' : ''}',
    });
    _lastRing[id] = DateTime.now();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Fin de service automatique.
    if (_until > 0 && DateTime.now().millisecondsSinceEpoch > _until) {
      FlutterForegroundTask.stopService();
      return;
    }
    // Relance chaque minute, 5 fois au maximum.
    final now = DateTime.now();
    _open.forEach((id, d) {
      final last = _lastRing[id];
      final n = _relances[id] ?? 0;
      if (last != null && n < 5 && now.difference(last) >= const Duration(seconds: 60)) {
        _relances[id] = n + 1;
        _ring(id, d, n + 1);
      }
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _sub?.cancel();
  }
}
