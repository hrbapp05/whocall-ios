"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {keyedDigest, normalizeName, normalizePhone} = require("../directory");

test("normalizes supported Turkish mobile formats", () => {
  assert.equal(normalizePhone("+90 506 158 55 98"), "905061585598");
  assert.equal(normalizePhone("05061585598"), "905061585598");
  assert.equal(normalizePhone("5061585598"), "905061585598");
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

test("uses a keyed digest instead of a plain phone hash", () => {
  const first = keyedDigest("905061585598", "secret-one");
  const second = keyedDigest("905061585598", "secret-two");
  assert.equal(first.length, 64);
  assert.notEqual(first, second);
});
