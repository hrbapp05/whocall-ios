"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  containsBlockedCommunityLanguage,
  keyedDigest,
  namesFromDisplayName,
  normalizeName,
  normalizePhone,
} = require("../directory");

test("normalizes supported Turkish mobile formats", () => {
  assert.equal(normalizePhone("+90 500 000 00 00"), "905000000000");
  assert.equal(normalizePhone("05000000000"), "905000000000");
  assert.equal(normalizePhone("5000000000"), "905000000000");
});

test("rejects invalid and non-mobile numbers", () => {
  assert.equal(normalizePhone("2121234567"), null);
  assert.equal(normalizePhone("506123"), null);
});

test("accepts Turkish names and rejects markup", () => {
  assert.equal(normalizeName("  Göktuğ  "), "Göktuğ");
  assert.equal(normalizeName("Nur-Su"), "Nur-Su");
  assert.equal(normalizeName("<script>"), null);
});

test("splits a verified display name for lazy directory publication", () => {
  assert.deepEqual(namesFromDisplayName(" Göktuğ Solmaz "), {
    firstName: "Göktuğ",
    lastName: "Solmaz",
  });
  assert.deepEqual(namesFromDisplayName("Ayşe Nur Yılmaz"), {
    firstName: "Ayşe",
    lastName: "Nur Yılmaz",
  });
  assert.equal(namesFromDisplayName("Tekad"), null);
});

test("uses a keyed digest instead of a plain phone hash", () => {
  const first = keyedDigest("905000000000", "secret-one");
  const second = keyedDigest("905000000000", "secret-two");
  assert.equal(first.length, 64);
  assert.notEqual(first, second);
});

test("blocks Turkish insults despite spacing and casing", () => {
  assert.equal(containsBlockedCommunityLanguage("ŞEREFSİZ arayan"), true);
  assert.equal(containsBlockedCommunityLanguage("s i k t i r"), true);
  assert.equal(containsBlockedCommunityLanguage("Güvenilir tesisatçı"), false);
});
