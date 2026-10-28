/**
 * Alerte Caisse — serveur.
 *  1. notifierManagers : nouvelle alerte -> fait sonner TOUS les managers
 *     en service dans CE magasin (et seulement eux).
 *  2. suiviAlerte      : quand quelqu'un appuie sur « J'arrive », la sonnerie
 *     s'arrête sur les autres téléphones avec « Honey arrive ».
 *  3. relancerAlertes  : sans réponse, relance chaque minute (5 fois max).
 *  4. finDeService     : remet « hors service » les services expirés.
 */
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

const REGION = "europe-west1";
const MAX_RELANCES = 5;

// iPhone : passez à true UNIQUEMENT après avoir obtenu d'Apple le droit
// « Critical Alerts » (sonne même en mode silencieux).
const IOS_CRITICAL = false;

const TXT = {
  fr: {
    alertTitle: (reg, relance) => `🚨 ${relance ? `RELANCE ${relance} · ` : ""}Caisse ${reg}`,
    comingTitle: (name, reg) => `${name} arrive · Caisse ${reg}`,
    comingBody: "Alerte prise en charge, la sonnerie est arrêtée.",
    cancelledTitle: (reg) => `Caisse ${reg} : alerte annulée`,
    cancelledBody: "Le caissier a annulé l'alerte.",
  },
  en: {
    alertTitle: (reg, relance) => `🚨 ${relance ? `REMINDER ${relance} · ` : ""}Till ${reg}`,
    comingTitle: (name, reg) => `${name} is on the way · Till ${reg}`,
    comingBody: "Alert taken, ringing stopped.",
    cancelledTitle: (reg) => `Till ${reg}: alert cancelled`,
    cancelledBody: "The cashier cancelled the alert.",
  },
};
const langOf = (u) => (u.lang === "en" ? "en" : "fr");

/** Managers en service dans le magasin, avec leurs téléphones. */
async function managersEnService(storeId) {
  const snap = await db
    .collection("users")
    .where("role", "==", "manager")
    .where("onDuty", "==", true)
    .where("dutyStoreId", "==", storeId)
    .get();
  const now = Date.now();
  return snap.docs
    .map((d) => ({ uid: d.id, ...d.data() }))
    .filter((u) => (u.dutyUntil?.toMillis?.() || 0) > now);
}

/** Envoie un message à une liste de managers, groupés par langue. */
async function envoyer(managers, build) {
  for (const lang of ["fr", "en"]) {
    const group = managers.filter((m) => langOf(m) === lang);
    const targets = group.flatMap((m) => (m.fcmTokens || []).map((t) => ({ token: t, uid: m.uid })));
    if (!targets.length) continue;

    const res = await getMessaging().sendEachForMulticast({
      tokens: targets.map((t) => t.token),
      ...build(TXT[lang]),
    });

    // Nettoyage des jetons morts (app désinstallée…).
    await Promise.all(
      res.responses.map((r, i) => {
        const code = r.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          return db.collection("users").doc(targets[i].uid).update({
            fcmTokens: FieldValue.arrayRemove(targets[i].token),
          });
        }
        return null;
      })
    );
    logger.info(`[${lang}] ${res.successCount} envoyé(s), ${res.failureCount} échec(s).`);
  }
}

/** Message « ça sonne ». */
function messageAlerte(alertId, a, relance) {
  return (t) => {
    const title = t.alertTitle(a.register, relance);
    const label = t === TXT.en ? a.typeEn || a.typeFr : a.typeFr;
    const body = `${label} — ${a.cashierName}` + (a.message ? ` : ${a.message}` : "");
    return {
      data: { action: "alert", alertId, title, body },
      android: { priority: "high", ttl: 5 * 60 * 1000 },
      apns: {
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
          // même identifiant : l'iPhone remplacera cette notification
          // par « Honey arrive » au lieu d'en empiler une deuxième
          "apns-collapse-id": alertId,
        },
        payload: {
          aps: {
            alert: { title, body },
            "interruption-level": IOS_CRITICAL ? "critical" : "time-sensitive",
            sound: IOS_CRITICAL ? { critical: 1, name: "alarme.wav", volume: 1.0 } : "alarme.wav",
          },
        },
      },
    };
  };
}

/** Message « arrêtez de sonner » (silencieux). */
function messageStop(alertId, title, body) {
  return (t) => {
    const ti = title(t);
    const bo = body(t);
    return {
      data: { action: "stop", alertId, title: ti, body: bo },
      android: { priority: "high" },
      apns: {
        headers: { "apns-priority": "10", "apns-push-type": "alert", "apns-collapse-id": alertId },
        payload: { aps: { alert: { title: ti, body: bo }, "interruption-level": "passive" } },
      },
    };
  };
}

exports.notifierManagers = onDocumentCreated(
  { document: "alerts/{alertId}", region: REGION },
  async (event) => {
    const a = event.data?.data();
    if (!a || !a.storeId) return;
    const managers = await managersEnService(a.storeId);
    if (!managers.length) logger.warn(`Aucun manager en service au magasin ${a.storeId}.`);
    await envoyer(managers, messageAlerte(event.params.alertId, a, 0));
    await event.data.ref.update({ lastNotifiedAt: FieldValue.serverTimestamp(), relances: 0 });
  }
);

exports.suiviAlerte = onDocumentUpdated(
  { document: "alerts/{alertId}", region: REGION },
  async (event) => {
    const avant = event.data.before.data();
    const apres = event.data.after.data();
    if (avant.status === apres.status) return;
    const id = event.params.alertId;
    const managers = await managersEnService(apres.storeId);

    if (avant.status === "open" && apres.status === "taken") {
      // Tous les autres téléphones arrêtent de sonner et voient qui arrive.
      const autres = managers.filter((m) => m.uid !== apres.takenBy);
      await envoyer(
        autres,
        messageStop(id, (t) => t.comingTitle(apres.takenByName, apres.register), (t) => t.comingBody)
      );
    } else if (avant.status === "open" && apres.status === "cancelled") {
      await envoyer(
        managers,
        messageStop(id, (t) => t.cancelledTitle(apres.register), (t) => t.cancelledBody)
      );
    }
  }
);

exports.relancerAlertes = onSchedule(
  { schedule: "every 1 minutes", region: REGION },
  async () => {
    const ilYaUneMinute = Timestamp.fromMillis(Date.now() - 60 * 1000);
    const snap = await db
      .collection("alerts")
      .where("status", "==", "open")
      .where("createdAt", "<=", ilYaUneMinute)
      .get();

    for (const doc of snap.docs) {
      const a = doc.data();
      const relances = a.relances || 0;
      const last = a.lastNotifiedAt?.toMillis?.() || 0;
      if (relances >= MAX_RELANCES || Date.now() - last < 55 * 1000) continue;
      const managers = await managersEnService(a.storeId);
      await envoyer(managers, messageAlerte(doc.id, a, relances + 1));
      await doc.ref.update({ relances: relances + 1, lastNotifiedAt: FieldValue.serverTimestamp() });
    }
  }
);

exports.finDeService = onSchedule(
  { schedule: "every 15 minutes", region: REGION },
  async () => {
    const snap = await db
      .collection("users")
      .where("onDuty", "==", true)
      .where("dutyUntil", "<=", Timestamp.now())
      .get();
    await Promise.all(snap.docs.map((d) => d.ref.update({ onDuty: false })));
    if (snap.size) logger.info(`${snap.size} service(s) terminé(s) automatiquement.`);
  }
);
