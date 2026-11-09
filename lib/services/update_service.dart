import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Android installé hors Play Store (fichier .apk) : signale une nouvelle version.
/// Installé depuis le Play Store, c'est le Play Store qui met à jour : rien à faire.
class UpdateService {
  static const _repo = 'honoremadika/alerte-caisse';
  static const apkUrl =
      'https://github.com/$_repo/releases/latest/download/AlerteManager-tous-telephones.apk';

  /// Nouvelle version disponible ? (ne lève jamais d'erreur)
  static Future<bool> available() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.installerStore == 'com.android.vending') return false;
      // versionCode : 100 + n° de compilation (+ 1000/2000… selon le processeur).
      final mine = (int.tryParse(info.buildNumber) ?? 0) % 1000;
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$_repo/releases/latest'));
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('User-Agent', 'AlerteManager');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      client.close();
      // Étiquette « v2.0.0-13 » : 13 = n° de compilation → versionCode 113.
      final run = int.tryParse((body['tag_name'] ?? '').toString().split('-').last) ?? 0;
      return mine > 0 && 100 + run > mine;
    } catch (_) {
      return false;
    }
  }

  static Future<void> download() =>
      launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
}
