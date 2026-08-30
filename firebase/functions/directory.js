"use strict";

const {createHmac} = require("node:crypto");

const NAME_PATTERN = /^[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*(?: [\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*)*$/u;
const CURRENT_TERMS_VERSION = "2026-08-19.1";
const CURRENT_PRIVACY_NOTICE_VERSION = "2026-08-12.1";

const COMMUNITY_MODERATION_REASONS = [
  "Küfür, hakaret veya nefret söylemi",
  "Taciz veya tehdit",
  "Kişisel bilgi paylaşımı",
  "Spam veya yanıltıcı içerik",
  "Diğer",
];

const BLOCKED_COMMUNITY_TERMS = [
  "amk", "aq", "orospu", "sik", "siktir", "piç", "pic", "yavşak", "yavsak",
  "şerefsiz", "serefsiz", "gerizekalı", "gerizekali", "salak", "aptal", "ibne",
  "kahpe", "pezevenk", "göt", "got", "bok", "mal",
];

const RESERVED_PROFILE_NAME_TERMS = new Set([
  "admin", "apple", "facebook", "google", "instagram", "meta", "tiktok", "whocall",
  "ad", "isim", "name", "soyad", "soyisim", "surname", "test", "deneme", "demo",
  "fake", "user", "kullanici", "unknown", "bilinmiyor", "yok", "yoktur",
  "abc", "abcd", "asdf", "asdfgh", "qwerty", "qwertyui", "xyz", "zxcv", "zxcvb",
]);

const ADMIN_TRUST_LEVELS = ["high", "medium", "risky"];
const ADMIN_PREMIUM_DURATIONS = ["7-days", "30-days", "lifetime", "revoke"];
const VISIBILITY_REENABLE_COOLDOWN_MILLISECONDS = 12 * 60 * 60 * 1000;

function normalizePhone(value) {
  if (typeof value !== "string") return null;
  let digits = value.replace(/\D/g, "");
  if (digits.startsWith("0090")) digits = digits.slice(2);
  if (digits.length === 11 && digits.startsWith("0")) digits = `90${digits.slice(1)}`;
  if (digits.length === 10) digits = `90${digits}`;
  if (digits.length !== 12 || !digits.startsWith("905")) return null;
  return digits;
}

function normalizeName(value) {
  if (typeof value !== "string") return null;
  const normalized = value.trim().replace(/\s+/g, " ").normalize("NFC");
  const length = Array.from(normalized).length;
  if (length < 2 || length > 40 || !NAME_PATTERN.test(normalized)) return null;
  const moderationValue = normalizeForModeration(normalized);
  const words = moderationValue.split(/\s+/).filter(Boolean);
  const compact = words.join("");
  if (words.some((word) => RESERVED_PROFILE_NAME_TERMS.has(word)) ||
      containsBlockedCommunityLanguage(normalized) ||
      new Set(Array.from(compact)).size < 2 || /(.)\1\1/u.test(compact)) return null;
  return normalized;
}

function namesFromDisplayName(value) {
  if (typeof value !== "string") return null;
  const parts = value.trim().replace(/\s+/g, " ").split(" ");
  if (parts.length < 2) return null;
  const firstName = normalizeName(parts[0]);
  const lastName = normalizeName(parts.slice(1).join(" "));
  return firstName && lastName ? {firstName, lastName} : null;
}

function publicProfileFromAuthUser(user, phoneNumber) {
  if (!user || user.disabled) return null;
  const names = namesFromDisplayName(user.displayName);
  if (!names) return null;
  return {
    phoneNumber,
    displayName: `${names.firstName} ${names.lastName}`,
    firstName: names.firstName,
    lastName: names.lastName,
  };
}

function communityAuthor(value) {
  if (typeof value === "string") {
    const masked = /^(.+) ([\p{L}\p{M}])\.$/u.exec(value.trim());
    const firstName = masked && normalizeName(masked[1]);
    if (firstName) return `${firstName} ${masked[2].toLocaleUpperCase("tr-TR")}.`;
  }
  const names = namesFromDisplayName(value);
  if (!names) return null;
  const surnameInitial = Array.from(names.lastName)[0];
  return surnameInitial ? `${names.firstName} ${surnameInitial}.` : null;
}

function keyedDigest(value, secret) {
  return createHmac("sha256", secret).update(value, "utf8").digest("hex");
}

function normalizeForModeration(value) {
  if (typeof value !== "string") return "";
  return value
      .normalize("NFKD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLocaleLowerCase("tr-TR")
      .replace(/ı/g, "i")
      .replace(/[^a-z0-9]+/g, " ")
      .trim();
}

function containsBlockedCommunityLanguage(value) {
  const normalized = normalizeForModeration(value);
  if (!normalized) return false;
  const compact = normalized.replace(/\s+/g, "");
  const words = normalized.split(/\s+/);
  return BLOCKED_COMMUNITY_TERMS.some((term) => {
    const normalizedTerm = normalizeForModeration(term).replace(/\s+/g, "");
    if (normalizedTerm.length <= 3) return words.includes(normalizedTerm);
    return compact.includes(normalizedTerm);
  });
}

function normalizeCommunityModerationReason(value) {
  if (typeof value !== "string") return null;
  const clean = value.trim().replace(/\s+/g, " ").normalize("NFC");
  return COMMUNITY_MODERATION_REASONS.includes(clean) ? clean : null;
}

function normalizeCommunityContentType(value) {
  return value === "comment" || value === "tag" ? value : null;
}

function normalizeAdminTrustLevel(value) {
  if (value === null || value === "automatic") return null;
  return ADMIN_TRUST_LEVELS.includes(value) ? value : undefined;
}

function normalizeAdminPremiumDuration(value) {
  return ADMIN_PREMIUM_DURATIONS.includes(value) ? value : null;
}

function normalizeCreditAdjustment(value) {
  if (!Number.isSafeInteger(value) || value === 0 || Math.abs(value) > 10_000) return null;
  return value;
}

function profileVisibilityTransition({
  currentIsVisible,
  hideCount,
  lockedUntilMillis,
  requestedIsVisible,
  confirmsCooldown,
  nowMillis,
}) {
  const visible = currentIsVisible !== false;
  const normalizedHideCount = Math.max(
      visible ? 0 : 1,
      Number.isSafeInteger(hideCount) ? hideCount : 0,
  );
  const normalizedLockedUntil = Number.isFinite(lockedUntilMillis) ? lockedUntilMillis : null;

  if (requestedIsVisible === visible) {
    return {
      allowed: true,
      isVisible: visible,
      hideCount: normalizedHideCount,
      lockedUntilMillis: normalizedLockedUntil,
    };
  }

  if (requestedIsVisible === true) {
    if (normalizedLockedUntil && normalizedLockedUntil > nowMillis) {
      return {
        allowed: false,
        reason: "locked",
        isVisible: false,
        hideCount: normalizedHideCount,
        lockedUntilMillis: normalizedLockedUntil,
      };
    }
    return {
      allowed: true,
      isVisible: true,
      hideCount: normalizedHideCount,
      lockedUntilMillis: null,
    };
  }

  const isRepeatHide = normalizedHideCount > 0;
  if (isRepeatHide && confirmsCooldown !== true) {
    return {
      allowed: false,
      reason: "confirmation-required",
      isVisible: true,
      hideCount: normalizedHideCount,
      lockedUntilMillis: null,
    };
  }

  return {
    allowed: true,
    isVisible: false,
    hideCount: normalizedHideCount + 1,
    lockedUntilMillis: isRepeatHide ?
      nowMillis + VISIBILITY_REENABLE_COOLDOWN_MILLISECONDS : null,
  };
}

function maskedPhone(value) {
  const phone = normalizePhone(value);
  return phone ? `+90 5** *** ** ${phone.slice(-2)}` : null;
}

function normalizeLegalAcceptance(value) {
  if (!value || typeof value !== "object") return null;
  if (value.termsVersion !== CURRENT_TERMS_VERSION ||
      value.privacyNoticeVersion !== CURRENT_PRIVACY_NOTICE_VERSION ||
      value.termsAccepted !== true ||
      value.privacyNoticeAcknowledged !== true) return null;
  if (typeof value.appVersion !== "string" || value.appVersion.length < 1 ||
      value.appVersion.length > 40 || typeof value.locale !== "string" ||
      value.locale.length < 2 || value.locale.length > 16) return null;
  return {
    termsVersion: CURRENT_TERMS_VERSION,
    privacyNoticeVersion: CURRENT_PRIVACY_NOTICE_VERSION,
    appVersion: value.appVersion,
    locale: value.locale,
  };
}

module.exports = {
  ADMIN_PREMIUM_DURATIONS,
  ADMIN_TRUST_LEVELS,
  COMMUNITY_MODERATION_REASONS,
  CURRENT_PRIVACY_NOTICE_VERSION,
  CURRENT_TERMS_VERSION,
  containsBlockedCommunityLanguage,
  communityAuthor,
  keyedDigest,
  namesFromDisplayName,
  publicProfileFromAuthUser,
  normalizeForModeration,
  normalizeCommunityContentType,
  normalizeCommunityModerationReason,
  normalizeAdminPremiumDuration,
  normalizeAdminTrustLevel,
  normalizeCreditAdjustment,
  normalizeName,
  normalizePhone,
  normalizeLegalAcceptance,
  maskedPhone,
  profileVisibilityTransition,
  VISIBILITY_REENABLE_COOLDOWN_MILLISECONDS,
};
