"use strict";

const {createHmac} = require("node:crypto");

const NAME_PATTERN = /^[\p{L}\p{M}'’.\-]+(?: [\p{L}\p{M}'’.\-]+)*$/u;

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

module.exports = {
  containsBlockedCommunityLanguage,
  keyedDigest,
  normalizeForModeration,
  normalizeName,
  normalizePhone,
};
