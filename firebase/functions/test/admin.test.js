"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {isMissingIndexError, newestFirst} = require("../admin");

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
