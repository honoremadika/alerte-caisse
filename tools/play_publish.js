/**
 * Envoie la nouvelle version au Play Store (canal « Test interne ») et met à jour
 * la fiche (textes, icône, image de présentation). Lancé par la mise en ligne automatique.
 *
 *   node tools/play_publish.js out/AlerteManager-PlayStore.aab
 *
 * Le compte technique du projet (clé FIREBASE_SERVICE_ACCOUNT) doit être invité dans la
 * Play Console (Utilisateurs et autorisations) avec les droits « canaux de test » et
 * « présence sur le Play Store » pour cette app.
 */
const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PKG = "tech.geniuslabs.alerte_caisse";
const PROJECT = process.env.PROJECT_ID || "alerte-caisse";
const API = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PKG}`;
const UP = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PKG}`;
const ROOT = path.resolve(__dirname, "..");
const one = (s) => String(s).replace(/\s+/g, " ").slice(0, 600);

const LISTING = {
  language: "fr-FR",
  title: "Alerte Manager",
  shortDescription: "La caisse appelle, votre téléphone sonne. Alertes caisse en temps réel.",
  fullDescription: [
    "Alerte Manager relie les caisses d'un magasin aux téléphones des managers.",
    "",
    "Quand un caissier a besoin d'aide (suppression d'article, annulation de facture, modification de quantité, recherche F1, authentification, réclamation client, remboursement, monnaie…), il envoie une alerte depuis l'ordinateur de la caisse. Le téléphone de chaque manager en service dans ce magasin sonne aussitôt, même écran verrouillé.",
    "",
    "Le premier manager qui appuie sur « J'arrive » arrête la sonnerie des autres, et le caissier voit qui vient. L'alerte est relancée chaque minute tant que personne ne répond.",
    "",
    "• Prise de service par magasin : seuls les managers du bon magasin sont appelés",
    "• Fin de service automatique après 12 heures",
    "• Historique des alertes du magasin",
    "• Choix de la sonnerie",
    "• Français et anglais",
    "",
    "Réservée au personnel : les comptes sont créés par l'administrateur du magasin. Fonctionne avec l'app Alerte Caisse installée sur les ordinateurs des caisses.",
  ].join("\n"),
};

async function main() {
  const aab = process.argv[2];
  if (!aab || !fs.existsSync(aab)) throw new Error(`Fichier .aab introuvable : ${aab}`);

  const auth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher", "https://www.googleapis.com/auth/cloud-platform"],
  });
  const client = await auth.getClient();
  const token = async () => (await client.getAccessToken()).token;
  const call = async (method, url, body, type) => {
    const res = await fetch(url, {
      method,
      headers: { Authorization: `Bearer ${await token()}`, ...(body ? { "Content-Type": type || "application/json" } : {}) },
      body: body ? (type ? body : JSON.stringify(body)) : undefined,
    });
    const text = await res.text();
    let json = {};
    try { json = JSON.parse(text); } catch (e) { /* pas du JSON */ }
    if (!res.ok) {
      const err = new Error(`${res.status} ${one(json.error?.message || text)}`);
      err.status = res.status;
      throw err;
    }
    return json;
  };

  // 1. L'API Google Play doit être activée dans le projet (une seule fois).
  try {
    await call("POST", `https://serviceusage.googleapis.com/v1/projects/${PROJECT}/services/androidpublisher.googleapis.com:enable`, {});
    await new Promise((r) => setTimeout(r, 20000));
  } catch (e) {
    console.log(`::warning::Activation de l'API Google Play : ${e.message}`);
  }

  // 2. Nouvelle « modification » : fichier de l'app + fiche + canal de test interne.
  const edit = await call("POST", `${API}/edits`, {});
  const E = `${API}/edits/${edit.id}`;

  const bundle = await call("POST", `${UP}/edits/${edit.id}/bundles?uploadType=media`, fs.readFileSync(aab), "application/octet-stream");
  console.log(`Fichier envoyé : version n° ${bundle.versionCode}`);

  try {
    await call("PUT", `${E}/listings/${LISTING.language}`, LISTING);
    const images = { icon: "docs/play-store/icone-512.png", featureGraphic: "docs/play-store/image-presentation-1024x500.png" };
    for (const [type, file] of Object.entries(images)) {
      await call("DELETE", `${E}/listings/${LISTING.language}/${type}`).catch(() => {});
      await call("POST", `${UP}/edits/${edit.id}/listings/${LISTING.language}/${type}?uploadType=media`, fs.readFileSync(path.join(ROOT, file)), "image/png");
    }
    // Captures d'écran du téléphone (docs/play-store/captures/*.png), si elles existent.
    const dir = path.join(ROOT, "docs/play-store/captures");
    const shots = fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => /\.(png|jpe?g)$/i.test(f)).sort() : [];
    if (shots.length >= 2) {
      await call("DELETE", `${E}/listings/${LISTING.language}/phoneScreenshots`).catch(() => {});
      for (const f of shots.slice(0, 8)) {
        await call("POST", `${UP}/edits/${edit.id}/listings/${LISTING.language}/phoneScreenshots?uploadType=media`, fs.readFileSync(path.join(dir, f)), /png$/i.test(f) ? "image/png" : "image/jpeg");
      }
    }
    await call("PATCH", `${E}/details`, { contactEmail: process.env.CONTACT_EMAIL || undefined, defaultLanguage: LISTING.language });
    console.log(`Fiche Play Store mise à jour (${shots.length >= 2 ? shots.length + " captures" : "sans captures d'écran"}).`);
  } catch (e) {
    console.log(`::warning::Fiche Play Store non mise à jour : ${e.message}`);
  }

  const notes = [{ language: "fr-FR", text: "Corrections et améliorations." }];
  const release = (status) => ({ track: "internal", releases: [{ name: process.env.VERSION_NAME || String(bundle.versionCode), versionCodes: [String(bundle.versionCode)], status, releaseNotes: notes }] });

  // Tant que l'app n'a jamais été publiée, Google n'accepte par l'API que des versions « brouillon ».
  let status = "completed";
  await call("PUT", `${E}/tracks/internal`, release(status));
  try {
    await call("POST", `${E}:commit`);
  } catch (e) {
    if (!/draft/i.test(e.message)) throw e;
    status = "draft";
    await call("PUT", `${E}/tracks/internal`, release(status));
    await call("POST", `${E}:commit`);
  }
  const msg = status === "completed"
    ? `Play Store : version n° ${bundle.versionCode} publiée dans le test interne.`
    : `Play Store : version n° ${bundle.versionCode} envoyée en brouillon dans le test interne (à lancer une fois dans la Play Console).`;
  console.log(`::notice::${msg}`);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, msg + "\n");
}

main().catch((e) => {
  console.log(`::error::Envoi au Play Store impossible : ${one(e.message)}`);
  process.exit(1);
});
