"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  creditAmountForProduct,
  decodeUnverifiedEnvironment,
  verifyAppleCreditTransaction,
} = require("../appleTransactions");

function fakeJWS(environment = "Sandbox") {
  const header = Buffer.from(JSON.stringify({alg: "ES256"})).toString("base64url");
  const payload = Buffer.from(JSON.stringify({environment})).toString("base64url");
  return `${header}.${payload}.${"a".repeat(96)}`;
}

test("maps only WhoCall consumable products to credits", () => {
  assert.equal(creditAmountForProduct("com.levelappstudio.whocall.credits.3"), 3);
  assert.equal(creditAmountForProduct("com.levelappstudio.whocall.credits.5"), 5);
  assert.equal(creditAmountForProduct("com.levelappstudio.whocall.credits.10"), 10);
  assert.equal(creditAmountForProduct("com.levelappstudio.whocall.premium.weekly"), null);
});

test("accepts only App Store production or sandbox environments", () => {
  assert.equal(decodeUnverifiedEnvironment(fakeJWS("Sandbox")), "Sandbox");
  assert.equal(decodeUnverifiedEnvironment(fakeJWS("Production")), "Production");
  assert.equal(decodeUnverifiedEnvironment(fakeJWS("LocalTesting")), null);
  assert.equal(decodeUnverifiedEnvironment("not-a-jws"), null);
});

test("returns credit data only after the signed transaction verifier succeeds", async () => {
  const verifierFactory = (environment) => ({
    verifyAndDecodeTransaction: async () => ({
      environment,
      productId: "com.levelappstudio.whocall.credits.5",
      purchaseDate: 1_700_000_000_000,
      quantity: 1,
      transactionId: "2000000123456789",
      type: "Consumable",
    }),
  });

  const result = await verifyAppleCreditTransaction(fakeJWS(), verifierFactory);

  assert.deepEqual(result, {
    amount: 5,
    environment: "Sandbox",
    productID: "com.levelappstudio.whocall.credits.5",
    purchaseDate: 1_700_000_000_000,
    transactionID: "2000000123456789",
  });
});

test("rejects non-consumable and revoked transactions", async () => {
  const subscriptionVerifier = () => ({
    verifyAndDecodeTransaction: async () => ({
      productId: "com.levelappstudio.whocall.credits.5",
      quantity: 1,
      transactionId: "2000000123456789",
      type: "Auto-Renewable Subscription",
    }),
  });
  await assert.rejects(
      verifyAppleCreditTransaction(fakeJWS(), subscriptionVerifier),
      /invalid-credit-transaction/,
  );

  const revokedVerifier = () => ({
    verifyAndDecodeTransaction: async () => ({
      productId: "com.levelappstudio.whocall.credits.5",
      quantity: 1,
      revocationDate: Date.now(),
      transactionId: "2000000123456789",
      type: "Consumable",
    }),
  });
  await assert.rejects(
      verifyAppleCreditTransaction(fakeJWS(), revokedVerifier),
      /invalid-credit-transaction/,
  );
});
