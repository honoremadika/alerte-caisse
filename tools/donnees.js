/**
 * Crée / met à jour les magasins et les profils (lancé par GitHub Actions).
 * Les comptes (email + mot de passe) sont créés à la main dans Firebase Authentication ;
 * ce script ne fait que relier chaque email à son rôle et à son magasin.
 */
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

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
  const c = String(n).padStart(2, "0");
  return { id: `km${c}`, name: `KM ${c} · ${name}`, radiusM: 200 };
});
const ALL = STORES.map((s) => s.id);

// ---- Profils : modifier ici puis relancer le workflow « Données » ----
const PROFILS = [
  { email: "honey@gmail.com", name: "Honey", role: "manager", storeIds: ALL, lang: "fr" },
  { email: "meya@gmail.com", name: "Meya", role: "cashier", storeId: "km06", register: "1" },
];

(async () => {
  const batch = db.batch();
  for (const { id, ...data } of STORES) batch.set(db.collection("stores").doc(id), data, { merge: true });
  await batch.commit();
  console.log(`${STORES.length} magasins enregistrés.`);
  for (const { email, ...profil } of PROFILS) {
    try {
      const u = await getAuth().getUserByEmail(email);
      await db.collection("users").doc(u.uid).set(profil, { merge: true });
      console.log(`Profil OK : ${email} (${profil.role})`);
    } catch (e) {
      console.log(`::warning::${email} : compte introuvable dans Authentication (${e.code || e.message})`);
    }
  }
})().catch((e) => { console.error(`::error::${e.message}`); process.exit(1); });
