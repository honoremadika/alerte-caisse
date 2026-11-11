#!/usr/bin/env bash
# Essai réel sur un téléphone Android virtuel : l'APK s'installe, l'app démarre et ne plante pas.
# Lancé par la mise en ligne automatique (job « Essai sur téléphone virtuel »).
set -u
APK="$1"; PKG=tech.geniuslabs.alerte_caisse
fail() { echo "::error::$1"; exit 1; }

OUT=$(adb install -r "$APK" 2>&1) || fail "Installation refusée : $(echo "$OUT" | tail -1)"
echo "::notice::Installation de l'APK : réussie"
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb logcat -c
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || fail "L'app ne se lance pas"
sleep 40
adb logcat -d > logcat.txt
if grep -q "FATAL EXCEPTION" logcat.txt; then
  grep -A12 "FATAL EXCEPTION" logcat.txt | head -30 | while IFS= read -r l; do echo "::error::$l"; done
  exit 1
fi
PID=$(adb shell pidof $PKG | tr -d '\r')
[ -n "$PID" ] || fail "L'app s'est fermée toute seule après le démarrage"
grep -E "E/flutter|Unhandled Exception" logcat.txt | head -15 | while IFS= read -r l; do echo "::warning::$l"; done
adb exec-out screencap -p > ecran-android.png
echo "::notice::App démarrée et toujours ouverte après 40 s (aucun plantage). Android $(adb shell getprop ro.build.version.release | tr -d '\r')"
