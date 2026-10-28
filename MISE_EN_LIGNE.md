# Mettre Alerte Caisse en ligne — version gratuite (Android + Windows)

Résultat : une page **https://TON-PROJET.web.app** où l'on télécharge
- l'**App Manager** pour Android (`.apk`) ;
- l'**App Caisse** pour Windows (`.zip`).

**Coût : 0 $.**
- Firebase reste sur le forfait gratuit **Spark** : pas de carte bancaire.
- GitHub compile gratuitement : 2 000 minutes par mois sur un dépôt privé, soit environ 50 mises à jour.

Toi, tu crées les deux comptes et tu envoies le projet sur GitHub. Ensuite, à chaque modification, GitHub recompile tout seul et republie la page (environ 12 minutes).

### Ce qui change avec la version gratuite
Le forfait gratuit ne permet pas d'avoir un serveur qui envoie les notifications. C'est donc **le téléphone du manager qui reste à l'écoute** pendant son service : une notification **« En service · KM 06 · Limete »** reste affichée tant qu'il est en service. Grâce à elle, le téléphone sonne même écran verrouillé, arrête de sonner quand un collègue répond, et relance chaque minute.
- Après « Terminer mon service » (ou au bout de 12 h), la notification disparaît et le téléphone ne reçoit plus rien.
- La batterie est un peu plus sollicitée pendant le service. C'est normal.

---

## 1. Firebase — https://console.firebase.google.com (gratuit)

1. **Ajouter un projet** → nom `alerte-caisse`. Désactive Google Analytics (inutile). Note l'**identifiant du projet** affiché sous le nom (ex. `alerte-caisse-4f2a1`).
2. **Build → Authentication** → Commencer → activer **E-mail/Mot de passe**.
3. **Build → Firestore Database** → Créer → région `europe-west1` → mode production.
4. **Build → Hosting** → Commencer → « Suivant » jusqu'au bout (les commandes affichées ne sont pas nécessaires).

Ne passe **pas** au forfait Blaze : tout fonctionne sur le forfait gratuit.

## 2. La clé qui permet à GitHub de publier

1. Firebase → ⚙️ **Paramètres du projet → Comptes de service → Générer une nouvelle clé privée**. Un fichier `.json` se télécharge. Ne le partage avec personne.
2. Ouvre https://console.cloud.google.com/iam-admin/iam (choisis ton projet en haut).
3. Sur la ligne **firebase-adminsdk-…**, clique le crayon ✏️ → **Ajouter un autre rôle**, et ajoute :
   - **Administrateur Firebase** (Firebase Admin)
   - **Éditeur** (Editor)
4. Enregistre.

## 3. GitHub — https://github.com (gratuit)

1. Crée un compte si besoin, puis **New repository** → nom `alerte-caisse` → **Private** → Create.
2. Sur ton Mac, dans le Terminal, depuis le dossier dézippé du projet :
   ```bash
   cd ~/Projets/alerte_caisse
   git init -b main
   git add .
   git commit -m "Alerte Caisse"
   git remote add origin https://github.com/TON-NOM/alerte-caisse.git
   git push -u origin main
   ```
   GitHub demande un mot de passe : utilise un **jeton** créé sur https://github.com/settings/tokens (*Generate new token (classic)*, coche `repo` et `workflow`).

   > N'envoie pas le dossier par glisser-déposer sur le site : le dossier caché `.github` (qui contient la compilation automatique) ne serait pas envoyé.

3. Dans le dépôt : **Settings → Secrets and variables → Actions**
   - onglet **Secrets** → *New repository secret* → nom `FIREBASE_SERVICE_ACCOUNT` → colle **tout le contenu** du fichier `.json`.
   - onglet **Variables** → *New repository variable* → nom `FIREBASE_PROJECT_ID` → l'identifiant du projet.

## 4. Lancer la mise en ligne

Onglet **Actions** du dépôt → **Mise en ligne** → **Run workflow**.

| Étape | Durée |
|---|---|
| Serveur Firebase (règles) | ~1 min |
| App Manager · Android | ~8 min |
| App Caisse · Windows | ~10 min |
| Page de téléchargement | ~1 min |

Quand tout est vert ✓, la page est en ligne : **https://TON-PROJET.web.app** (le lien est aussi dans le résumé de l'exécution).

Si une étape est rouge ✗ : clique dessus, copie les dernières lignes rouges et envoie-les-moi.

## 5. Créer les magasins et les comptes

Depuis le Mac (Node.js installé), une seule fois :
```bash
cd ~/Projets/alerte_caisse/functions && npm install && cd ..
node tools/seed.js ~/chemin/vers/la-cle.json
```
Ça crée les **40 magasins** (KM 01 · Gombe … KM 81 · UPN) et des comptes de test (`…@test.com`, mot de passe `Test1234!`).

Pour les vrais comptes : Firebase → **Authentication → Ajouter un utilisateur** (email + mot de passe), puis **Firestore → collection `users`** → document dont l'ID est l'UID de la personne :
- Caissier : `name` « Grâce », `role` `cashier`, `storeId` `km06`, `register` `1`
- Manager : `name` « Honey », `role` `manager`, `storeIds` tableau `["km06", "km14"]`, `lang` `fr`

## 6. Installer

- **Android** : ouvrir la page sur le téléphone, « Télécharger pour Android », autoriser l'installation. Dans l'app : se connecter, accepter les notifications, **accepter « Ignorer l'optimisation de la batterie »**, puis « Prendre mon service ».
- **Windows** : télécharger le `.zip`, extraire, lancer `alerte_caisse.exe`. Au premier lancement : « Windows a protégé votre ordinateur » → *Informations complémentaires → Exécuter quand même*.

## Limites du forfait gratuit
- **Hébergement** : 360 Mo de téléchargements par jour, soit environ 10 installations par jour. C'est largement assez pour équiper les magasins petit à petit.
- **Base de données** : 50 000 lectures et 20 000 écritures par jour, ce qui suffit pour des centaines d'alertes par jour.
- **Pas de notification si l'app Manager est arrêtée de force** dans les paramètres d'Android : il faut alors rouvrir l'app.
