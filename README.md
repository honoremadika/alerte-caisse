# Alerte Caisse (Till Alert)

> Pour tester sur un Mac : voir **TESTER_SUR_MAC.md**.
> Pour mettre les apps en ligne (page de téléchargement Android / Windows / macOS) : voir **MISE_EN_LIGNE.md**.

## Deux applications

| App | Point d'entrée | Appareils | Commande |
|---|---|---|---|
| **Caisse** | `lib/main_caisse.dart` | Windows, macOS | `flutter build windows -t lib/main_caisse.dart` |
| **Manager** | `lib/main_manager.dart` | Android, iPhone | `flutter build apk -t lib/main_manager.dart` |

Un compte caissier ne peut pas ouvrir l'app Manager, et inversement. Le code commun (modèles, services, textes FR/EN) est partagé dans `lib/`.

Le caissier appuie sur la **bulle rouge** (ou `Ctrl + Alt + A`) par-dessus son logiciel de caisse → **tous les managers en service dans ce magasin** sonnent en même temps → le premier qui appuie sur **« J'arrive »** arrête la sonnerie chez les autres, qui voient « Honey arrive » → le caissier voit aussi **« Honey arrive »** → « Problème résolu » → historique.

Application en **français et en anglais** (choix sur chaque appareil).

| Rôle | Appareil | Ce qu'il voit |
|---|---|---|
| Caissier | Ordinateur Windows | Bulle flottante toujours au-dessus de la caisse ; panneau d'alerte au clic ou au raccourci |
| Manager | Android ou iPhone | « Prendre mon service », alertes, « J'arrive », « Résolu », historique |

---

## Nouveautés de la version 1.1

1. **Langue FR / EN** — bouton « FR/EN » sur tous les écrans. Le choix est mémorisé, et les notifications des managers arrivent dans leur langue.
2. **Par-dessus n'importe quel logiciel** — sur l'ordinateur, l'app est une petite bulle ronde toujours au premier plan (`alwaysOnTop`), sans icône dans la barre des tâches. Elle se déplace en la glissant. Elle change de couleur : rouge (rien), orange (en attente), verte avec le nom du manager (il arrive).
3. **Raccourci clavier global** `Ctrl + Alt + A` : ouvre/ferme le panneau même quand le logiciel de caisse a le focus. Après l'envoi, le panneau se réduit seul. L'app démarre avec Windows.
4. **Nouveaux problèmes** : suppression d'article, annulation de facture, modification de quantité, authentification manager, réclamation client, remboursement, besoin de monnaie, panne, autre. Liste **modifiable par magasin** (voir plus bas).
5. **Plusieurs téléphones sonnent ensemble** et **la sonnerie s'arrête chez les autres** dès qu'un manager répond, avec le message « Honey arrive ».
6. **Le caissier voit le nom** de la personne qui arrive.
7. **Seuls les managers du bon magasin sonnent** (voir ci-dessous).

### Pourquoi pas un rayon GPS permanent de 200 m ?
Suivre la position de chaque téléphone en continu vide la batterie, marche mal à l'intérieur des bâtiments, demande sur iPhone l'autorisation « Toujours » (souvent refusée) et pose un problème de vie privée pour les employés.

**Solution retenue : magasin + prise de service.**
- Chaque magasin est un document `stores/{id}` ; chaque manager a la liste de ses magasins (`storeIds`), chaque caissier son magasin (`storeId`).
- En arrivant, le manager appuie sur **« Prendre mon service »**. L'app vérifie **une seule fois** qu'il est à moins de **200 m** du magasin (rayon réglable par magasin, `radiusM`).
- Une alerte ne fait sonner **que les managers en service dans ce magasin**. Les 100 autres personnes des autres magasins ne reçoivent rien.
- Le service **se termine automatiquement après 12 h** (ou avec « Terminer mon service », ou à la déconnexion).
- Si aucun manager n'est en service, le caissier voit un avertissement.

---

## Contenu du projet

```
lib/
  main.dart                       démarrage, langue, choix de l'écran
  l10n/strings.dart               textes FR / EN
  models/                         alerte, utilisateur, magasin, types de problèmes
  services/
    alert_service.dart            envoyer / « J'arrive » / résoudre / annuler
    duty_service.dart             prise de service + vérification 200 m
    desktop_overlay.dart          bulle toujours visible + Ctrl+Alt+A + démarrage Windows
    notification_service.dart     sonnerie d'alarme, arrêt de la sonnerie
    store_service.dart, auth_service.dart
  screens/                        connexion, caissier, manager, historique
  widgets/lang_menu.dart          bouton FR / EN
functions/index.js                serveur : envoi par magasin, arrêt chez les autres, relances, fin de service
firestore.rules                   sécurité
firestore.indexes.json            index
assets/sons/alarme.wav            son d'alarme
```

---

## Installation pas à pas

### 1. Outils
- [Flutter](https://docs.flutter.dev/get-started/install) (Visual Studio « Desktop development with C++ » pour Windows, Android Studio, et un Mac + Xcode pour iPhone)
- [Node.js 20](https://nodejs.org)
- `npm install -g firebase-tools`
- `dart pub global activate flutterfire_cli`

### 2. Projet Firebase
1. https://console.firebase.google.com → **Ajouter un projet**.
2. **Authentication** → activer **Adresse e-mail/Mot de passe**.
3. **Firestore Database** → Créer → région `europe-west1`.
4. Forfait **Blaze** (obligatoire pour les Cloud Functions ; coût quasi nul pour cet usage, mettre une alerte de budget à 1 $).

### 3. Dossiers des plateformes
```bash
flutter create --platforms=android,ios,windows,macos --org tech.geniuslabs .
firebase login
flutterfire configure          # crée lib/firebase_options.dart
flutter pub get
```

### 4. Android (managers)
1. Copier `assets/sons/alarme.wav` → `android/app/src/main/res/raw/alarme.wav`.
2. `android/app/src/main/AndroidManifest.xml`, avant `<application` :
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
   <uses-permission android:name="android.permission.VIBRATE"/>
   <uses-permission android:name="android.permission.WAKE_LOCK"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```
   et dans `<activity android:name=".MainActivity" …>` : `android:showWhenLocked="true" android:turnScreenOn="true"`.
3. `android/app/build.gradle` : `minSdk = 23`, et
   ```gradle
   compileOptions { coreLibraryDesugaringEnabled true }
   dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' }
   ```
4. Sur chaque téléphone : Applis → Alerte Caisse → Batterie → **Sans restriction**, et autoriser « Notifications plein écran » (important sur Tecno, Infinix, Xiaomi…).

### 5. iPhone (managers)
1. Xcode → `ios/Runner.xcworkspace` → **Signing & Capabilities** : *Push Notifications*, *Background Modes → Remote notifications*, *Time Sensitive Notifications*.
2. Glisser `assets/sons/alarme.wav` dans *Runner* (« Copy items if needed »).
3. `ios/Runner/Info.plist` : ajouter `NSLocationWhenInUseUsageDescription` = « Vérifier que vous êtes au magasin lors de la prise de service. »
4. Clé APNs (.p8) du compte Apple Developer → Firebase → Paramètres → Cloud Messaging.
5. Pour sonner malgré le mode silencieux : demander le droit *Critical Alerts* à Apple (https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/), puis `IOS_CRITICAL = true` dans `functions/index.js`.

> Sur iPhone, « Honey arrive » **remplace** la notification d'alerte (même identifiant). Le son d'une notification iPhone ne dure que quelques secondes : il n'y a donc pas de sonnerie à « couper » comme sur Android, où elle sonne en boucle jusqu'à la réponse.

### 6. Ordinateurs caissiers (Windows)
- `flutter build windows -t lib/main_caisse.dart` puis copier le dossier `build/windows/x64/runner/Release` sur chaque caisse.
- Au premier lancement, l'app s'ajoute au démarrage de Windows.
- Le logiciel de caisse doit être en **plein écran fenêtré** (cas de la grande majorité des logiciels de caisse). Si un logiciel utilise un plein écran exclusif (rare, type jeu vidéo), la bulle peut être masquée ; le raccourci `Ctrl + Alt + A` reste la solution, et on peut le changer dans `desktop_overlay.dart` si la caisse l'utilise déjà.

### 7. Déployer le serveur
```bash
cd functions && npm install && cd ..
firebase deploy --only firestore,functions
```

### 8. Créer les magasins et les comptes (console Firebase → Firestore)

**Magasin** — collection `stores`, document `gombe` :
```
name: "Supermarché Gombe"              (string)
location: [-4.3045° N, 15.3115° E]     (geopoint)  ← coordonnées du magasin
radiusM: 200                           (number)
```
Optionnel — liste de problèmes propre au magasin, champ `alertTypes` (array de maps) :
```
{ key: "suppression_article", fr: "Suppression d'article", en: "Delete item", icon: "remove_shopping_cart" }
```
Icônes disponibles : `remove_shopping_cart`, `receipt_long`, `exposure`, `badge`, `record_voice_over`, `undo`, `payments`, `build`, `shield`, `local_offer`, `help_outline`.

**Comptes** — Authentication → *Ajouter un utilisateur*, puis collection `users`, document = UID :

Caissier :
```
name: "Grâce"   role: "cashier"   storeId: "gombe"   register: "3"
```
Manager (peut travailler dans plusieurs magasins) :
```
name: "Honey"   role: "manager"   storeIds: ["gombe", "limete"]   lang: "fr"
```

### 9. Test
1. Higelin, Honey et Ceda se connectent sur leur téléphone et prennent leur service à Gombe. Patrick prend son service à Limete.
2. Ils verrouillent leur téléphone.
3. Sur la caisse 3 de Gombe : `Ctrl + Alt + A` → « Modification de quantité » → **ENVOYER**.
4. Higelin, Honey et Ceda sonnent ; Patrick non.
5. Honey appuie sur « J'arrive » : Higelin et Ceda arrêtent de sonner et lisent « Honey arrive » ; la bulle de la caisse devient verte avec « Honey ».
