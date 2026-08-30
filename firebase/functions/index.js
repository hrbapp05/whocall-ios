"use strict";

const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");
const {defineSecret} = require("firebase-functions/params");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {createAdminService, isPremiumActive} = require("./admin");
const {
  communityAuthor,
  containsBlockedCommunityLanguage,
  keyedDigest,
  namesFromDisplayName,
  normalizeCommunityContentType,
  normalizeCommunityModerationReason,
  normalizeLegalAcceptance,
  maskedPhone,
  normalizeName,
  normalizePhone,
  publicProfileFromAuthUser,
} = require("./directory");

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
const accountDeletionOptions = {...callableOptions, timeoutSeconds: 60};
const adminOptions = {...callableOptions, timeoutSeconds: 60, memory: "512MiB"};

async function authenticatedPhone(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Telefon doğrulaması gerekli.");
  }

  // A freshly linked phone credential can briefly be ahead of the cached ID
  // token used by callable Functions. Prefer its claim, then safely resolve the
  // same authenticated UID through Firebase Auth before rejecting the request.
  let phone = normalizePhone(request.auth.token.phone_number);
  if (!phone) {
    try {
      const user = await getAuth().getUser(request.auth.uid);
      phone = normalizePhone(user.phoneNumber);
    } catch (_error) {
      throw new HttpsError("unauthenticated", "Oturum doğrulanamadı.");
    }
  }
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
  const phone = await authenticatedPhone(request);
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
  const sameOwner = existing.exists && existing.data().uid === request.auth.uid;

  await reference.set({
    uid: request.auth.uid,
    phoneHmac,
    firstName,
    lastName,
    displayName: `${firstName} ${lastName}`,
    isVisible: sameOwner ? existing.data().isVisible !== false : true,
    verifiedAt: sameOwner ? existing.data().verifiedAt : FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    schemaVersion: 1,
    deletedAt: FieldValue.delete(),
  }, {merge: true});

  return {published: true};
});

exports.lookupVerifiedProfile = onCall(callableOptions, async (request) => {
  await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  if (!number) {
    throw new HttpsError("invalid-argument", "Geçerli bir Türkiye GSM numarası girin.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "lookup", 20, secret);
  const phoneHmac = keyedDigest(number, secret);
  const documentID = `v1_${phoneHmac}`;
  const [snapshot, exclusion] = await Promise.all([
    db.collection("verifiedNumberProfiles").doc(documentID).get(),
    db.collection("adminExcludedNumbers").doc(documentID).get(),
  ]);
  if (exclusion.exists && exclusion.data().active === true) {
    return {found: false, hidden: false, suppressed: true};
  }
  const profile = snapshot.data();
  if (!snapshot.exists) {
    try {
      const user = await getAuth().getUserByPhoneNumber(`+${number}`);
      const owner = publicProfileFromAuthUser(user, number);
      return owner ? {found: true, owner} : {found: false, hidden: false};
    } catch (error) {
      if (error && error.code === "auth/user-not-found") {
        return {found: false, hidden: false};
      }
      throw new HttpsError("internal", "Doğrulanmış profil okunamadı.");
    }
  }
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

exports.getAccountAccessState = onCall(callableOptions, async (request) => {
  const phone = await authenticatedPhone(request);
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "account-access-read", 30, secret);
  const reference = db.collection("accountBenefits")
      .doc(`v1_${keyedDigest(phone, secret)}`);
  const configurationReference = db.collection("appConfiguration").doc("public");
  const data = await db.runTransaction(async (transaction) => {
    const [snapshot, configuration] = await transaction.getAll(reference, configurationReference);
    const current = snapshot.data() || {};
    const configuredAmount = Number(configuration.data() && configuration.data().signupCreditAmount);
    const signupCreditAmount = Number.isSafeInteger(configuredAmount) &&
      configuredAmount >= 0 && configuredAmount <= 100 ? configuredAmount : 1;
    const showPostLoginPaywall = configuration.data() &&
      typeof configuration.data().showPostLoginPaywall === "boolean" ?
      configuration.data().showPostLoginPaywall : true;
    if (current.welcomeCreditGranted === true) {
      return {...current, showPostLoginPaywall};
    }
    const promotionalCreditBalance = Math.max(
        0,
        Number(current.promotionalCreditBalance || 0),
    ) + signupCreditAmount;
    transaction.set(reference, {
      phoneMasked: `+90 5** *** ** ${phone.slice(-2)}`,
      promotionalCreditBalance,
      welcomeCreditGranted: true,
      welcomeCreditAmount: signupCreditAmount,
      welcomeCreditGrantedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return {...current, promotionalCreditBalance, showPostLoginPaywall};
  });
  return {
    promotionalPremiumActive: isPremiumActive(data),
    promotionalPremiumExpiresAt: data.promotionalPremiumExpiresAt &&
      typeof data.promotionalPremiumExpiresAt.toDate === "function" ?
      data.promotionalPremiumExpiresAt.toDate().toISOString() : null,
    promotionalCreditBalance: Math.max(0, Number(data.promotionalCreditBalance || 0)),
    showPostLoginPaywall: data.showPostLoginPaywall !== false,
  };
});

// App Store consumable credits are maintained by the signed-in iOS account.
// This snapshot is for admin reporting only: access checks and deductions never
// trust these client-reported fields.
exports.syncPurchaseSnapshot = onCall(callableOptions, async (request) => {
  const phone = await authenticatedPhone(request);
  const purchasedCreditBalance = Number(
      request.data && request.data.purchasedCreditBalance,
  );
  const revenueCatPremiumActive = request.data && request.data.revenueCatPremiumActive;
  if (!Number.isSafeInteger(purchasedCreditBalance) ||
      purchasedCreditBalance < 0 || purchasedCreditBalance > 100_000 ||
      typeof revenueCatPremiumActive !== "boolean") {
    throw new HttpsError("invalid-argument", "Geçerli satın alma özeti zorunludur.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "purchase-snapshot-sync", 60, secret);
  const reference = db.collection("accountBenefits")
      .doc(`v1_${keyedDigest(phone, secret)}`);
  await reference.set({
    revenueCatAppUserID: request.auth.uid,
    reportedPurchasedCreditBalance: purchasedCreditBalance,
    reportedRevenueCatPremiumActive: revenueCatPremiumActive,
    purchaseSnapshotUpdatedAt: FieldValue.serverTimestamp(),
    phoneMasked: maskedPhone(phone),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {synchronized: true};
});

exports.registerPushToken = onCall(callableOptions, async (request) => {
  await authenticatedPhone(request);
  const token = request.data && request.data.token;
  if (typeof token !== "string" || token.length < 20 || token.length > 4096) {
    throw new HttpsError("invalid-argument", "Geçerli bildirim cihaz anahtarı zorunludur.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "push-token-register", 10, secret);
  const tokenID = `v1_${keyedDigest(token, secret)}`;
  // A device token has a single current owner. Keeping tokens in a top-level
  // collection lets a later verified login atomically replace that owner,
  // preventing one device from receiving another account's targeted message.
  await db.collection("pushDeviceTokens").doc(tokenID).set({
    token,
    uid: request.auth.uid,
    platform: "ios",
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {registered: true};
});

exports.consumePromotionalCredit = onCall(callableOptions, async (request) => {
  const phone = await authenticatedPhone(request);
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "account-credit-consume", 20, secret);
  const reference = db.collection("accountBenefits")
      .doc(`v1_${keyedDigest(phone, secret)}`);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const data = snapshot.data() || {};
    if (isPremiumActive(data)) {
      return {
        authorized: true,
        promotionalPremiumActive: true,
        promotionalCreditBalance: Math.max(0, Number(data.promotionalCreditBalance || 0)),
      };
    }
    const balance = Math.max(0, Number(data.promotionalCreditBalance || 0));
    if (balance < 1) {
      return {authorized: false, promotionalPremiumActive: false, promotionalCreditBalance: 0};
    }
    transaction.set(reference, {
      promotionalCreditBalance: balance - 1,
      lastCreditConsumedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return {
      authorized: true,
      promotionalPremiumActive: false,
      promotionalCreditBalance: balance - 1,
    };
  });
  return result;
});

exports.claimInitialAdmin = onCall(callableOptions, async (request) => {
  if (!request.auth || request.auth.token.communityModerator !== true) {
    throw new HttpsError("permission-denied", "Mevcut moderatör yetkisi gerekli.");
  }
  const secret = hmacKey.value();
  const ownerUIDHash = keyedDigest(`initial-admin:${request.auth.uid}`, secret);
  const reference = db.collection("adminBootstrapSettings").doc("initial-admin");
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (snapshot.exists && snapshot.data().ownerUIDHash !== ownerUIDHash) {
      throw new HttpsError("permission-denied", "İlk yönetici daha önce tanımlanmış.");
    }
    if (!snapshot.exists) {
      transaction.create(reference, {
        ownerUIDHash,
        claimedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  const user = await getAuth().getUser(request.auth.uid);
  await getAuth().setCustomUserClaims(request.auth.uid, {
    ...user.customClaims,
    communityModerator: true,
    whoCallAdmin: true,
  });
  logger.info("initial_whocall_admin_claimed", {ownerUIDHash});
  return {claimed: true};
});

exports.unpublishVerifiedProfile = onCall(callableOptions, async (request) => {
  const phone = await authenticatedPhone(request);
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
  const phone = await authenticatedPhone(request);
  const isVisible = request.data && request.data.isVisible;
  if (typeof isVisible !== "boolean") {
    throw new HttpsError("invalid-argument", "Görünürlük değeri zorunludur.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "visibility", 10, secret);
  const phoneHmac = keyedDigest(phone, secret);
  const reference = db.collection("verifiedNumberProfiles").doc(`v1_${phoneHmac}`);
  const snapshot = await reference.get();
  if (!snapshot.exists) {
    const user = await getAuth().getUser(request.auth.uid);
    const names = namesFromDisplayName(user.displayName);
    if (!names) {
      throw new HttpsError("not-found", "Yayınlanmış doğrulanmış profil bulunamadı.");
    }
    await reference.set({
      uid: request.auth.uid,
      phoneHmac,
      firstName: names.firstName,
      lastName: names.lastName,
      displayName: `${names.firstName} ${names.lastName}`,
      isVisible,
      verifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    });
    return {published: isVisible};
  }
  if (snapshot.data().uid !== request.auth.uid) {
    throw new HttpsError("not-found", "Yayınlanmış doğrulanmış profil bulunamadı.");
  }
  await reference.set({
    isVisible,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {published: isVisible};
});

exports.recordLegalAcceptance = onCall(callableOptions, async (request) => {
  await authenticatedPhone(request);
  const acceptance = normalizeLegalAcceptance(request.data);
  if (!acceptance) {
    throw new HttpsError("invalid-argument", "Geçerli yasal tercih beyanları zorunludur.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "legal-acceptance", 5, secret);
  await db.collection("userLegalAcceptances").doc(request.auth.uid).set({
    uid: request.auth.uid,
    ...acceptance,
    termsAccepted: true,
    privacyNoticeAcknowledged: true,
    acceptedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {recorded: true};
});

async function deleteQueryInBatches(query, mutateDocument) {
  const batchSize = 180;
  while (true) {
    const snapshot = await query.limit(batchSize).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    for (const document of snapshot.docs) {
      if (mutateDocument) mutateDocument(batch, document);
      else batch.delete(document.ref);
    }
    await batch.commit();
    if (snapshot.size < batchSize) return;
  }
}

exports.deleteWhoCallAccount = onCall(accountDeletionOptions, async (request) => {
  await authenticatedPhone(request);
  const uid = request.auth.uid;
  const secret = hmacKey.value();
  await enforceRateLimit(uid, "account-delete", 2, secret);

  const profileQuery = db.collection("verifiedNumberProfiles").where("uid", "==", uid);
  await deleteQueryInBatches(profileQuery, (batch, document) => {
    batch.set(document.ref, {
      uid: FieldValue.delete(),
      firstName: FieldValue.delete(),
      lastName: FieldValue.delete(),
      displayName: FieldValue.delete(),
      isVisible: false,
      deletedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  await deleteQueryInBatches(
      db.collectionGroup("comments").where("uid", "==", uid),
  );

  const reportID = keyedDigest(uid, secret);
  await deleteQueryInBatches(
      db.collectionGroup("reports").where("uidHash", "==", reportID),
      (batch, document) => {
        batch.delete(document.ref);
        const community = document.ref.parent.parent;
        if (community) {
          batch.set(community, {
            reportCount: FieldValue.increment(-1),
            updatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});
        }
      },
  );

  await deleteQueryInBatches(
      db.collection("communityModerationReports").where("reporterUIDHash", "==", reportID),
  );
  await deleteQueryInBatches(
      db.collection("communityModerationReports").where("authorUID", "==", uid),
      (batch, document) => {
        batch.set(document.ref, {
          authorUID: FieldValue.delete(),
          authorID: FieldValue.delete(),
          targetAccountDeleted: true,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      },
  );
  await deleteQueryInBatches(
      db.collection("pushDeviceTokens").where("uid", "==", uid),
  );

  const batch = db.batch();
  batch.delete(db.collection("userLegalAcceptances").doc(uid));
  batch.delete(db.collection("communityUserSafety").doc(uid));
  const rateLimitOperations = [
    "publish", "lookup", "unpublish", "visibility", "community-read",
    "community-comment", "community-tag", "community-report",
    "community-content-report", "community-user-block",
    "legal-acceptance", "account-delete", "account-access-read",
    "account-credit-consume", "purchase-snapshot-sync",
    "push-token-register",
  ];
  for (const operation of rateLimitOperations) {
    const id = keyedDigest(`${uid}:${operation}`, secret);
    batch.delete(db.collection("directoryRateLimits").doc(id));
  }
  await batch.commit();

  await getAuth().deleteUser(uid);
  return {deleted: true};
});

function communityReference(number, secret) {
  return db.collection("numberCommunities").doc(`v1_${keyedDigest(number, secret)}`);
}

function communitySafetyReference(uid) {
  return db.collection("communityUserSafety").doc(uid);
}

function communityAuthorID(uid, secret) {
  return keyedDigest(`community-author:${uid}`, secret);
}

function commentContentKey(communityID, commentID) {
  return `comment:${communityID}:${commentID}`;
}

function tagContentKey(communityID, tag, secret) {
  const normalizedTag = tag.normalize("NFKC").toLocaleLowerCase("tr-TR");
  return `tag:${communityID}:${keyedDigest(normalizedTag, secret)}`;
}

function moderationReportID(uid, contentKey, action, secret) {
  return `v1_${keyedDigest(`${uid}:${contentKey}:${action}`, secret)}`;
}

function moderationDeadline() {
  return Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
}

function logModerationReport(reportID, action, contentType, communityID) {
  logger.warn("community_moderation_report_created", {
    reportID,
    action,
    contentType,
    communityID,
    responseRequiredWithinHours: 24,
  });
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
  await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  if (!number) throw new HttpsError("invalid-argument", "Geçerli bir numara girin.");
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-read", 30, secret);
  const reference = communityReference(number, secret);
  const [community, comments, safety] = await Promise.all([
    reference.get(),
    reference.collection("comments").orderBy("createdAt", "desc").limit(50).get(),
    communitySafetyReference(request.auth.uid).get(),
  ]);
  const safetyData = safety.data() || {};
  const blockedAuthorIDs = new Set(
      Array.isArray(safetyData.blockedAuthorIDs) ? safetyData.blockedAuthorIDs : [],
  );
  const hiddenContentKeys = new Set(
      Array.isArray(safetyData.hiddenContentKeys) ? safetyData.hiddenContentKeys : [],
  );
  const storedTags = community.data() && Array.isArray(community.data().tags) ?
    community.data().tags : [];
  return {
    tags: storedTags.filter((tag) =>
      !hiddenContentKeys.has(tagContentKey(reference.id, tag, secret)),
    ),
    reportCount: Math.max(0, Number(community.data() && community.data().reportCount || 0)),
    trustLevel: community.data() && community.data().trustOverride || null,
    comments: comments.docs
        .map((document) => {
          const data = document.data();
          const authorID = data.authorID ||
            (data.uid ? communityAuthorID(data.uid, secret) : null);
          return {
            id: document.id,
            authorID,
            author: data.author,
            body: data.body,
            time: relativeTime(data.createdAt),
            isHidden: data.isHidden === true,
          };
        })
        .filter((comment) => comment.authorID &&
          !comment.isHidden &&
          !blockedAuthorIDs.has(comment.authorID) &&
          !hiddenContentKeys.has(commentContentKey(reference.id, comment.id)),
        )
        .map(({isHidden, ...comment}) => comment),
  };
});

exports.addNumberComment = onCall(callableOptions, async (request) => {
  await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const body = cleanCommunityText(request.data && request.data.body, 2, 500);
  if (!number || !body) throw new HttpsError("invalid-argument", "Geçerli numara ve yorum zorunludur.");
  if (containsBlockedCommunityLanguage(body)) {
    throw new HttpsError("invalid-argument", "Yorum küfür veya hakaret içeremez.");
  }
  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-comment", 8, secret);
  const author = communityAuthor(request.auth.token.name) ||
    communityAuthor(request.data && request.data.author) || "WhoCall Kullanıcısı";
  const reference = communityReference(number, secret);
  const commentReference = reference.collection("comments").doc();
  const batch = db.batch();
  batch.set(commentReference, {
    uid: request.auth.uid,
    authorID: communityAuthorID(request.auth.uid, secret),
    author,
    body,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(reference, {updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  await batch.commit();
  return {added: true, id: commentReference.id};
});

exports.addNumberTag = onCall(callableOptions, async (request) => {
  await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const tag = cleanCommunityText(request.data && request.data.tag, 2, 24);
  if (!number || !tag || !/^[\p{L}\p{M}\d '&().\-]+$/u.test(tag)) {
    throw new HttpsError("invalid-argument", "Geçerli bir etiket girin.");
  }
  if (containsBlockedCommunityLanguage(tag)) {
    throw new HttpsError("invalid-argument", "Etiket küfür veya hakaret içeremez.");
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
    transaction.set(reference, {
      phoneMasked: `+90 5** *** ** ${number.slice(-2)}`,
      tags,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
  return {added: true};
});

exports.reportNumber = onCall(callableOptions, async (request) => {
  const reporterPhone = await authenticatedPhone(request);
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
  const reference = communityReference(number, secret);
  const reportID = keyedDigest(request.auth.uid, secret);
  const reportReference = reference.collection("reports").doc(`v1_${reportID}`);
  const reportCount = await db.runTransaction(async (transaction) => {
    const [report, community] = await transaction.getAll(reportReference, reference);
    const currentCount = Math.max(0, Number(community.data() && community.data().reportCount || 0));
    transaction.set(reportReference, {
      uidHash: reportID,
      reporterPhoneMasked: maskedPhone(reporterPhone),
      targetPhoneMasked: maskedPhone(number),
      reason,
      status: "pending",
      createdAt: report.exists ? report.data().createdAt : FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    if (!report.exists) {
      transaction.set(reference, {
        phoneMasked: `+90 5** *** ** ${number.slice(-2)}`,
        reportCount: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    return report.exists ? currentCount : currentCount + 1;
  });
  return {
    reported: true,
    reportCount,
  };
});

exports.reportCommunityContent = onCall(callableOptions, async (request) => {
  const reporterPhone = await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const contentType = normalizeCommunityContentType(
      request.data && request.data.contentType,
  );
  const reason = normalizeCommunityModerationReason(request.data && request.data.reason);
  if (!number || !contentType || !reason) {
    throw new HttpsError("invalid-argument", "Geçerli içerik ve şikâyet nedeni zorunludur.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-content-report", 12, secret);
  const reference = communityReference(number, secret);
  let authorID = null;
  let authorUID = null;
  let contentKey;
  let contentRefPath;
  let contentSnapshot;
  let commentReference = null;

  if (contentType === "comment") {
    const commentID = request.data && request.data.commentID;
    if (typeof commentID !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(commentID)) {
      throw new HttpsError("invalid-argument", "Geçerli bir yorum seçin.");
    }
    commentReference = reference.collection("comments").doc(commentID);
    const comment = await commentReference.get();
    if (!comment.exists || comment.data().isHidden === true) {
      throw new HttpsError("not-found", "Yorum artık kullanılamıyor.");
    }
    authorUID = comment.data().uid || null;
    authorID = comment.data().authorID ||
      (authorUID ? communityAuthorID(authorUID, secret) : null);
    contentKey = commentContentKey(reference.id, comment.id);
    contentRefPath = commentReference.path;
    contentSnapshot = cleanCommunityText(comment.data().body, 2, 500);
  } else {
    const tag = cleanCommunityText(request.data && request.data.tag, 2, 24);
    const community = await reference.get();
    const tags = community.exists && Array.isArray(community.data().tags) ?
      community.data().tags : [];
    const storedTag = tag && tags.find((value) =>
      value.localeCompare(tag, "tr", {sensitivity: "base"}) === 0,
    );
    if (!storedTag) throw new HttpsError("not-found", "Etiket artık kullanılamıyor.");
    contentKey = tagContentKey(reference.id, storedTag, secret);
    contentRefPath = reference.path;
    contentSnapshot = storedTag;
  }

  const reportID = moderationReportID(
      request.auth.uid,
      contentKey,
      "content-report",
      secret,
  );
  const reportReference = db.collection("communityModerationReports").doc(reportID);
  const existingReport = await reportReference.get();
  const batch = db.batch();
  batch.set(communitySafetyReference(request.auth.uid), {
    hiddenContentKeys: FieldValue.arrayUnion(contentKey),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  batch.set(reportReference, {
    reporterUIDHash: keyedDigest(request.auth.uid, secret),
    reporterPhoneMasked: maskedPhone(reporterPhone),
    targetPhoneMasked: maskedPhone(number),
    authorID,
    authorUID,
    communityID: reference.id,
    contentType,
    contentKey,
    contentRefPath,
    contentSnapshot,
    reason,
    action: "contentReported",
    status: "pending",
    createdAt: existingReport.exists ? existingReport.data().createdAt :
      FieldValue.serverTimestamp(),
    lastReportedAt: FieldValue.serverTimestamp(),
    reviewBy: moderationDeadline(),
  }, {merge: true});
  if (!existingReport.exists && commentReference) {
    batch.set(commentReference, {
      moderationReportCount: FieldValue.increment(1),
      latestModerationReportAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();
  if (!existingReport.exists) {
    logModerationReport(reportID, "contentReported", contentType, reference.id);
  }
  return {reported: true};
});

exports.blockCommunityAuthor = onCall(callableOptions, async (request) => {
  const reporterPhone = await authenticatedPhone(request);
  const number = normalizePhone(request.data && request.data.number);
  const commentID = request.data && request.data.commentID;
  const reason = normalizeCommunityModerationReason(request.data && request.data.reason);
  if (!number || typeof commentID !== "string" ||
      !/^[A-Za-z0-9_-]{1,128}$/.test(commentID) || !reason) {
    throw new HttpsError("invalid-argument", "Geçerli kullanıcı ve engelleme nedeni zorunludur.");
  }

  const secret = hmacKey.value();
  await enforceRateLimit(request.auth.uid, "community-user-block", 12, secret);
  const reference = communityReference(number, secret);
  const commentReference = reference.collection("comments").doc(commentID);
  const comment = await commentReference.get();
  if (!comment.exists || comment.data().isHidden === true) {
    throw new HttpsError("not-found", "Yorum artık kullanılamıyor.");
  }
  const authorUID = comment.data().uid;
  if (!authorUID) throw new HttpsError("failed-precondition", "Yorum sahibi engellenemiyor.");
  if (authorUID === request.auth.uid) {
    throw new HttpsError("failed-precondition", "Kendi hesabınızı engelleyemezsiniz.");
  }

  const authorID = comment.data().authorID || communityAuthorID(authorUID, secret);
  const contentKey = commentContentKey(reference.id, comment.id);
  const reportID = moderationReportID(request.auth.uid, contentKey, "user-block", secret);
  const reportReference = db.collection("communityModerationReports").doc(reportID);
  const existingReport = await reportReference.get();
  const batch = db.batch();
  batch.set(communitySafetyReference(request.auth.uid), {
    blockedAuthorIDs: FieldValue.arrayUnion(authorID),
    hiddenContentKeys: FieldValue.arrayUnion(contentKey),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  batch.set(reportReference, {
    reporterUIDHash: keyedDigest(request.auth.uid, secret),
    reporterPhoneMasked: maskedPhone(reporterPhone),
    targetPhoneMasked: maskedPhone(number),
    authorID,
    authorUID,
    communityID: reference.id,
    contentType: "comment",
    contentKey,
    contentRefPath: commentReference.path,
    contentSnapshot: cleanCommunityText(comment.data().body, 2, 500),
    reason,
    action: "userBlocked",
    status: "pending",
    createdAt: existingReport.exists ? existingReport.data().createdAt :
      FieldValue.serverTimestamp(),
    lastReportedAt: FieldValue.serverTimestamp(),
    reviewBy: moderationDeadline(),
  }, {merge: true});
  if (!existingReport.exists) {
    batch.set(commentReference, {
      moderationReportCount: FieldValue.increment(1),
      latestModerationReportAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  await batch.commit();
  if (!existingReport.exists) {
    logModerationReport(reportID, "userBlocked", "comment", reference.id);
  }
  return {blocked: true, authorID};
});

exports.moderateCommunityReport = onCall(
    {...callableOptions, timeoutSeconds: 30},
    async (request) => {
      if (!request.auth || (request.auth.token.communityModerator !== true &&
          request.auth.token.whoCallAdmin !== true)) {
        throw new HttpsError("permission-denied", "Moderasyon yetkisi gerekli.");
      }
      const reportID = request.data && request.data.reportID;
      const decision = request.data && request.data.decision;
      const allowedDecisions = new Set([
        "dismiss",
        "remove-content",
        "remove-content-and-suspend-user",
      ]);
      if (typeof reportID !== "string" || !/^v1_[a-f0-9]{64}$/.test(reportID) ||
          !allowedDecisions.has(decision)) {
        throw new HttpsError("invalid-argument", "Geçerli rapor ve karar zorunludur.");
      }

      const reportReference = db.collection("communityModerationReports").doc(reportID);
      const report = await reportReference.get();
      if (!report.exists) throw new HttpsError("not-found", "Moderasyon raporu bulunamadı.");
      const data = report.data();
      if (decision === "remove-content-and-suspend-user") {
        if (!data.authorUID) {
          throw new HttpsError("failed-precondition", "İçerik sahibi bulunamadı.");
        }
        await getAuth().updateUser(data.authorUID, {disabled: true});
      }

      const batch = db.batch();
      if (decision !== "dismiss") {
        if (data.contentType === "comment" && data.contentRefPath) {
          batch.set(db.doc(data.contentRefPath), {
            isHidden: true,
            moderatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});
        } else if (data.contentType === "tag" && data.contentRefPath &&
            data.contentSnapshot) {
          batch.set(db.doc(data.contentRefPath), {
            tags: FieldValue.arrayRemove(data.contentSnapshot),
            moderatedAt: FieldValue.serverTimestamp(),
          }, {merge: true});
        }
      }
      batch.set(reportReference, {
        status: decision === "dismiss" ? "dismissed" : "resolved",
        decision,
        resolvedAt: FieldValue.serverTimestamp(),
        resolverUIDHash: keyedDigest(request.auth.uid, hmacKey.value()),
      }, {merge: true});
      await batch.commit();
      logger.info("community_moderation_report_resolved", {reportID, decision});
      return {resolved: true};
    },
);

const adminService = createAdminService({
  db,
  auth: getAuth(),
  messaging: getMessaging(),
  FieldValue,
  Timestamp,
  HttpsError,
  hmacKey,
});

exports.adminQuery = onCall(adminOptions, (request) => adminService.query(request));
exports.adminMutate = onCall(adminOptions, (request) => adminService.mutate(request));
