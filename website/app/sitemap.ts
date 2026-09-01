import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  return ["", "/privacy-policy", "/terms-of-use"].map((path) => ({
    url: `https://whocallapp.online${path}`,
    lastModified: new Date("2026-08-12"),
    changeFrequency: path ? "yearly" : "monthly",
    priority: path ? 0.5 : 1,
  }));
}
