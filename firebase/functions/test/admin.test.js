"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULT_APP_CONFIGURATION,
  accountPurchaseSummary,
  isMissingIndexError,
  newestFirst,
  publicAppConfiguration,
} = require("../admin");

test("combines purchased and promotional credits without treating the snapshot as an entitlement", () => {
  const updatedAt = new Date("2026-08-30T12:00:00.000Z");
  const summary = accountPurchaseSummary({
    revenueCatAppUserID: "firebase-user-123",
    reportedPurchasedCreditBalance: 23,
    promotionalCreditBalance: 2,
    reportedRevenueCatPremiumActive: false,
    promotionalPremiumActive: true,
    purchaseSnapshotUpdatedAt: {toDate: () => updatedAt},
  });
  assert.deepEqual(summary, {
    revenueCatAppUserID: "firebase-user-123",
    revenueCatPremiumActive: false,
    promotionalPremiumActive: true,
    premiumActive: true,
    purchasedCreditBalance: 23,
    promotionalCreditBalance: 2,
    totalCreditBalance: 25,
    purchaseSnapshotUpdatedAt: updatedAt.toISOString(),
  });
});

test("uses the Firebase UID as the RevenueCat search ID before the first device snapshot", () => {
  const summary = accountPurchaseSummary({}, "firebase-fallback");
  assert.equal(summary.revenueCatAppUserID, "firebase-fallback");
  assert.equal(summary.totalCreditBalance, 0);
  assert.equal(summary.premiumActive, false);
});

test("prefers the server credit ledger over a stale device snapshot", () => {
  const summary = accountPurchaseSummary({
    purchasedCreditBalance: 4,
    reportedPurchasedCreditBalance: 35,
    promotionalCreditBalance: 1,
  });
  assert.equal(summary.purchasedCreditBalance, 4);
  assert.equal(summary.promotionalCreditBalance, 1);
  assert.equal(summary.totalCreditBalance, 5);
});

test("recognizes the production Firestore missing-index response", () => {
  assert.equal(isMissingIndexError({
    code: 9,
    message: "The query requires a COLLECTION_DESC index for collection reports and field updatedAt.",
  }), true);
  assert.equal(isMissingIndexError({code: 9, message: "Transaction failed."}), false);
  assert.equal(isMissingIndexError({code: "permission-denied", message: "Missing index"}), false);
});

test("sorts report records by their newest available timestamp", () => {
  const reports = [
    {id: "older", updatedAt: "2026-08-20T10:00:00.000Z"},
    {id: "created", createdAt: "2026-08-22T09:00:00.000Z"},
    {id: "newer", updatedAt: "2026-08-22T10:00:00.000Z"},
  ];
  assert.deepEqual(reports.sort(newestFirst).map((report) => report.id), [
    "newer",
    "created",
    "older",
  ]);
});

test("uses safe public app configuration defaults", () => {
  assert.deepEqual(publicAppConfiguration(), DEFAULT_APP_CONFIGURATION);
  assert.deepEqual(publicAppConfiguration({
    signupCreditAmount: 5,
    showPostLoginPaywall: false,
  }), {
    signupCreditAmount: 5,
    showPostLoginPaywall: false,
  });
  assert.deepEqual(publicAppConfiguration({
    signupCreditAmount: 500,
    showPostLoginPaywall: "no",
  }), DEFAULT_APP_CONFIGURATION);
});
