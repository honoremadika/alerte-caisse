/**
 * Met à jour la fiche Play Store (textes, icône, image de présentation, captures),
 * morceau par morceau, pour savoir précisément ce que Google accepte ou refuse.
 *   node tools/play_fiche.js
 */
const fs = require("fs");
const path = require("path");
const { GoogleAuth } = require("google-auth-library");

const PKG = "tech.geniuslabs.alerte_caisse";
const API = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PKG}`;
const UP = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PKG}`;
const ROOT = path.resolve(__dirname, "..");
const one = (s) => String(s).replace(/\s+/g, " ").slice(0, 500);
const LANG = "fr-FR";
const src = fs.readFileSync(path.join(__dirname, "play_publish.js"), "utf8");
const LISTING = eval("(" + src.slice(src.indexOf("const LISTING = ") + 16, src.indexOf("};", src.indexOf("const LISTING = ")) + 1) + ")");

(async () => {
  const client = await new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/androidpublisher"] }).getClient();
  const call = async (method, url, body, type) => {
    const res = await fetch(url, {
      method,
      headers: { Authorization: `Bearer ${(await client.getAccessToken()).token}`, ...(body ? { "Content-Type": type || "application/json" } : {}) },
      body: body ? (type ? body : JSON.stringify(body)) : undefined,
    });
    const text = await res.text();
    let json = {};
    try { json = JSON.parse(text); } catch (e) { /* pas du JSON */ }
    if (!res.ok) throw new Error(`${res.status} ${one(json.error?.message || text)}`);
    return json;
  };
  // Chaque morceau a sa propre « modification » : un refus n'empêche pas les autres.
  const part = async (label, fn) => {
    try {
      const ed = await call("POST", `${API}/edits`, {});
      await fn(ed.id);
      await call("POST", `${API}/edits/${ed.id}:commit`);
      console.log(`::notice::Fiche · ${label} : mis à jour`);
      return true;
    } catch (e) {
      console.log(`::warning::Fiche · ${label} : refusé (${one(e.message)})`);
      return false;
    }
  };
  let ok = 0;
  ok += await part("textes (titre, descriptions)", (id) => call("PUT", `${API}/edits/${id}/listings/${LANG}`, LISTING));
  const images = { icon: "docs/play-store/icone-512.png", featureGraphic: "docs/play-store/image-presentation-1024x500.png" };
  for (const [type, file] of Object.entries(images)) {
    ok += await part(type === "icon" ? "icône" : "image de présentation", async (id) => {
      await call("DELETE", `${API}/edits/${id}/listings/${LANG}/${type}`).catch(() => {});
      await call("POST", `${UP}/edits/${id}/listings/${LANG}/${type}?uploadType=media`, fs.readFileSync(path.join(ROOT, file)), "image/png");
    });
  }
  if (process.env.CONTACT_EMAIL) {
    ok += await part("adresse de contact", (id) => call("PATCH", `${API}/edits/${id}/details`, { contactEmail: process.env.CONTACT_EMAIL, defaultLanguage: LANG }));
  }
  if (!ok) process.exit(1);
})().catch((e) => { console.log(`::error::Fiche Play Store : ${one(e.message)}`); process.exit(1); });
