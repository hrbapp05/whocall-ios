import Image from "next/image";
import Link from "next/link";
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
    <main className="legal-shell" lang="en">
      <header className="legal-header">
        <Link className="brand" href="/">
          <Image src="/assets/whocall-app-icon.png" alt="" width={38} height={38} priority />
          <span>whoCall</span>
        </Link>
        <Link className="legal-back" href="/">← Back to home</Link>
      </header>
      <section className="legal-hero">
        <div>
          <span className="legal-updated">Last updated: August 19, 2026</span>
          <h1>{title}</h1>
          <p>{intro}</p>
        </div>
      </section>
      <div className="legal-layout">
        <aside className="legal-toc">
          <strong>Contents</strong>
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
        <span>© 2026 BLAVI LLC. All rights reserved.</span>
        <a href="mailto:support@levelappstudio.com">support@levelappstudio.com</a>
      </footer>
    </main>
  );
}
