import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

async function render(path) {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${path}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const response = await worker.fetch(
    new Request(`https://whocall.test${path}`, { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
  assert.equal(response.status, 200);
  return response.text();
}

test("landing page includes product copy and legal links", async () => {
  const html = await render("/");
  assert.match(html, /Arayan kim\?/);
  assert.match(html, /App Store/);
  assert.match(html, /\/privacy-policy/);
  assert.match(html, /\/terms-of-use/);
  assert.match(html, /support@levelappstuido\.com/);
});

test("privacy policy describes actual app data practices", async () => {
  const html = await render("/privacy-policy");
  assert.match(html, /Privacy Policy/);
  assert.match(html, /Firebase/);
  assert.match(html, /RevenueCat/);
  assert.match(html, /does not request access to your address book/);
});

test("terms page covers subscriptions and community use", async () => {
  const html = await render("/terms-of-use");
  assert.match(html, /Terms of Use/);
  assert.match(html, /Premium subscriptions/);
  assert.match(html, /Community content/);
  assert.match(html, /Standard Licensed Application End User License Agreement/);
});

test("social card is the required preview size", async () => {
  const image = await readFile(new URL("../public/og.png", import.meta.url));
  assert.equal(image.toString("ascii", 1, 4), "PNG");
  assert.equal(image.readUInt32BE(16), 1200);
  assert.equal(image.readUInt32BE(20), 630);
});
