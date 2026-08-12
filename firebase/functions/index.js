"use strict";

const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
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
  if (!snapshot.exists) return {found: false, hidden: false};
  if (!profile.isVisible) return {found: false, hidden: true};

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

exports.setVerifiedProfileVisibility = onCall(callableOptions, async (request) => {
  const phone = authenticatedPhone(request);
  const isVisible = request.data && request.data.isVisible;
  if (typeof isVisible !== "boolean") {
    throw new HttpsError("invalid-argument", "Görünürlük değeri zorunludur.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "visibility", 10, secret);
  const phoneHmac = keyedDigest(phone, secret);
  const reference = db.collection("verifiedNumberProfiles").doc(`v1_${phoneHmac}`);
  const snapshot = await reference.get();
  if (!snapshot.exists || snapshot.data().uid !== request.auth.uid) {
    throw new HttpsError("not-found", "Yayınlanmış doğrulanmış profil bulunamadı.");
  }
  await reference.set({
    isVisible,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {published: isVisible};
});

function communityReference(number, secret) {
  return db.collection("numberCommunities").doc(`v1_${keyedDigest(number, secret)}`);
}

function cleanCommunityText(value, minLength, maxLength) {
  if (typeof value !== "string") return null;
  const clean = value.trim().replace(/\s+/g, " ").normalize("NFC");
  const length = Array.from(clean).length;
  return length >= minLength && length <= maxLength ? clean : null;
}

function relativeTime(createdAt) {
  const milliseconds = createdAt && typeof createdAt.toMillis === "function" ?
    Date.now() - createdAt.toMillis() : 0;
  const minutes = Math.max(0, Math.floor(milliseconds / 60_000));
  if (minutes < 1) return "Şimdi";
  if (minutes < 60) return `${minutes} dk`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} sa`;
  const days = Math.floor(hours / 24);
  return days === 1 ? "Dün" : `${days} gün`;
}

exports.getNumberCommunity = onCall(callableOptions, async (request) => {
  authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  if (!number) throw new HttpsError("invalid-argument", "Geçerli bir numara girin.");
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-read", 30, secret);
  const reference = communityReference(number, secret);
  const [community, comments] = await Promise.all([
    reference.get(),
    reference.collection("comments").orderBy("createdAt", "desc").limit(50).get(),
  ]);
  return {
    tags: community.data() && Array.isArray(community.data().tags) ? community.data().tags : [],
    comments: comments.docs.map((document) => ({
      id: document.id,
      author: document.data().author,
      body: document.data().body,
      time: relativeTime(document.data().createdAt),
    })),
  };
});

exports.addNumberComment = onCall(callableOptions, async (request) => {
  authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const body = cleanCommunityText(request.data && request.data.body, 2, 500);
  if (!number || !body) throw new HttpsError("invalid-argument", "Geçerli numara ve yorum zorunludur.");
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-comment", 8, secret);
  const user = await getAuth().getUser(request.auth.uid);
  const author = cleanCommunityText(user.displayName, 2, 80) || "WhoCall Kullanıcısı";
  const reference = communityReference(number, secret);
  await reference.collection("comments").add({
    uid: request.auth.uid,
    author,
    body,
    createdAt: FieldValue.serverTimestamp(),
  });
  await reference.set({updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  return {added: true};
});

exports.addNumberTag = onCall(callableOptions, async (request) => {
  authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const tag = cleanCommunityText(request.data && request.data.tag, 2, 24);
  if (!number || !tag || !/^[\p{L}\p{M}\d '&().\-]+$/u.test(tag)) {
    throw new HttpsError("invalid-argument", "Geçerli bir etiket girin.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-tag", 12, secret);
  const reference = communityReference(number, secret);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const tags = snapshot.exists && Array.isArray(snapshot.data().tags) ? snapshot.data().tags : [];
    if (!tags.some((value) => value.localeCompare(tag, "tr", {sensitivity: "base"}) === 0)) {
      if (tags.length >= 30) throw new HttpsError("resource-exhausted", "Etiket sınırına ulaşıldı.");
      tags.push(tag);
    }
    transaction.set(reference, {tags, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  });
  return {added: true};
});

exports.reportNumber = onCall(callableOptions, async (request) => {
  authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const reason = cleanCommunityText(request.data && request.data.reason, 2, 80);
  const allowedReasons = new Set([
    "Spam veya dolandırıcılık",
    "Taciz veya istenmeyen arama",
    "Yanlış kişi bilgisi",
    "Diğer",
  ]);
  if (!number || !reason || !allowedReasons.has(reason)) {
    throw new HttpsError("invalid-argument", "Geçerli bir rapor nedeni seçin.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-report", 8, secret);
  await communityReference(number, secret).collection("reports").add({
    uid: request.auth.uid,
    reason,
    createdAt: FieldValue.serverTimestamp(),
  });
  return {reported: true};
});
