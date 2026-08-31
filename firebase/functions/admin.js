"use strict";

const {
  containsBlockedCommunityLanguage,
  keyedDigest,
  maskedPhone,
  normalizeAdminPremiumDuration,
  normalizeAdminTrustLevel,
  normalizeCreditAdjustment,
  normalizeName,
  normalizePhone,
  namesFromDisplayName,
} = require("./directory");

const PHONE_ID_PATTERN = /^v1_[a-f0-9]{64}$/;
const DOCUMENT_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const USER_ID_PATTERN = /^[A-Za-z0-9:_-]{1,128}$/;
const ADMIN_ACTIONS = new Set([
  "upsert-phone",
  "exclude-phone",
  "restore-phone",
  "set-visibility",
  "set-premium",
  "adjust-credits",
  "set-trust",
  "add-tag",
  "update-tag",
  "delete-tag",
  "add-comment",
  "update-comment",
  "delete-comment",
  "resolve-number-report",
  "set-user-disabled",
  "set-app-config",
  "bulk-adjust-credits",
  "bulk-set-premium",
  "send-notification",
]);

const DEFAULT_APP_CONFIGURATION = Object.freeze({
  signupCreditAmount: 1,
  showPostLoginPaywall: true,
});

function cleanText(value, minLength, maxLength) {
  if (typeof value !== "string") return null;
  const clean = value.trim().replace(/\s+/g, " ").normalize("NFC");
  const length = Array.from(clean).length;
  return length >= minLength && length <= maxLength ? clean : null;
}

function serializeTimestamp(value) {
  return value && typeof value.toDate === "function" ? value.toDate().toISOString() : null;
}

function serializeDocument(document) {
  const data = document.data();
  return {
    id: document.id,
    ...data,
    createdAt: serializeTimestamp(data.createdAt),
    updatedAt: serializeTimestamp(data.updatedAt),
    lastReportedAt: serializeTimestamp(data.lastReportedAt),
    reviewBy: serializeTimestamp(data.reviewBy),
    resolvedAt: serializeTimestamp(data.resolvedAt),
  };
}

function newestFirst(left, right) {
  const leftTime = Date.parse(left.updatedAt || left.createdAt || "") || 0;
  const rightTime = Date.parse(right.updatedAt || right.createdAt || "") || 0;
  return rightTime - leftTime;
}

function isMissingIndexError(error) {
  const code = error && error.code;
  const message = String(error && error.message || "");
  return [9, "failed-precondition", "firestore/failed-precondition"].includes(code) &&
    /query requires(?: a)?(?: collection_desc)? index/i.test(message);
}

function publicProfile(profile) {
  if (!profile) return null;
  return {
    firstName: profile.firstName || "",
    lastName: profile.lastName || "",
    displayName: profile.displayName || "",
    isVisible: profile.isVisible !== false,
    source: profile.source || (profile.uid ? "verified-user" : "admin"),
    hasOwner: Boolean(profile.uid),
    updatedAt: serializeTimestamp(profile.updatedAt),
  };
}

function publicAppConfiguration(data) {
  const signupCreditAmount = Number(data && data.signupCreditAmount);
  return {
    signupCreditAmount: Number.isSafeInteger(signupCreditAmount) &&
      signupCreditAmount >= 0 && signupCreditAmount <= 100 ?
      signupCreditAmount : DEFAULT_APP_CONFIGURATION.signupCreditAmount,
    showPostLoginPaywall: data && typeof data.showPostLoginPaywall === "boolean" ?
      data.showPostLoginPaywall : DEFAULT_APP_CONFIGURATION.showPostLoginPaywall,
  };
}

function premiumExpiresAt(duration, Timestamp) {
  if (duration === "lifetime" || duration === "revoke") return null;
  const days = duration === "7-days" ? 7 : 30;
  return Timestamp.fromMillis(Date.now() + days * 24 * 60 * 60 * 1000);
}

function isPremiumActive(data) {
  if (!data || data.promotionalPremiumActive !== true) return false;
  const expiresAt = data.promotionalPremiumExpiresAt;
  return !expiresAt || expiresAt.toMillis() > Date.now();
}

function accountPurchaseSummary(data, fallbackRevenueCatAppUserID = null) {
  const benefit = data || {};
  const serverPurchasedCredits = Number(benefit.purchasedCreditBalance);
  const reportedPurchasedCredits = Number(benefit.reportedPurchasedCreditBalance);
  const promotionalCredits = Number(benefit.promotionalCreditBalance);
  const purchasedCreditBalance = Number.isSafeInteger(serverPurchasedCredits) ?
    Math.max(0, serverPurchasedCredits) :
    Number.isSafeInteger(reportedPurchasedCredits) ?
      Math.max(0, reportedPurchasedCredits) : 0;
  const promotionalCreditBalance = Number.isSafeInteger(promotionalCredits) ?
    Math.max(0, promotionalCredits) : 0;
  const promotionalPremiumActive = isPremiumActive(benefit);
  const revenueCatPremiumActive = benefit.reportedRevenueCatPremiumActive === true;
  const storedRevenueCatID = typeof benefit.revenueCatAppUserID === "string" &&
    USER_ID_PATTERN.test(benefit.revenueCatAppUserID) ? benefit.revenueCatAppUserID : null;
  return {
    revenueCatAppUserID: storedRevenueCatID || fallbackRevenueCatAppUserID,
    revenueCatPremiumActive,
    promotionalPremiumActive,
    premiumActive: revenueCatPremiumActive || promotionalPremiumActive,
    purchasedCreditBalance,
    promotionalCreditBalance,
    totalCreditBalance: purchasedCreditBalance + promotionalCreditBalance,
    purchaseSnapshotUpdatedAt: serializeTimestamp(benefit.purchaseSnapshotUpdatedAt),
  };
}

async function countPhoneUsers(auth, firstPage) {
  let totalUsers = firstPage.users.reduce((count, user) =>
    count + (normalizePhone(user.phoneNumber) ? 1 : 0), 0);
  let pageToken = firstPage.pageToken;
  while (pageToken) {
    const page = await auth.listUsers(1000, pageToken);
    totalUsers += page.users.reduce((count, user) =>
      count + (normalizePhone(user.phoneNumber) ? 1 : 0), 0);
    pageToken = page.pageToken;
  }
  return totalUsers;
}

function createAdminService({db, auth, messaging, FieldValue, Timestamp, HttpsError, hmacKey}) {
  function requireAdmin(request) {
    if (!request.auth || request.auth.token.whoCallAdmin !== true) {
      throw new HttpsError("permission-denied", "WhoCall yönetici yetkisi gerekli.");
    }
    return request.auth.uid;
  }

  function contextForPhone(rawPhone) {
    const phone = normalizePhone(rawPhone);
    if (!phone) throw new HttpsError("invalid-argument", "Geçerli bir Türkiye GSM numarası girin.");
    const digest = keyedDigest(phone, hmacKey.value());
    const id = `v1_${digest}`;
    return {
      phone,
      id,
      masked: maskedPhone(phone),
      profile: db.collection("verifiedNumberProfiles").doc(id),
      exclusion: db.collection("adminExcludedNumbers").doc(id),
      benefits: db.collection("accountBenefits").doc(id),
      community: db.collection("numberCommunities").doc(id),
    };
  }

  async function audit(uid, action, targetID, details = {}) {
    await db.collection("adminAuditLogs").add({
      actorUIDHash: keyedDigest(`admin:${uid}`, hmacKey.value()),
      action,
      targetID,
      details,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  async function overview() {
    const [profiles, exclusions, benefits, contentReports] = await Promise.all([
      db.collection("verifiedNumberProfiles").count().get(),
      db.collection("adminExcludedNumbers").where("active", "==", true).count().get(),
      db.collection("accountBenefits").count().get(),
      db.collection("communityModerationReports").where("status", "==", "pending").count().get(),
    ]);
    return {
      profiles: profiles.data().count,
      excludedNumbers: exclusions.data().count,
      managedAccounts: benefits.data().count,
      pendingContentReports: contentReports.data().count,
    };
  }

  async function appConfiguration() {
    const snapshot = await db.collection("appConfiguration").doc("public").get();
    return publicAppConfiguration(snapshot.data());
  }

  async function allPhoneUsers() {
    const entries = [];
    let pageToken;
    do {
      const page = await auth.listUsers(1000, pageToken);
      for (const user of page.users) {
        const phone = normalizePhone(user.phoneNumber);
        if (phone) entries.push({user, phone});
      }
      pageToken = page.pageToken;
    } while (pageToken);
    return entries;
  }

  async function reportIdentityMaps() {
    const users = await allPhoneUsers();
    const phoneByUIDHash = new Map();
    const phoneByCommunityID = new Map();
    for (const {user, phone} of users) {
      const fullPhone = `+${phone}`;
      phoneByUIDHash.set(keyedDigest(user.uid, hmacKey.value()), fullPhone);
      phoneByCommunityID.set(`v1_${keyedDigest(phone, hmacKey.value())}`, fullPhone);
    }
    return {phoneByUIDHash, phoneByCommunityID};
  }

  async function phoneDetails(rawPhone) {
    const context = contextForPhone(rawPhone);
    const [profile, exclusion, benefits, community, comments, numberReports] = await Promise.all([
      context.profile.get(),
      context.exclusion.get(),
      context.benefits.get(),
      context.community.get(),
      context.community.collection("comments").orderBy("createdAt", "desc").limit(100).get(),
      context.community.collection("reports").limit(100).get(),
    ]);
    let authUser = null;
    try {
      const user = await auth.getUserByPhoneNumber(`+${context.phone}`);
      authUser = {
        registered: true,
        uid: user.uid,
        disabled: user.disabled,
        displayName: user.displayName || null,
      };
    } catch (error) {
      if (!error || error.code !== "auth/user-not-found") throw error;
      authUser = {registered: false, uid: null, disabled: false, displayName: null};
    }
    const benefitData = benefits.data() || {};
    const communityData = community.data() || {};
    const authNames = namesFromDisplayName(authUser.displayName);
    const effectiveProfile = profile.exists ? publicProfile(profile.data()) : authNames ? {
      firstName: authNames.firstName,
      lastName: authNames.lastName,
      displayName: `${authNames.firstName} ${authNames.lastName}`,
      isVisible: true,
      source: "firebase-auth",
      hasOwner: true,
      updatedAt: null,
    } : null;
    return {
      phone: context.masked,
      recordID: context.id,
      profile: effectiveProfile,
      isExcluded: exclusion.exists && exclusion.data().active === true,
      account: {
        ...authUser,
        ...accountPurchaseSummary(benefitData, authUser.uid),
        promotionalPremiumExpiresAt: serializeTimestamp(benefitData.promotionalPremiumExpiresAt),
      },
      community: {
        trustOverride: communityData.trustOverride || null,
        reportCount: Math.max(0, Number(communityData.reportCount || 0)),
        tags: Array.isArray(communityData.tags) ? communityData.tags : [],
        comments: comments.docs.map(serializeDocument).map((comment) => ({
          id: comment.id,
          author: comment.author || "WhoCall Kullanıcısı",
          body: comment.body || "",
          isHidden: comment.isHidden === true,
          createdAt: comment.createdAt,
          updatedAt: comment.updatedAt,
        })),
        reports: numberReports.docs.map(serializeDocument).sort(newestFirst).map((report) => ({
          id: report.id,
          reason: report.reason || "Diğer",
          status: report.status || "pending",
          reporterPhoneMasked: report.reporterPhoneMasked || null,
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
          decision: report.decision || null,
        })),
      },
    };
  }

  async function reports(limit) {
    const safeLimit = Math.min(100, Math.max(10, Number(limit) || 50));
    const content = await db.collection("communityModerationReports")
        .orderBy("lastReportedAt", "desc").limit(safeLimit).get();
    let numberReports;
    try {
      numberReports = await db.collectionGroup("reports")
          .orderBy("updatedAt", "desc").limit(safeLimit).get();
    } catch (error) {
      if (!isMissingIndexError(error)) throw error;
      numberReports = await db.collectionGroup("reports").limit(safeLimit).get();
    }
    const {phoneByUIDHash, phoneByCommunityID} = await reportIdentityMaps();
    const communityIDs = new Set([
      ...content.docs.map((document) => document.data().communityID),
      ...numberReports.docs.map((document) => document.ref.parent.parent.id),
    ].filter(Boolean));
    const communitySnapshots = communityIDs.size ?
      await db.getAll(...[...communityIDs].map((id) => db.collection("numberCommunities").doc(id))) : [];
    const targetPhoneByCommunityID = new Map(communitySnapshots.map((snapshot) => [
      snapshot.id,
      snapshot.data() && snapshot.data().phoneMasked || null,
    ]));
    return {
      content: content.docs.map(serializeDocument).map((report) => ({
        id: report.id,
        action: report.action,
        contentType: report.contentType,
        contentSnapshot: report.contentSnapshot,
        reason: report.reason,
        status: report.status,
        decision: report.decision || null,
        communityID: report.communityID,
        reporterPhone: phoneByUIDHash.get(report.reporterUIDHash) || null,
        reporterPhoneMasked: report.reporterPhoneMasked || null,
        targetPhone: phoneByCommunityID.get(report.communityID) || null,
        targetPhoneMasked: report.targetPhoneMasked ||
          targetPhoneByCommunityID.get(report.communityID) || null,
        createdAt: report.createdAt,
        reviewBy: report.reviewBy,
        resolvedAt: report.resolvedAt,
      })),
      numbers: numberReports.docs.map((document) => {
        const report = serializeDocument(document);
        return {
          id: report.id,
          communityID: document.ref.parent.parent.id,
          reason: report.reason,
          reporterPhone: phoneByUIDHash.get(report.uidHash) || null,
          reporterPhoneMasked: report.reporterPhoneMasked || null,
          targetPhone: phoneByCommunityID.get(document.ref.parent.parent.id) || null,
          targetPhoneMasked: report.targetPhoneMasked ||
            targetPhoneByCommunityID.get(document.ref.parent.parent.id) || null,
          status: report.status || "pending",
          decision: report.decision || null,
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
        };
      }).sort(newestFirst),
    };
  }

  async function users(limit, pageToken, includeTotal) {
    const safeLimit = Math.min(100, Math.max(10, Number(limit) || 50));
    const safePageToken = cleanText(pageToken, 1, 2000) || undefined;
    const result = await auth.listUsers(safeLimit, safePageToken);
    const phoneUsers = result.users.map((user) => ({
      user,
      phone: normalizePhone(user.phoneNumber),
    })).filter((entry) => entry.phone);
    const contexts = phoneUsers.map((entry) => contextForPhone(entry.phone));
    const [profiles, benefits] = contexts.length ? await Promise.all([
      db.getAll(...contexts.map((context) => context.profile)),
      db.getAll(...contexts.map((context) => context.benefits)),
    ]) : [[], []];
    const response = {
      items: phoneUsers.map(({user, phone}, index) => {
        const profile = profiles[index].data() || {};
        const benefit = benefits[index].data() || {};
        const authNames = namesFromDisplayName(user.displayName);
        const profilePublished = profiles[index].exists || Boolean(authNames);
        const firstName = profile.firstName || authNames && authNames.firstName || "";
        const lastName = profile.lastName || authNames && authNames.lastName || "";
        return {
          uid: user.uid,
          ...accountPurchaseSummary(benefit, user.uid),
          phone: `+${phone}`,
          phoneMasked: maskedPhone(phone),
          displayName: profile.displayName || user.displayName || "İsimsiz kullanıcı",
          firstName,
          lastName,
          isVisible: profile.isVisible !== false,
          disabled: user.disabled === true,
          profilePublished,
          promotionalPremiumExpiresAt: serializeTimestamp(benefit.promotionalPremiumExpiresAt),
          createdAt: user.metadata && user.metadata.creationTime || null,
          lastSignInAt: user.metadata && user.metadata.lastSignInTime || null,
        };
      }),
      nextPageToken: result.pageToken || null,
    };
    if (includeTotal === true) {
      response.totalUsers = await countPhoneUsers(auth, result);
    }
    return response;
  }

  async function audits(limit) {
    const safeLimit = Math.min(100, Math.max(10, Number(limit) || 50));
    const snapshot = await db.collection("adminAuditLogs")
        .orderBy("createdAt", "desc").limit(safeLimit).get();
    return snapshot.docs.map(serializeDocument);
  }

  async function query(request) {
    requireAdmin(request);
    const action = request.data && request.data.action;
    if (action === "overview") return overview();
    if (action === "phone") return phoneDetails(request.data.phone);
    if (action === "users") {
      return users(request.data.limit, request.data.pageToken, request.data.includeTotal);
    }
    if (action === "reports") return reports(request.data.limit);
    if (action === "audits") return audits(request.data.limit);
    if (action === "app-config") return appConfiguration();
    throw new HttpsError("invalid-argument", "Geçerli bir yönetim sorgusu seçin.");
  }

  async function upsertPhone(uid, data) {
    const context = contextForPhone(data.phone);
    const firstName = normalizeName(data.firstName);
    const lastName = normalizeName(data.lastName);
    if (!firstName || !lastName || typeof data.isVisible !== "boolean") {
      throw new HttpsError("invalid-argument", "Ad, soyad ve görünürlük bilgisi zorunludur.");
    }
    const existing = await context.profile.get();
    const batch = db.batch();
    batch.set(context.profile, {
      firstName,
      lastName,
      displayName: `${firstName} ${lastName}`,
      isVisible: data.isVisible,
      phoneHmac: context.id.slice(3),
      phoneMasked: context.masked,
      source: "admin",
      adminManaged: true,
      schemaVersion: 1,
      verifiedAt: existing.exists && existing.data().verifiedAt ?
        existing.data().verifiedAt : FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      deletedAt: FieldValue.delete(),
    }, {merge: true});
    batch.delete(context.exclusion);
    batch.set(context.community, {
      phoneMasked: context.masked,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    await audit(uid, "upsert-phone", context.id, {
      isVisible: data.isVisible,
      replacedExisting: existing.exists,
    });
    return {saved: true, phone: context.masked};
  }

  async function excludePhone(uid, data) {
    const context = contextForPhone(data.phone);
    const reason = cleanText(data.reason, 3, 160) || "Yönetici tarafından dizinden çıkarıldı";
    const batch = db.batch();
    batch.delete(context.profile);
    batch.set(context.exclusion, {
      active: true,
      phoneMasked: context.masked,
      reason,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    await audit(uid, "exclude-phone", context.id, {reason});
    return {excluded: true};
  }

  async function restorePhone(uid, data) {
    const context = contextForPhone(data.phone);
    await context.exclusion.delete();
    await audit(uid, "restore-phone", context.id);
    return {restored: true};
  }

  async function setVisibility(uid, data) {
    const context = contextForPhone(data.phone);
    if (typeof data.isVisible !== "boolean") {
      throw new HttpsError("invalid-argument", "Görünürlük değeri zorunludur.");
    }
    const profile = await context.profile.get();
    if (!profile.exists) throw new HttpsError("not-found", "Yönetilecek numara kaydı bulunamadı.");
    await context.profile.set({
      isVisible: data.isVisible,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await audit(uid, "set-visibility", context.id, {isVisible: data.isVisible});
    return {saved: true};
  }

  async function setPremium(uid, data) {
    const context = contextForPhone(data.phone);
    const duration = normalizeAdminPremiumDuration(data.duration);
    if (!duration) throw new HttpsError("invalid-argument", "Geçerli premium süresi seçin.");
    const active = duration !== "revoke";
    const expiresAt = premiumExpiresAt(duration, Timestamp);
    await context.benefits.set({
      phoneMasked: context.masked,
      promotionalPremiumActive: active,
      promotionalPremiumExpiresAt: expiresAt || FieldValue.delete(),
      premiumSource: active ? "admin-promotion" : FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await audit(uid, active ? "grant-premium" : "revoke-premium", context.id, {
      duration,
      expiresAt: serializeTimestamp(expiresAt),
    });
    return {active, expiresAt: serializeTimestamp(expiresAt)};
  }

  async function adjustCredits(uid, data) {
    const context = contextForPhone(data.phone);
    const adjustment = normalizeCreditAdjustment(data.adjustment);
    if (!adjustment) throw new HttpsError("invalid-argument", "Geçerli kredi değişimi girin.");
    const balance = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(context.benefits);
      const current = Math.max(0, Number(snapshot.data() &&
        snapshot.data().promotionalCreditBalance || 0));
      const next = current + adjustment;
      if (next < 0) throw new HttpsError("failed-precondition", "Kredi bakiyesi sıfırın altına inemez.");
      transaction.set(context.benefits, {
        phoneMasked: context.masked,
        promotionalCreditBalance: next,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return next;
    });
    await audit(uid, "adjust-credits", context.id, {adjustment, balance});
    return {balance};
  }

  async function setTrust(uid, data) {
    const context = contextForPhone(data.phone);
    const trust = normalizeAdminTrustLevel(data.trustLevel);
    if (trust === undefined) throw new HttpsError("invalid-argument", "Geçerli güven seviyesi seçin.");
    await context.community.set({
      phoneMasked: context.masked,
      trustOverride: trust || FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await audit(uid, "set-trust", context.id, {trustLevel: trust || "automatic"});
    return {trustLevel: trust};
  }

  function validatedTag(value) {
    const tag = cleanText(value, 2, 24);
    if (!tag || !/^[\p{L}\p{M}\d '&().\-]+$/u.test(tag) ||
        containsBlockedCommunityLanguage(tag)) {
      throw new HttpsError("invalid-argument", "Etiket biçimini ve içeriğini kontrol edin.");
    }
    return tag;
  }

  async function mutateTag(uid, action, data) {
    const context = contextForPhone(data.phone);
    const currentTag = action === "add-tag" ? null : validatedTag(data.currentTag);
    const nextTag = action === "delete-tag" ? null : validatedTag(data.tag);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(context.community);
      const tags = snapshot.exists && Array.isArray(snapshot.data().tags) ? snapshot.data().tags : [];
      let next = tags;
      if (action === "add-tag") {
        if (!tags.some((tag) => tag.localeCompare(nextTag, "tr", {sensitivity: "base"}) === 0)) {
          if (tags.length >= 30) throw new HttpsError("resource-exhausted", "Etiket sınırına ulaşıldı.");
          next = [...tags, nextTag];
        }
      } else {
        const index = tags.findIndex((tag) =>
          tag.localeCompare(currentTag, "tr", {sensitivity: "base"}) === 0);
        if (index < 0) throw new HttpsError("not-found", "Etiket bulunamadı.");
        next = [...tags];
        if (action === "delete-tag") next.splice(index, 1);
        else next[index] = nextTag;
      }
      transaction.set(context.community, {
        phoneMasked: context.masked,
        tags: next,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    });
    await audit(uid, action, context.id, {currentTag, nextTag});
    return {saved: true};
  }

  function validatedCommentBody(value) {
    const body = cleanText(value, 2, 500);
    if (!body || containsBlockedCommunityLanguage(body)) {
      throw new HttpsError("invalid-argument", "Yorum biçimini ve içeriğini kontrol edin.");
    }
    return body;
  }

  async function mutateComment(uid, action, data) {
    const context = contextForPhone(data.phone);
    const commentID = data.commentID;
    if (action !== "add-comment" &&
        (typeof commentID !== "string" || !DOCUMENT_ID_PATTERN.test(commentID))) {
      throw new HttpsError("invalid-argument", "Geçerli yorum seçin.");
    }
    const reference = action === "add-comment" ?
      context.community.collection("comments").doc() :
      context.community.collection("comments").doc(commentID);
    if (action === "delete-comment") {
      await reference.delete();
    } else {
      const body = validatedCommentBody(data.body);
      const author = cleanText(data.author || "WhoCall Ekibi", 2, 40);
      if (!author) throw new HttpsError("invalid-argument", "Geçerli yorum yazarı girin.");
      const existing = action === "update-comment" ? await reference.get() : null;
      if (existing && !existing.exists) throw new HttpsError("not-found", "Yorum bulunamadı.");
      await reference.set({
        author,
        authorID: "whocall-admin",
        body,
        source: "admin",
        isHidden: false,
        createdAt: existing && existing.data().createdAt ?
          existing.data().createdAt : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      await context.community.set({
        phoneMasked: context.masked,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    await audit(uid, action, context.id, {commentID: reference.id});
    return {saved: true, commentID: reference.id};
  }

  async function resolveNumberReport(uid, data) {
    const communityID = data.communityID;
    const reportID = data.reportID;
    const decision = data.decision;
    if (typeof communityID !== "string" || !PHONE_ID_PATTERN.test(communityID) ||
        typeof reportID !== "string" || !DOCUMENT_ID_PATTERN.test(reportID) ||
        !["dismiss", "uphold"].includes(decision)) {
      throw new HttpsError("invalid-argument", "Geçerli rapor ve karar seçin.");
    }
    const community = db.collection("numberCommunities").doc(communityID);
    const report = community.collection("reports").doc(reportID);
    await db.runTransaction(async (transaction) => {
      const [reportSnapshot, communitySnapshot] = await transaction.getAll(report, community);
      if (!reportSnapshot.exists) throw new HttpsError("not-found", "Rapor bulunamadı.");
      const wasPending = !reportSnapshot.data().status || reportSnapshot.data().status === "pending";
      transaction.set(report, {
        status: decision === "dismiss" ? "dismissed" : "resolved",
        decision,
        resolvedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      if (decision === "dismiss" && wasPending) {
        const count = Math.max(0, Number(communitySnapshot.data() &&
          communitySnapshot.data().reportCount || 0) - 1);
        transaction.set(community, {
          reportCount: count,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }
    });
    await audit(uid, "resolve-number-report", communityID, {reportID, decision});
    return {resolved: true};
  }

  async function setUserDisabled(uid, data) {
    const targetUID = data.uid;
    if (typeof targetUID !== "string" || !USER_ID_PATTERN.test(targetUID) ||
        typeof data.disabled !== "boolean") {
      throw new HttpsError("invalid-argument", "Geçerli kullanıcı ve hesap durumu seçin.");
    }
    if (targetUID === uid && data.disabled) {
      throw new HttpsError("failed-precondition", "Kendi yönetici hesabınızı devre dışı bırakamazsınız.");
    }
    const user = await auth.updateUser(targetUID, {disabled: data.disabled});
    const targetID = keyedDigest(`user:${targetUID}`, hmacKey.value());
    await audit(uid, "set-user-disabled", targetID, {disabled: data.disabled});
    return {uid: user.uid, disabled: user.disabled === true};
  }

  async function setAppConfiguration(uid, data) {
    const signupCreditAmount = Number(data.signupCreditAmount);
    if (!Number.isSafeInteger(signupCreditAmount) || signupCreditAmount < 0 ||
        signupCreditAmount > 100 || typeof data.showPostLoginPaywall !== "boolean") {
      throw new HttpsError("invalid-argument", "Başlangıç kredisi ve paywall ayarını kontrol edin.");
    }
    await db.collection("appConfiguration").doc("public").set({
      signupCreditAmount,
      showPostLoginPaywall: data.showPostLoginPaywall,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    await audit(uid, "set-app-config", "appConfiguration/public", {
      signupCreditAmount,
      showPostLoginPaywall: data.showPostLoginPaywall,
    });
    return {saved: true, signupCreditAmount, showPostLoginPaywall: data.showPostLoginPaywall};
  }

  async function contextsForAudience(data) {
    if (data.audience === "single") return [contextForPhone(data.phone)];
    if (data.audience !== "all") {
      throw new HttpsError("invalid-argument", "Geçerli kullanıcı kitlesi seçin.");
    }
    const users = await allPhoneUsers();
    return [...new Map(users.map(({phone}) => {
      const context = contextForPhone(phone);
      return [context.id, context];
    })).values()];
  }

  async function commitInChunks(contexts, writer) {
    for (let offset = 0; offset < contexts.length; offset += 400) {
      const batch = db.batch();
      for (const context of contexts.slice(offset, offset + 400)) writer(batch, context);
      await batch.commit();
    }
  }

  async function bulkAdjustCredits(uid, data) {
    const amount = Number(data.amount);
    if (!Number.isSafeInteger(amount) || amount < 1 || amount > 1000) {
      throw new HttpsError("invalid-argument", "1 ile 1000 arasında kredi miktarı girin.");
    }
    const contexts = await contextsForAudience(data);
    await commitInChunks(contexts, (batch, context) => batch.set(context.benefits, {
      phoneMasked: context.masked,
      promotionalCreditBalance: FieldValue.increment(amount),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true}));
    await audit(uid, "bulk-adjust-credits", `audience:${data.audience}`, {
      amount,
      affectedAccounts: contexts.length,
    });
    return {affectedAccounts: contexts.length, amount};
  }

  async function bulkSetPremium(uid, data) {
    const duration = normalizeAdminPremiumDuration(data.duration);
    if (!duration || duration === "revoke") {
      throw new HttpsError("invalid-argument", "Geçerli premium süresi seçin.");
    }
    const contexts = await contextsForAudience(data);
    const expiresAt = premiumExpiresAt(duration, Timestamp);
    await commitInChunks(contexts, (batch, context) => batch.set(context.benefits, {
      phoneMasked: context.masked,
      promotionalPremiumActive: true,
      promotionalPremiumExpiresAt: expiresAt || FieldValue.delete(),
      premiumSource: "admin-campaign",
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true}));
    await audit(uid, "bulk-set-premium", `audience:${data.audience}`, {
      duration,
      affectedAccounts: contexts.length,
    });
    return {affectedAccounts: contexts.length, expiresAt: serializeTimestamp(expiresAt)};
  }

  async function notificationTokensForAudience(data) {
    if (data.audience === "single") {
      const phone = normalizePhone(data.phone);
      if (!phone) throw new HttpsError("invalid-argument", "Geçerli telefon numarası girin.");
      let user;
      try {
        user = await auth.getUserByPhoneNumber(`+${phone}`);
      } catch (error) {
        if (error && error.code === "auth/user-not-found") {
          throw new HttpsError("not-found", "Bu numarayla kayıtlı kullanıcı bulunamadı.");
        }
        throw error;
      }
      const snapshot = await db.collection("pushDeviceTokens").where("uid", "==", user.uid).get();
      return snapshot.docs.map((document) => ({token: document.data().token, reference: document.ref}));
    }
    if (data.audience !== "all") {
      throw new HttpsError("invalid-argument", "Geçerli kullanıcı kitlesi seçin.");
    }
    const snapshot = await db.collection("pushDeviceTokens").get();
    return snapshot.docs.map((document) => ({token: document.data().token, reference: document.ref}));
  }

  async function sendNotification(uid, data) {
    const title = cleanText(data.title, 2, 80);
    const body = cleanText(data.body, 2, 240);
    if (!title || !body) throw new HttpsError("invalid-argument", "Bildirim başlığı ve metni zorunludur.");
    const tokenEntries = (await notificationTokensForAudience(data))
        .filter((entry) => typeof entry.token === "string" && entry.token.length > 20);
    if (!tokenEntries.length) throw new HttpsError("not-found", "Bildirim alabilecek cihaz bulunamadı.");
    let successCount = 0;
    let failureCount = 0;
    const invalidReferences = [];
    for (let offset = 0; offset < tokenEntries.length; offset += 500) {
      const chunk = tokenEntries.slice(offset, offset + 500);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk.map((entry) => entry.token),
        notification: {title, body},
        apns: {payload: {aps: {sound: "default"}}},
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
      response.responses.forEach((result, index) => {
        const code = result.error && result.error.code;
        if (["messaging/registration-token-not-registered", "messaging/invalid-registration-token"].includes(code)) {
          invalidReferences.push(chunk[index].reference);
        }
      });
    }
    if (invalidReferences.length) {
      await commitInChunks(invalidReferences, (batch, reference) => batch.delete(reference));
    }
    await audit(uid, "send-notification", `audience:${data.audience}`, {
      successCount,
      failureCount,
      titleLength: Array.from(title).length,
      bodyLength: Array.from(body).length,
    });
    return {successCount, failureCount};
  }

  async function mutate(request) {
    const uid = requireAdmin(request);
    const data = request.data || {};
    const action = data.action;
    if (!ADMIN_ACTIONS.has(action)) {
      throw new HttpsError("invalid-argument", "Geçerli bir yönetim işlemi seçin.");
    }
    if (action === "upsert-phone") return upsertPhone(uid, data);
    if (action === "exclude-phone") return excludePhone(uid, data);
    if (action === "restore-phone") return restorePhone(uid, data);
    if (action === "set-visibility") return setVisibility(uid, data);
    if (action === "set-premium") return setPremium(uid, data);
    if (action === "adjust-credits") return adjustCredits(uid, data);
    if (action === "set-trust") return setTrust(uid, data);
    if (action === "set-user-disabled") return setUserDisabled(uid, data);
    if (action === "set-app-config") return setAppConfiguration(uid, data);
    if (action === "bulk-adjust-credits") return bulkAdjustCredits(uid, data);
    if (action === "bulk-set-premium") return bulkSetPremium(uid, data);
    if (action === "send-notification") return sendNotification(uid, data);
    if (["add-tag", "update-tag", "delete-tag"].includes(action)) {
      return mutateTag(uid, action, data);
    }
    if (["add-comment", "update-comment", "delete-comment"].includes(action)) {
      return mutateComment(uid, action, data);
    }
    return resolveNumberReport(uid, data);
  }

  return {query, mutate};
}

module.exports = {
  DEFAULT_APP_CONFIGURATION,
  accountPurchaseSummary,
  countPhoneUsers,
  createAdminService,
  isMissingIndexError,
  isPremiumActive,
  newestFirst,
  publicAppConfiguration,
};
