import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Android, app fermée ou en arrière-plan.
/// Le serveur envoie deux sortes de messages "data" :
///  - action=alert : nouvelle alerte -> sonnerie d'alarme en boucle
///  - action=stop  : un autre manager a répondu -> la sonnerie s'arrête
///                   et une notification silencieuse dit qui arrive
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb && Platform.isAndroid) {
    await NotificationService.handleData(message.data);
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const alarmChannel = 'alertes_caisse_v1';
  static const infoChannel = 'alertes_caisse_info_v1';

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static final _local = FlutterLocalNotificationsPlugin();
  static bool _localReady = false;

  static Future<void> _initLocal() async {
    if (_localReady) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(settings);

    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // Canal « alarme » : sonne même en mode silencieux/vibreur.
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      alarmChannel,
      'Alertes caisse',
      description: 'Alertes urgentes envoyées par les caisses',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarme'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
    // Canal silencieux : « Honey arrive », alerte résolue…
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      infoChannel,
      'Suivi des alertes',
      description: 'Qui a pris en charge une alerte',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ));
    _localReady = true;
  }

  static int _id(String alertId) => alertId.hashCode & 0x7fffffff;

  static Future<void> handleData(Map<String, dynamic> data) async {
    final alertId = (data['alertId'] ?? '').toString();
    if (alertId.isEmpty) return;
    if (data['action'] == 'stop') {
      await showStopped(alertId, data['title'], data['body']);
    } else {
      await showAlarm(data);
    }
  }

  /// Notification plein écran qui sonne en boucle jusqu'à réaction.
  static Future<void> showAlarm(Map<String, dynamic> data) async {
    await _initLocal();
    final alertId = (data['alertId'] ?? '').toString();
    final details = AndroidNotificationDetails(
      alarmChannel,
      'Alertes caisse',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarme'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
      ticker: 'Alerte caisse',
      // 4 = FLAG_INSISTENT : le son se répète jusqu'à ce que quelqu'un réagisse.
      additionalFlags: Int32List.fromList([4]),
    );
    await _local.show(
      _id(alertId),
      data['title'] ?? 'Alerte caisse',
      data['body'] ?? '',
      NotificationDetails(android: details),
      payload: alertId,
    );
  }

  /// Remplace l'alarme par une notification silencieuse (même identifiant :
  /// la sonnerie s'arrête immédiatement).
  static Future<void> showStopped(String alertId, String? title, String? body) async {
    await _initLocal();
    await _local.cancel(_id(alertId));
    if (title == null) return;
    await _local.show(
      _id(alertId),
      title,
      body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          infoChannel,
          'Suivi des alertes',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          timeoutAfter: 60000, // disparaît après 1 minute
        ),
      ),
      payload: alertId,
    );
  }

  /// Arrête la sonnerie localement (le manager a lui-même répondu).
  static Future<void> dismiss(String alertId) async {
    if (!isSupported) return;
    await _initLocal();
    await _local.cancel(_id(alertId));
  }

  Future<void> init() async {
    if (!isSupported) return;
    await _initLocal();

    final fm = FirebaseMessaging.instance;
    await fm.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      criticalAlert: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await fm.setForegroundNotificationPresentationOptions(
        alert: true, sound: true, badge: true);

    FirebaseMessaging.onMessage.listen((m) {
      if (Platform.isAndroid) handleData(m.data);
    });
  }

  /// Enregistre ce téléphone pour recevoir les alertes.
  Future<void> registerManager(String uid) async {
    if (!isSupported) return;
    final fm = FirebaseMessaging.instance;
    if (Platform.isIOS) {
      for (var i = 0; i < 10 && await fm.getAPNSToken() == null; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    final token = await fm.getToken();
    if (token != null) await _saveToken(uid, token);
    fm.onTokenRefresh.listen((t) => _saveToken(uid, t));
  }

  Future<void> _saveToken(String uid, String token) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

  Future<void> unregisterManager(String uid) async {
    if (!isSupported) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}
