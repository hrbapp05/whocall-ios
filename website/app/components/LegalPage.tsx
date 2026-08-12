import Link from "next/link";
import Image from "next/image";
import type { ReactNode } from "react";

export type LegalSection = {
  id: string;
  title: string;
  content: ReactNode;
};

export function LegalPage({
  title,
  intro,
  sections,
}: {
  title: string;
  intro: string;
  sections: LegalSection[];
}) {
  return (
    <main className="legal-shell">
      <header className="legal-header">
        <Link className="brand" href="/">
          <Image src="/assets/whocall-app-icon.png" alt="" width={38} height={38} priority />
          <span>whoCall</span>
        </Link>
        <Link className="legal-back" href="/">← Ana sayfaya dön</Link>
      </header>
      <section className="legal-hero">
        <div>
          <span className="legal-updated">Son güncelleme: 12 Ağustos 2026</span>
          <h1>{title}</h1>
          <p>{intro}</p>
        </div>
      </section>
      <div className="legal-layout">
        <aside className="legal-toc">
          <strong>İçindekiler</strong>
          {sections.map((section) => <a href={`#${section.id}`} key={section.id}>{section.title}</a>)}
        </aside>
        <article className="legal-content">
          {sections.map((section, index) => (
            <section id={section.id} key={section.id}>
              <h2>{index + 1}. {section.title}</h2>
              {section.content}
            </section>
          ))}
        </article>
      </div>
      <footer className="legal-footer">
        <span>© 2026 BLAVI LLC. Tüm hakları saklıdır.</span>
        <a href="mailto:support@levelappstuido.com">support@levelappstuido.com</a>
      </footer>
    </main>
  );
}
