import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";

const geist = Geist({ variable: "--font-geist", subsets: ["latin"] });

export const metadata: Metadata = {
  metadataBase: new URL("https://whocallapp.online"),
  title: {
    default: "WhoCall — Numarayı sorgula, arayanı anında öğren",
    template: "%s | WhoCall",
  },
  description:
    "Bilinmeyen Türkiye cep telefonu numaralarını sorgula; topluluk etiketleri, yorumları ve güven seviyesiyle arayan hakkında fikir edin.",
  keywords: ["numara sorgulama", "arayan kim", "telefon", "spam", "bilinmeyen numara"],
  alternates: { canonical: "/" },
  openGraph: {
    title: "WhoCall — Bilinmeyen numaralara karşı bir adım önde",
    description: "Numarayı sorgula, arayanı anında öğren.",
    url: "/",
    siteName: "WhoCall",
    locale: "tr_TR",
    type: "website",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "WhoCall" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "WhoCall",
    description: "Bilinmeyen numaralara karşı bir adım önde.",
    images: ["/og.png"],
  },
  icons: { icon: "/assets/whocall-app-icon.png", apple: "/assets/whocall-app-icon.png" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr">
      <body className={geist.variable}>{children}</body>
    </html>
  );
}
