/**
 * Active la connexion « anonyme » de Firebase Authentication : l'app Windows
 * des caisses se connecte ainsi sans identifiant ni mot de passe (le poste
 * est ensuite validé par un manager). Lancé par la mise en ligne automatique.
 */
const { applicationDefault } = require("firebase-admin/app");

const project = process.env.PROJECT_ID || "alerte-caisse";

(async () => {
  const { access_token: token } = await applicationDefault().getAccessToken();
  const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config?updateMask=signIn.anonymous.enabled`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json", "x-goog-user-project": project },
    body: JSON.stringify({ signIn: { anonymous: { enabled: true } } }),
  });
  const body = await res.text();
  if (!res.ok) {
    console.log(`::warning::Connexion anonyme non activée (${res.status}). À faire une fois : console Firebase → Authentication → Méthode de connexion → Anonyme → Activer. ${body.slice(0, 300).replace(/\n/g, " ")}`);
    process.exit(0);
  }
  const anon = JSON.parse(body)?.signIn?.anonymous?.enabled;
  console.log(`Connexion anonyme : ${anon ? "activée" : "inconnue"}`);
})().catch((e) => { console.log(`::warning::Connexion anonyme : ${e.message}`); });
