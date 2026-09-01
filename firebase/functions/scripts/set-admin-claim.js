"use strict";

const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {normalizePhone} = require("../directory");

async function main() {
  const phoneArgument = process.argv.find((value) => value.startsWith("--phone="));
  const phone = normalizePhone(phoneArgument && phoneArgument.slice("--phone=".length));
  if (!phone) throw new Error("Use --phone with a valid Turkish mobile number.");

  initializeApp({credential: applicationDefault()});
  const auth = getAuth();
  const user = await auth.getUserByPhoneNumber(`+${phone}`);
  await auth.setCustomUserClaims(user.uid, {
    ...user.customClaims,
    whoCallAdmin: true,
    communityModerator: true,
  });
  process.stdout.write(`Admin role granted to Firebase user …${user.uid.slice(-6)}.\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
});
