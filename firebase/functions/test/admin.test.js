"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULT_APP_CONFIGURATION,
  accountPurchaseSummary,
  countPhoneUsers,
  isMissingIndexError,
  listPhoneUsersNewest,
  newestFirst,
  publicAppConfiguration,
} = require("../admin");

test("counts only phone-verified users across every Firebase Auth page", async () => {
  const requestedPages = [];
  const auth = {
    async listUsers(limit, pageToken) {
      requestedPages.push({limit, pageToken});
      return {
        users: [
          {phoneNumber: "+905551112233"},
          {email: "email-only@example.com"},
        ],
        pageToken: null,
      };
    },
  };
  const total = await countPhoneUsers(auth, {
    users: [
      {phoneNumber: "+905555555555"},
      {phoneNumber: "invalid"},
    ],
    pageToken: "page-2",
  });
  assert.equal(total, 2);
  assert.deepEqual(requestedPages, [{limit: 1000, pageToken: "page-2"}]);
});

test("lists all phone users with the newest Firebase Auth member first", async () => {
  const requestedPages = [];
  const auth = {
    async listUsers(limit, pageToken) {
      requestedPages.push({limit, pageToken});
      if (!pageToken) {
        return {
          users: [
            {
              uid: "older",
              phoneNumber: "+905551112233",
              metadata: {creationTime: "2026-08-20T09:00:00.000Z"},
            },
            {uid: "email-only", email: "email-only@example.com"},
          ],
          pageToken: "page-2",
        };
      }
      return {
        users: [{
          uid: "newer",
          phoneNumber: "+905555555555",
          metadata: {creationTime: "2026-08-31T12:00:00.000Z"},
        }],
        pageToken: null,
      };
    },
  };

  const users = await listPhoneUsersNewest(auth);

  assert.deepEqual(users.map(({user}) => user.uid), ["newer", "older"]);
  assert.deepEqual(requestedPages, [
    {limit: 1000, pageToken: undefined},
    {limit: 1000, pageToken: "page-2"},
  ]);
});

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
