/**
 * Crée les données de TEST dans Firebase : 2 magasins, 1 caissier, 4 managers.
 *
 * Utilisation (depuis le dossier du projet) :
 *   cd functions && npm install && cd ..
 *   node tools/seed.js chemin/vers/cle-service.json
 *
 * La clé se télécharge dans la console Firebase :
 *   Paramètres du projet → Comptes de service → Générer une nouvelle clé privée.
 * Ne partage jamais ce fichier et ne le mets pas dans le dossier du projet.
 */
const path = require("path");
const fnModules = path.join(__dirname, "..", "functions", "node_modules");
const { initializeApp, cert } = require(path.join(fnModules, "firebase-admin/app"));
const { getAuth } = require(path.join(fnModules, "firebase-admin/auth"));
const { getFirestore } = require(path.join(fnModules, "firebase-admin/firestore"));

const keyPath = process.argv[2];
if (!keyPath) {
  console.error("Usage : node tools/seed.js chemin/vers/cle-service.json");
  process.exit(1);
}
initializeApp({ credential: cert(require(path.resolve(keyPath))) });
const auth = getAuth();
const db = getFirestore();

const PASSWORD = "Test1234!";

// Pas de champ `location` : la vérification des 200 m est désactivée
// pendant les tests. Ajoute-le plus tard (geopoint) dans la console.
// Les 40 magasins : code + nom.
const STORES = [
  [1, "Gombe"], [3, "Kabambare"], [4, "Bandalungwa"], [5, "Ngaliema"], [6, "Limete"], [7, "Kitambo"],
  [8, "Victoire"], [9, "Ozone"], [10, "Masina"], [11, "Matadi"], [13, "Triangle"], [14, "Lemba"],
  [15, "City Moderne"], [16, "Boulevard"], [17, "Mimosa"], [18, "Kapela"], [20, "Cell Point"],
  [21, "Bon Marché"], [22, "Boma"], [23, "Kingasani"], [24, "Tata Raphel"], [28, "Bibwa"],
  [29, "Debonhomme"], [32, "Righini"], [35, "Mont-Ngafula"], [36, "Selembao"], [39, "La Promenade"],
  [40, "Matate"], [45, "Coca Matadi"], [46, "Kasa Vubu"], [48, "Pompage"], [67, "Lingwala"],
  [68, "Kim Pese"], [70, "Super Lemba"], [74, "Aqua Splash"], [75, "Kabambare"], [76, "Mariano"],
  [77, "Entrée Plaza"], [78, "Terre Jaune"], [81, "UPN"],
].map(([n, name]) => {
  const code = String(n).padStart(2, "0");
  return { id: `km${code}`, name: `KM ${code} · ${name}`, radiusM: 200 };
});

const USERS = [
  { email: "caisse3@test.com", name: "Grâce", role: "cashier", storeId: "km01", register: "3" },
  { email: "honey@test.com", name: "Honey", role: "manager", storeIds: ["km01", "km06"], lang: "fr" },
  { email: "higelin@test.com", name: "Higelin", role: "manager", storeIds: ["km01"], lang: "fr" },
  { email: "ceda@test.com", name: "Ceda", role: "manager", storeIds: ["km01"], lang: "en" },
  { email: "patrick@test.com", name: "Patrick", role: "manager", storeIds: ["km06"], lang: "fr" },
];

async function main() {
  for (const s of STORES) {
    const { id, ...data } = s;
    await db.collection("stores").doc(id).set(data, { merge: true });
    console.log(`Magasin ${s.name}`);
  }
  for (const u of USERS) {
    let user;
    try {
      user = await auth.getUserByEmail(u.email);
    } catch {
      user = await auth.createUser({ email: u.email, password: PASSWORD, displayName: u.name });
    }
    const { email, ...profile } = u;
    await db.collection("users").doc(user.uid).set(profile, { merge: true });
    console.log(`${u.role === "cashier" ? "Caissier" : "Manager "}  ${u.email}`);
  }
  console.log(`\nMot de passe de tous les comptes : ${PASSWORD}`);
}

main().then(() => process.exit(0)).catch((e) => {
  console.error(e.message);
  process.exit(1);
});
