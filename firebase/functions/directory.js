"use strict";

const {createHmac} = require("node:crypto");

const NAME_PATTERN = /^[\p{L}\p{M}'’.\-]+(?: [\p{L}\p{M}'’.\-]+)*$/u;

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

module.exports = {keyedDigest, normalizeName, normalizePhone};
