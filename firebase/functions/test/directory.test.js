"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  communityAuthor,
  containsBlockedCommunityLanguage,
  keyedDigest,
  namesFromDisplayName,
  maskedPhone,
  normalizeAdminPremiumDuration,
  normalizeAdminTrustLevel,
  normalizeCreditAdjustment,
  normalizeCommunityContentType,
  normalizeCommunityModerationReason,
  normalizeLegalAcceptance,
  normalizeName,
  normalizePhone,
  publicProfileFromAuthUser,
} = require("../directory");

test("normalizes supported Turkish mobile formats", () => {
  assert.equal(normalizePhone("+90 500 000 00 00"), "905000000000");
  assert.equal(normalizePhone("05000000000"), "905000000000");
  assert.equal(normalizePhone("5000000000"), "905000000000");
});

test("validates admin account adjustments without accepting arbitrary values", () => {
  assert.equal(normalizeAdminTrustLevel("high"), "high");
  assert.equal(normalizeAdminTrustLevel("automatic"), null);
  assert.equal(normalizeAdminTrustLevel("unknown"), undefined);
  assert.equal(normalizeAdminPremiumDuration("30-days"), "30-days");
  assert.equal(normalizeAdminPremiumDuration("forever"), null);
  assert.equal(normalizeCreditAdjustment(5), 5);
  assert.equal(normalizeCreditAdjustment(-3), -3);
  assert.equal(normalizeCreditAdjustment(0), null);
  assert.equal(normalizeCreditAdjustment(10_001), null);
  assert.equal(maskedPhone("0506 158 55 98"), "+90 5** *** ** 98");
});

test("rejects invalid and non-mobile numbers", () => {
  assert.equal(normalizePhone("2121234567"), null);
  assert.equal(normalizePhone("506123"), null);
});

test("accepts Turkish names and rejects markup", () => {
  assert.equal(normalizeName("  Göktuğ  "), "Göktuğ");
  assert.equal(normalizeName("Nur-Su"), "Nur-Su");
  assert.equal(normalizeName("<script>"), null);
  assert.equal(normalizeName(""), null);
  assert.equal(normalizeName("S."), null);
  assert.equal(normalizeName("Ali123"), null);
  assert.equal(normalizeName("Test"), null);
  assert.equal(normalizeName("WhoCall"), null);
  assert.equal(normalizeName("Şerefsiz"), null);
  assert.equal(normalizeName("Aaaaa"), null);
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

test("masks the community author without an Auth Admin lookup", () => {
  assert.equal(communityAuthor("Göktuğ Solmaz"), "Göktuğ S.");
  assert.equal(communityAuthor("Göktuğ S."), "Göktuğ S.");
  assert.equal(communityAuthor("TekAd"), null);
});

test("builds a public lookup owner from a verified Firebase Auth user", () => {
  assert.deepEqual(
      publicProfileFromAuthUser({displayName: "Göktuğ Solmaz", disabled: false}, "905061585598"),
      {
        phoneNumber: "905061585598",
        displayName: "Göktuğ Solmaz",
        firstName: "Göktuğ",
        lastName: "Solmaz",
      },
  );
  assert.equal(
      publicProfileFromAuthUser({displayName: "Göktuğ Solmaz", disabled: true}, "905061585598"),
      null,
  );
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

test("accepts only supported community moderation requests", () => {
  assert.equal(
      normalizeCommunityModerationReason("  Taciz veya tehdit  "),
      "Taciz veya tehdit",
  );
  assert.equal(normalizeCommunityModerationReason("Beğenmedim"), null);
  assert.equal(normalizeCommunityContentType("comment"), "comment");
  assert.equal(normalizeCommunityContentType("tag"), "tag");
  assert.equal(normalizeCommunityContentType("profile"), null);
});

test("accepts only the current, separately acknowledged legal documents", () => {
  assert.deepEqual(normalizeLegalAcceptance({
    termsVersion: "2026-08-19.1",
    privacyNoticeVersion: "2026-08-12.1",
    termsAccepted: true,
    privacyNoticeAcknowledged: true,
    appVersion: "1.0 (25)",
    locale: "tr-TR",
  }), {
    termsVersion: "2026-08-19.1",
    privacyNoticeVersion: "2026-08-12.1",
    appVersion: "1.0 (25)",
    locale: "tr-TR",
  });
  assert.equal(normalizeLegalAcceptance({
    termsVersion: "old",
    privacyNoticeVersion: "2026-08-12.1",
    termsAccepted: true,
    privacyNoticeAcknowledged: true,
    appVersion: "1.0",
    locale: "tr-TR",
  }), null);
});
