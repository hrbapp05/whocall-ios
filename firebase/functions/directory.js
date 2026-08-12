"use strict";

const {createHmac} = require("node:crypto");

const NAME_PATTERN = /^[\p{L}\p{M}'’.\-]+(?: [\p{L}\p{M}'’.\-]+)*$/u;
const CURRENT_TERMS_VERSION = "2026-08-12.1";
const CURRENT_PRIVACY_NOTICE_VERSION = "2026-08-12.1";

const BLOCKED_COMMUNITY_TERMS = [
  "amk", "aq", "orospu", "sik", "siktir", "piç", "pic", "yavşak", "yavsak",
  "şerefsiz", "serefsiz", "gerizekalı", "gerizekali", "salak", "aptal", "ibne",
  "kahpe", "pezevenk", "göt", "got", "bok", "mal",
];

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
  CURRENT_PRIVACY_NOTICE_VERSION,
  CURRENT_TERMS_VERSION,
  containsBlockedCommunityLanguage,
  keyedDigest,
  namesFromDisplayName,
  publicProfileFromAuthUser,
  normalizeForModeration,
  normalizeName,
  normalizePhone,
  normalizeLegalAcceptance,
};
