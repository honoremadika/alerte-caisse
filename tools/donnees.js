/**
 * Crée / met à jour les magasins et les profils (lancé par GitHub Actions).
 * Les comptes (email + mot de passe) sont créés à la main dans Firebase Authentication ;
 * ce script ne fait que relier chaque email à son rôle et à son magasin.
 */
const crypto = require("crypto");
const { initializeApp, applicationDefault } = require("firebase-admin/app");
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
// id = identifiant tapé à la connexion (minuscules, sans espace).
const PROFILS = [
  { id: "honey", email: "honey@gmail.com", name: "Honey", role: "manager", storeIds: ALL, lang: "fr" },
  { id: "meya", email: "meya@gmail.com", name: "Meya", role: "cashier", storeId: "km06", register: "1" },
];

// Code de poste caisse : « KM06-7F3K9P » (sans 0/O ni 1/I pour éviter les confusions).
const ALPHA = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const newCode = (storeId) =>
  storeId.toUpperCase() + "-" + Array.from(crypto.randomBytes(6), (b) => ALPHA[b % ALPHA.length]).join("");

async function stationCodes() {
  let created = 0;
  for (const s of STORES) {
    const ref = db.collection("storeCodes").doc(s.id);
    const snap = await ref.get();
    if (snap.exists && snap.data().code) continue; // un code ne change pas tout seul
    const code = newCode(s.id);
    const b = db.batch();
    b.set(ref, { code, createdAt: new Date() });
    b.set(db.collection("stationCodes").doc(code), { storeId: s.id });
    await b.commit();
    created++;
  }
  console.log(`Codes des postes caisse : ${created} créé(s), visibles par les managers dans l'app (Réglages).`);
}

// Active la connexion sans compte (anonyme) utilisée par les PC des caisses.
async function enableAnonymous() {
  const project = process.env.GOOGLE_CLOUD_PROJECT || "alerte-caisse";
  const { access_token } = await applicationDefault().getAccessToken();
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config?updateMask=signIn.anonymous.enabled`,
    { method: "PATCH", headers: { Authorization: `Bearer ${access_token}`, "Content-Type": "application/json", "X-Goog-User-Project": project },
      body: JSON.stringify({ signIn: { anonymous: { enabled: true } } }) });
  if (res.ok) console.log("Connexion des postes caisse (anonyme) : activée.");
  else console.log(`::warning::Connexion anonyme non activée (${res.status}) : Firebase Console → Authentication → Méthodes de connexion → Anonyme → Activer. ${(await res.text()).slice(0, 300)}`);
}

(async () => {
  await enableAnonymous();
  const batch = db.batch();
  for (const { id, ...data } of STORES) batch.set(db.collection("stores").doc(id), data, { merge: true });
  await batch.commit();
  console.log(`${STORES.length} magasins enregistrés.`);
  for (const { id, email, ...profil } of PROFILS) {
    try {
      const u = await getAuth().getUserByEmail(email);
      await db.collection("users").doc(u.uid).set({ ...profil, loginId: id }, { merge: true });
      await db.collection("logins").doc(id).set({ email });
      console.log(`Profil OK : ${id} -> ${email} (${profil.role})`);
    } catch (e) {
      console.log(`::warning::${email} : compte introuvable dans Authentication (${e.code || e.message})`);
    }
  }
  await stationCodes();
})().catch((e) => { console.error(`::error::${e.message}`); process.exit(1); });
