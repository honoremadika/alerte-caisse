#!/usr/bin/env python3
"""
Prépare les dossiers de plateforme créés par `flutter create` pour Alerte Caisse.
Lancé par la compilation automatique (GitHub Actions), et utilisable à la main :

    flutter create --platforms=android,windows,macos --org tech.geniuslabs .
    python3 tools/ci_prepare.py

Ce que le script règle :
  Android : son d'alarme, permissions (notifications, plein écran, localisation),
            affichage sur écran verrouillé, minSdk 23, desugaring, nom de l'app.
  macOS   : accès internet, macOS 10.15 minimum.
Il peut être relancé sans risque : il ne modifie pas deux fois la même chose.
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
done = []


def patch(path: Path, fn):
    if not path.exists():
        return
    old = path.read_text(encoding="utf-8")
    new = fn(old)
    if new != old:
        path.write_text(new, encoding="utf-8")
        done.append(str(path.relative_to(ROOT)))


# ---------------- Android ----------------
android = ROOT / "android" / "app"
if android.exists():
    raw = android / "src" / "main" / "res" / "raw"
    raw.mkdir(parents=True, exist_ok=True)
    shutil.copy(ROOT / "assets" / "sons" / "alarme.wav", raw / "alarme.wav")
    done.append("android/app/src/main/res/raw/alarme.wav")

    PERMS = [
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.USE_FULL_SCREEN_INTENT",
        "android.permission.VIBRATE",
        "android.permission.WAKE_LOCK",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        # Version gratuite : écoute des alertes pendant le service
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_SPECIAL_USE",
        "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS",
    ]
    SERVICE = (
        '        <service\n'
        '            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"\n'
        '            android:foregroundServiceType="specialUse"\n'
        '            android:exported="false">\n'
        '            <property\n'
        '                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"\n'
        '                android:value="Alertes des caisses en temps réel pendant le service du manager" />\n'
        '        </service>\n'
    )

    def manifest(s: str) -> str:
        lines = "".join(
            f'    <uses-permission android:name="{p}"/>\n' for p in PERMS if p not in s
        )
        if lines:
            s = s.replace("<application", lines + "    <application", 1)
        s = re.sub(r'android:label="[^"]*"', 'android:label="Alerte Caisse"', s, count=1)
        if "flutter_foreground_task.service.ForegroundService" not in s:
            s = s.replace("    </application>", SERVICE + "    </application>", 1)
        if "showWhenLocked" not in s:
            s = s.replace(
                'android:name=".MainActivity"',
                'android:name=".MainActivity"\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"',
                1,
            )
        return s

    patch(android / "src" / "main" / "AndroidManifest.xml", manifest)

    DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.4"

    def gradle_kts(s: str) -> str:
        s = re.sub(r"minSdk\s*=\s*[^\n]+", "minSdk = 23", s, count=1)
        if "isCoreLibraryDesugaringEnabled" not in s:
            s = s.replace("compileOptions {", "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
        if DESUGAR not in s:
            s += f'\ndependencies {{\n    coreLibraryDesugaring("{DESUGAR}")\n}}\n'
        return s

    def gradle_groovy(s: str) -> str:
        s = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", "minSdkVersion 23", s, count=1)
        if "coreLibraryDesugaringEnabled" not in s:
            s = s.replace("compileOptions {", "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
        if DESUGAR not in s:
            s += f"\ndependencies {{\n    coreLibraryDesugaring '{DESUGAR}'\n}}\n"
        return s

    patch(android / "build.gradle.kts", gradle_kts)
    patch(android / "build.gradle", gradle_groovy)

# ---------------- macOS ----------------
mac = ROOT / "macos"
if mac.exists():
    def entitlements(s: str) -> str:
        if "com.apple.security.network.client" not in s:
            s = s.replace(
                "<dict>",
                "<dict>\n\t<key>com.apple.security.network.client</key>\n\t<true/>",
                1,
            )
        return s

    patch(mac / "Runner" / "DebugProfile.entitlements", entitlements)
    patch(mac / "Runner" / "Release.entitlements", entitlements)
    patch(mac / "Podfile", lambda s: re.sub(r"#?\s*platform :osx, '[\d.]+'", "platform :osx, '10.15'", s))
    patch(
        mac / "Runner.xcodeproj" / "project.pbxproj",
        lambda s: re.sub(r"MACOSX_DEPLOYMENT_TARGET = 10\.\d+;", "MACOSX_DEPLOYMENT_TARGET = 10.15;", s),
    )

print("Fichiers préparés :" if done else "Rien à modifier.")
for f in done:
    print("  -", f)
sys.exit(0)
