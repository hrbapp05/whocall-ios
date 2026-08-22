import express from "express";
import path from "node:path";
import {fileURLToPath} from "node:url";

const app = express();
const root = path.dirname(fileURLToPath(import.meta.url));
const port = Number(process.env.PORT || 3000);

app.disable("x-powered-by");
app.use((request, response, next) => {
  response.set({
    "Cache-Control": request.path.startsWith("/assets/") ?
      "public, max-age=31536000, immutable" : "no-store",
    "Content-Security-Policy": [
      "default-src 'self'",
      "script-src 'self' https://www.gstatic.com https://www.google.com https://www.recaptcha.net",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https://www.gstatic.com",
      "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.cloudfunctions.net https://identitytoolkit.googleapis.com https://securetoken.googleapis.com",
      "frame-src https://*.firebaseapp.com https://www.google.com https://www.recaptcha.net",
      "font-src 'self' data:",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'none'",
    ].join("; "),
    "Cross-Origin-Opener-Policy": "same-origin-allow-popups",
    "Referrer-Policy": "no-referrer",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  });
  if (process.env.NODE_ENV === "production") {
    response.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  }
  next();
});

app.get("/health", (_request, response) => response.json({status: "ok"}));
app.use(express.static(path.join(root, "dist"), {index: false}));
app.get("*path", (_request, response) => response.sendFile(path.join(root, "dist", "index.html")));

app.listen(port, "0.0.0.0", () => {
  console.log(`WhoCall Admin listening on port ${port}`);
});
