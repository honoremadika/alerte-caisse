#!/bin/bash
# Test sur un téléphone Android virtuel : l'app s'installe, démarre et ne plante pas.
APK="$1"; PKG=tech.geniuslabs.alerte_caisse
adb install -r "$APK" > install.log 2>&1 || { echo "::error::Installation refusée : $(tail -1 install.log)"; exit 1; }
echo "::notice::Installation sur Android $(adb shell getprop ro.build.version.release) : OK"
adb logcat -c
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS || true
adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
sleep 40
adb exec-out screencap -p > ecran-android.png || true
adb logcat -d > logcat.txt
if grep -q "FATAL EXCEPTION" logcat.txt; then
  grep -A12 "FATAL EXCEPTION" logcat.txt | head -30 | while IFS= read -r l; do echo "::error::$l"; done
  exit 1
fi
if [ -z "$(adb shell pidof $PKG)" ]; then echo "::error::L'app s'est fermée toute seule après le démarrage"; grep -iE "flutter|$PKG" logcat.txt | tail -15 | while IFS= read -r l; do echo "::error::$l"; done; exit 1; fi
grep -E "E/flutter|Unhandled Exception" logcat.txt | head -10 | while IFS= read -r l; do echo "::warning::$l"; done
echo "::notice::Démarrage : OK, l'app tourne sans plantage après 40 secondes"
