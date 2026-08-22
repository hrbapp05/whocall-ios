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
} = require("./directory");

const PHONE_ID_PATTERN = /^v1_[a-f0-9]{64}$/;
const DOCUMENT_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
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
]);

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

function createAdminService({db, auth, FieldValue, Timestamp, HttpsError, hmacKey}) {
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

  async function phoneDetails(rawPhone) {
    const context = contextForPhone(rawPhone);
    const [profile, exclusion, benefits, community, comments, numberReports] = await Promise.all([
      context.profile.get(),
      context.exclusion.get(),
      context.benefits.get(),
      context.community.get(),
      context.community.collection("comments").orderBy("createdAt", "desc").limit(100).get(),
      context.community.collection("reports").orderBy("updatedAt", "desc").limit(100).get(),
    ]);
    let authUser = null;
    try {
      const user = await auth.getUserByPhoneNumber(`+${context.phone}`);
      authUser = {
        registered: true,
        disabled: user.disabled,
        displayName: user.displayName || null,
      };
    } catch (error) {
      if (!error || error.code !== "auth/user-not-found") throw error;
      authUser = {registered: false, disabled: false, displayName: null};
    }
    const benefitData = benefits.data() || {};
    const communityData = community.data() || {};
    return {
      phone: context.masked,
      recordID: context.id,
      profile: profile.exists ? publicProfile(profile.data()) : null,
      isExcluded: exclusion.exists && exclusion.data().active === true,
      account: {
        ...authUser,
        promotionalPremiumActive: isPremiumActive(benefitData),
        promotionalPremiumExpiresAt: serializeTimestamp(benefitData.promotionalPremiumExpiresAt),
        promotionalCreditBalance: Math.max(0, Number(benefitData.promotionalCreditBalance || 0)),
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
        reports: numberReports.docs.map(serializeDocument).map((report) => ({
          id: report.id,
          reason: report.reason || "Diğer",
          status: report.status || "pending",
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
          decision: report.decision || null,
        })),
      },
    };
  }

  async function reports(limit) {
    const safeLimit = Math.min(100, Math.max(10, Number(limit) || 50));
    const [content, numberReports] = await Promise.all([
      db.collection("communityModerationReports")
          .orderBy("lastReportedAt", "desc").limit(safeLimit).get(),
      db.collectionGroup("reports").orderBy("updatedAt", "desc").limit(safeLimit).get(),
    ]);
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
          status: report.status || "pending",
          decision: report.decision || null,
          createdAt: report.createdAt,
          updatedAt: report.updatedAt,
        };
      }),
    };
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
    if (action === "reports") return reports(request.data.limit);
    if (action === "audits") return audits(request.data.limit);
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

module.exports = {createAdminService, isPremiumActive};
