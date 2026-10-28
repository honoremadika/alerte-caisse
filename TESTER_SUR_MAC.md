# Tester la vraie application sur un MacBook

Le Mac joue le rôle de **l'ordinateur de caisse**. Le **téléphone du manager** est :
- un **émulateur Android** sur le Mac (gratuit, la vraie sonnerie fonctionne), ou
- ton **téléphone Android** branché en USB (gratuit), ou
- un **iPhone** (il faut un compte Apple Developer payant, 99 $/an, pour recevoir les notifications).

Compte environ 1 h 30 pour la première installation.

---

## 1. Installer les outils (une seule fois)

Dans le Terminal :

```bash
# Homebrew (si tu ne l'as pas) : https://brew.sh
brew install --cask flutter
brew install cocoapods node@20
npm install -g firebase-tools
dart pub global activate flutterfire_cli
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc && source ~/.zshrc
```

Installe aussi depuis l'App Store **Xcode**, puis :
```bash
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

Et **Android Studio** (https://developer.android.com/studio) : au premier lancement, laisse-le installer le SDK Android.

Vérification : `flutter doctor`. Les lignes **Xcode**, **Android toolchain** et **macOS** doivent être ✓. Si une ligne affiche une commande à lancer (ex. `flutter doctor --android-licenses`), lance-la.

---

## 2. Créer le projet Firebase

1. https://console.firebase.google.com → **Ajouter un projet** → nom `alerte-caisse`.
2. **Build → Authentication** → Commencer → activer **E-mail/Mot de passe**.
3. **Build → Firestore Database** → Créer → région `europe-west1` → mode production.
4. En bas à gauche : passer au forfait **Blaze** (carte bancaire). Obligatoire pour le serveur qui envoie les notifications. Pour des tests, le coût est de 0 $. Mets une alerte de budget à 1 $.

---

## 3. Préparer le projet sur le Mac

Dézippe `alerte_caisse.zip` (par ex. dans `~/Projets`), puis :

```bash
cd ~/Projets/alerte_caisse
flutter create --platforms=macos,android,ios --org tech.geniuslabs .
firebase login
firebase use --add            # choisis alerte-caisse
flutterfire configure         # coche macos, android, ios → crée lib/firebase_options.dart
flutter pub get
```

### Réglages macOS (obligatoires)

**a) Autoriser internet et la connexion** — ouvre `macos/Runner/DebugProfile.entitlements` **et** `macos/Runner/Release.entitlements` et ajoute dans `<dict>` :

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array/>
```

**b) Version minimale de macOS** — dans `macos/Podfile`, la première ligne doit être :
```ruby
platform :osx, '10.15'
```

**c) Signature** — `open macos/Runner.xcworkspace` → clique sur **Runner** → onglet **Signing & Capabilities** → **Team** : choisis ton Apple ID (un compte gratuit suffit) → ajoute la capability **Keychain Sharing**. Ferme Xcode.

### Réglages Android
Fais l'étape 4 du README (son `alarme.wav` dans `res/raw`, permissions, `minSdk 23`, desugaring).

---

## 4. Déployer le serveur

```bash
cd functions && npm install && cd ..
firebase deploy --only firestore,functions
```
Le premier déploiement prend 3 à 5 minutes. Si on te demande d'activer des API (Cloud Functions, Cloud Build, Eventarc, Cloud Scheduler), réponds oui.

---

## 5. Créer les comptes de test

1. Console Firebase → ⚙️ **Paramètres du projet → Comptes de service → Générer une nouvelle clé privée**. Range le fichier hors du projet, par ex. `~/cles/alerte-caisse.json`.
2. Lance :
```bash
node tools/seed.js ~/cles/alerte-caisse.json
```

Comptes créés (mot de passe **Test1234!** pour tous) :

| Email | Rôle | Magasin |
|---|---|---|
| caisse3@test.com | Caissier (Grâce, caisse 3) | KM 01 · Gombe |
| honey@test.com | Manager | KM 01 + KM 06 |
| higelin@test.com | Manager | KM 01 · Gombe |
| ceda@test.com | Manager (anglais) | KM 01 · Gombe |
| patrick@test.com | Manager | KM 06 · Limete |

La vérification des 200 m est désactivée pour les tests (pas de coordonnées sur les magasins).

---

## 6. Lancer le téléphone du manager

### Option A : émulateur Android (recommandé)
1. Android Studio → **Device Manager** → **Create device** → Pixel 7 → choisis une image **avec l'icône Google Play** (indispensable pour les notifications) → Finish → ▶︎.
2. Dans le Terminal :
```bash
flutter run -t lib/main_manager.dart -d emulator-5554
```
3. Connecte-toi avec `honey@test.com` → accepte les notifications → **Prendre mon service** → choisis Gombe.
4. Mets l'app en arrière-plan (bouton rond) ou verrouille l'émulateur.

### Option B : ton téléphone Android
Active les **Options développeur** (Paramètres → À propos → appuie 7 fois sur « Numéro de build ») puis **Débogage USB**, branche le téléphone, et `flutter devices` pour voir son nom, puis `flutter run -t lib/main_manager.dart -d <nom>`.

---

## 7. Lancer la caisse sur le Mac

Dans un **deuxième** onglet du Terminal :
```bash
cd ~/Projets/alerte_caisse
flutter run -t lib/main_caisse.dart -d macos
```
Connecte-toi avec `caisse3@test.com`. Après la connexion, le panneau peut être réduit en bulle : clique dessus ou fais **Control + Option + A**.

> Sur Mac, la bulle peut apparaître dans un petit carré gris au lieu d'un rond : c'est une limite d'affichage propre à macOS, sans conséquence. Sur les caisses Windows, elle est ronde.

---

## 8. Le test

1. Sur le Mac : **Modification de quantité** → **ENVOYER L'ALERTE**.
2. Le téléphone (ou l'émulateur) **sonne en boucle** en moins de 2 secondes.
3. Appuie sur **J'arrive** : sur le Mac, la caisse affiche **« Honey arrive »**.
4. Appuie sur **Problème résolu** → onglet **Historique**.
5. Ne réponds pas à une alerte : elle est relancée chaque minute.

### Tester plusieurs managers en même temps
Lance un 2ᵉ émulateur (ou émulateur + ton téléphone) connecté avec `higelin@test.com` en service à Gombe. Les deux sonnent ; quand Honey répond, Higelin s'arrête et lit « Honey arrive ». Un 3ᵉ appareil avec `patrick@test.com` (Limete) ne sonne pas.

---

## En cas de problème

| Symptôme | Solution |
|---|---|
| Mac : « network error » ou la connexion tourne sans fin | Étape 3a (network.client) oubliée. |
| Mac : erreur `keychain-error` | Étape 3a + 3c (Keychain Sharing et Team). |
| `pod install` échoue | `cd macos && pod repo update && pod install && cd ..` |
| Le téléphone ne sonne pas | Le manager a-t-il pris son service ? Émulateur avec Google Play ? Console Firebase → Functions → **Journaux** de `notifierManagers`. |
| Écran manager vide ou « Erreur de connexion » | Les index Firestore se construisent encore (quelques minutes après le déploiement). Le lien de création d'index s'affiche aussi dans le Terminal. |
| Compte « sans profil » | Relancer `node tools/seed.js …`. |

Envoie-moi le message d'erreur exact du Terminal si tu bloques.
