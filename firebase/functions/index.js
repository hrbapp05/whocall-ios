"use strict";

const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {defineSecret} = require("firebase-functions/params");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {keyedDigest, normalizeName, normalizePhone} = require("./directory");

initializeApp();

const db = getFirestore();
const hmacKey = defineSecret("PHONE_DIRECTORY_HMAC_KEY");
const region = "europe-west1";
const callableOptions = {
  region,
  memory: "256MiB",
  timeoutSeconds: 10,
  minInstances: 0,
  secrets: [hmacKey],
};

function authenticatedPhone(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Telefon doğrulaması gerekli.");
  }
  const phone = normalizePhone(request.auth.token.phone_number);
  if (!phone) {
    throw new HttpsError("failed-precondition", "Doğrulanmış telefon numarası bulunamadı.");
  }
  return phone;
}

async function enforceRateLimit(uid, operation, limit, secret) {
  const documentID = keyedDigest(`${uid}:${operation}`, secret);
  const reference = db.collection("directoryRateLimits").doc(documentID);
  const now = Date.now();
  const windowMilliseconds = 60_000;

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const value = snapshot.data();
    const inWindow = value && now - value.windowStartMillis < windowMilliseconds;
    const count = inWindow ? Number(value.count || 0) : 0;
    if (count >= limit) {
      throw new HttpsError("resource-exhausted", "Çok fazla istek gönderildi.");
    }
    transaction.set(reference, {
      count: count + 1,
      windowStartMillis: inWindow ? value.windowStartMillis : now,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

exports.publishVerifiedProfile = onCall(callableOptions, async (request) => {
  const phone = authenticatedPhone(request);
  const firstName = normalizeName(request.data && request.data.firstName);
  const lastName = normalizeName(request.data && request.data.lastName);
  if (!firstName || !lastName) {
    throw new HttpsError("invalid-argument", "Geçerli ad ve soyadı zorunludur.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "publish", 5, secret);
  const phoneHmac = keyedDigest(phone, secret);
  const reference = db.collection("verifiedNumberProfiles").doc(`v1_${phoneHmac}`);
  const existing = await reference.get();
  if (existing.exists && existing.data().uid !== request.auth.uid) {
    throw new HttpsError("already-exists", "Bu numara başka bir hesaba bağlı.");
  }

  await reference.set({
    uid: request.auth.uid,
    phoneHmac,
    firstName,
    lastName,
    displayName: `${firstName} ${lastName}`,
    isVisible: true,
    verifiedAt: existing.exists ? existing.data().verifiedAt : FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    schemaVersion: 1,
  }, {merge: true});

  return {published: true};
});

exports.lookupVerifiedProfile = onCall(callableOptions, async (request) => {
  authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  if (!number) {
    throw new HttpsError("invalid-argument", "Geçerli bir Türkiye GSM numarası girin.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "lookup", 20, secret);
  const phoneHmac = keyedDigest(number, secret);
  const snapshot = await db.collection("verifiedNumberProfiles").doc(`v1_${phoneHmac}`).get();
  const profile = snapshot.data();
  if (!snapshot.exists || !profile.isVisible) return {found: false};

  return {
    found: true,
    owner: {
      phoneNumber: number,
      displayName: profile.displayName,
      firstName: profile.firstName,
      lastName: profile.lastName,
    },
  };
});

exports.unpublishVerifiedProfile = onCall(callableOptions, async (request) => {
  const phone = authenticatedPhone(request);
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "unpublish", 5, secret);
  const phoneHmac = keyedDigest(phone, secret);
  const reference = db.collection("verifiedNumberProfiles").doc(`v1_${phoneHmac}`);
  const snapshot = await reference.get();
  if (snapshot.exists && snapshot.data().uid === request.auth.uid) {
    await reference.set({
      isVisible: false,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  return {published: false};
});
