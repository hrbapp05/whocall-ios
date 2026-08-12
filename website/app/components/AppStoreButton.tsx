"use client";

import type { MouseEvent } from "react";

export function AppStoreButton({ compact = false }: { compact?: boolean }) {
  const appStoreURL = process.env.NEXT_PUBLIC_APP_STORE_URL;

  function handleClick(event: MouseEvent<HTMLAnchorElement>) {
    if (!appStoreURL) {
      event.preventDefault();
      document.getElementById("app-store-notice")?.showPopover();
    }
  }

  return (
    <>
      <a
        className={`app-store-button${compact ? " compact" : ""}`}
        href={appStoreURL || "#app-store"}
        onClick={handleClick}
        target={appStoreURL ? "_blank" : undefined}
        rel={appStoreURL ? "noreferrer" : undefined}
        aria-label="WhoCall'u App Store'dan indir"
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M18.7 12.8c0-3 2.5-4.5 2.6-4.6a5.5 5.5 0 0 0-4.3-2.3c-1.8-.2-3.6 1.1-4.5 1.1-.9 0-2.4-1.1-4-1.1A5.9 5.9 0 0 0 3.6 9c-2.1 3.7-.5 9.1 1.5 12 .9 1.4 2 2.9 3.5 2.8 1.4 0 2-1 3.9-1 1.8 0 2.4 1 3.9 1 1.6 0 2.5-1.4 3.4-2.8a12 12 0 0 0 1.6-3.4 5.2 5.2 0 0 1-2.7-4.8ZM15.8 4a5.2 5.2 0 0 0 1.2-3.8 5.4 5.4 0 0 0-3.6 1.8 5 5 0 0 0-1.3 3.7A4.5 4.5 0 0 0 15.8 4Z" />
        </svg>
        <span>
          <small>App Store’dan</small>
          <strong>İndirin</strong>
        </span>
      </a>
      <div className="app-store-notice" id="app-store-notice" popover="auto">
        <button popoverTarget="app-store-notice" popoverTargetAction="hide" aria-label="Kapat">×</button>
        <strong>Çok yakında App Store’da.</strong>
        <span>WhoCall yayınlandığında indirme bağlantısı burada olacak.</span>
      </div>
    </>
  );
}
