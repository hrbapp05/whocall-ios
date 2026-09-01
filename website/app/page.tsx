import Image from "next/image";
import { AppStoreButton } from "./components/AppStoreButton";
import { Reveal } from "./components/Reveal";

const screenshots = [
  { src: "/assets/01-numara-sorgula.png", alt: "WhoCall numara sorgulama ekranı" },
  { src: "/assets/02-son-arayanlar.png", alt: "WhoCall sorgu geçmişi ekranı" },
  { src: "/assets/03-sonucu-ogren.png", alt: "WhoCall numara sorgulanıyor ekranı" },
  { src: "/assets/04-etiketleri-incele.png", alt: "WhoCall topluluk etiketleri ekranı" },
  { src: "/assets/05-topluluk-yorumlari.png", alt: "WhoCall topluluk yorumları ekranı" },
];

const features = [
  {
    number: "01",
    title: "Numarayı sorgula",
    text: "Bilmediğin Türkiye cep telefonu numarasını yaz, sonucu saniyeler içinde gör.",
  },
  {
    number: "02",
    title: "Topluluğu dinle",
    text: "Etiketleri, yorumları ve rapor sayısına göre oluşan güven seviyesini incele.",
  },
  {
    number: "03",
    title: "Daha bilinçli karar ver",
    text: "Soyadı gizlilik için kısaltılmış sonuçlarla aramaya cevap vermeden önce fikir edin.",
  },
];

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="WhoCall ana sayfa">
          <Image src="/assets/whocall-app-icon.png" alt="" width={42} height={42} priority />
          <span>whoCall</span>
        </a>
        <nav aria-label="Ana menü">
          <a href="#nasil-calisir">Nasıl çalışır?</a>
          <a href="#uygulama">Uygulama</a>
          <a href="/privacy-policy">Privacy Policy</a>
          <a href="/terms-of-use">Terms of Use</a>
          <a href="mailto:support@levelappstudio.com">İletişim</a>
        </nav>
        <details className="mobile-menu">
          <summary aria-label="Menüyü aç">Menü</summary>
          <div>
            <a href="#nasil-calisir">Nasıl çalışır?</a>
            <a href="#uygulama">Uygulama</a>
            <a href="/privacy-policy">Privacy Policy</a>
            <a href="/terms-of-use">Terms of Use</a>
          </div>
        </details>
        <AppStoreButton compact />
      </header>

      <section className="hero" id="top">
        <div className="hero-orb hero-orb-one" aria-hidden="true" />
        <div className="hero-orb hero-orb-two" aria-hidden="true" />
        <div className="signal signal-one" aria-hidden="true" />
        <div className="signal signal-two" aria-hidden="true" />

        <div className="hero-copy">
          <p className="eyebrow"><span /> Türkiye’nin numara sorgulama uygulaması</p>
          <h1>
            Arayan kim?<br />
            <span>Anında öğren.</span>
          </h1>
          <p className="hero-lead">
            Bilmediğin numaraları sorgula, topluluğun deneyimini incele ve telefona
            cevap vermeden önce bir adım önde ol.
          </p>
          <div className="hero-actions">
            <AppStoreButton />
            <a className="text-link" href="#nasil-calisir">
              Nasıl çalıştığını gör <span aria-hidden="true">↓</span>
            </a>
          </div>
          <div className="trust-row" aria-label="WhoCall özellikleri">
            <span>Türkiye’ye özel</span>
            <span>Gizlilik odaklı</span>
            <span>Topluluk destekli</span>
          </div>
        </div>

        <div className="hero-visual" aria-label="WhoCall uygulamasından bir görünüm">
          <div className="floating-pill pill-left">Numara doğrulandı <b>✓</b></div>
          <div className="floating-pill pill-right"><b>Güvenli</b> görünüm</div>
          <div className="phone-mockup">
            <span className="phone-button phone-button-action" aria-hidden="true" />
            <span className="phone-button phone-button-volume-up" aria-hidden="true" />
            <span className="phone-button phone-button-volume-down" aria-hidden="true" />
            <div className="phone-screen">
              <Image
                src="/assets/hero-app-screen.png"
                alt="WhoCall uygulamasında numara sorgulanıyor ekranı"
                width={1206}
                height={2622}
                priority
                sizes="(max-width: 620px) 285px, 350px"
              />
            </div>
          </div>
          <div className="hero-icon">
            <Image src="/assets/whocall-app-icon.png" alt="WhoCall uygulama ikonu" width={132} height={132} priority />
          </div>
        </div>

        <a className="scroll-cue" href="#nasil-calisir" aria-label="Aşağı kaydır">
          <span />
        </a>
      </section>

      <section className="steps section" id="nasil-calisir">
        <Reveal className="section-heading">
          <p className="eyebrow dark"><span /> Karmaşayı azalt</p>
          <h2>Bir numaradan<br />daha fazlasını gör.</h2>
          <p>WhoCall, arayan hakkında elindeki sinyalleri tek ve anlaşılır bir yerde toplar.</p>
        </Reveal>
        <div className="feature-grid">
          {features.map((feature, index) => (
            <Reveal className="feature-card" delay={index * 90} key={feature.number}>
              <div className="feature-number">{feature.number}</div>
              <h3>{feature.title}</h3>
              <p>{feature.text}</p>
              <div className={`feature-mark mark-${index + 1}`} aria-hidden="true">
                {index === 0 ? "⌕" : index === 1 ? "✦" : "✓"}
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="showcase section" id="uygulama">
        <Reveal className="showcase-copy">
          <p className="eyebrow"><span /> Tasarımı kadar hızlı</p>
          <h2>Merak ettiğin cevap,<br />birkaç dokunuş uzağında.</h2>
          <p>
            Sorgu geçmişinden topluluk yorumlarına kadar ihtiyacın olan her şey,
            sade ve akıcı bir deneyimde.
          </p>
          <AppStoreButton />
        </Reveal>
        <div className="screenshot-rail" aria-label="WhoCall uygulama ekranları">
          {screenshots.map((shot, index) => (
            <Reveal className={`store-shot shot-${index + 1}`} delay={index * 75} key={shot.src}>
              <Image src={shot.src} alt={shot.alt} width={1320} height={2868} loading={index > 1 ? "lazy" : "eager"} sizes="(max-width: 620px) 235px, (max-width: 980px) 280px, 20vw" />
            </Reveal>
          ))}
        </div>
      </section>

      <section className="privacy-highlight section">
        <Reveal className="privacy-card">
          <div className="privacy-symbol" aria-hidden="true">W</div>
          <div>
            <p className="eyebrow"><span /> Gizlilik varsayılan</p>
            <h2>Bilgi verir,<br />fazlasını göstermez.</h2>
          </div>
          <p>
            Arama sonuçlarında soyadının yalnızca baş harfi gösterilir. Kendi doğrulanmış
            numaranın görünürlüğünü dilediğinde yönetebilirsin.
          </p>
          <a className="outline-link" href="/privacy-policy">Gizlilik yaklaşımımız</a>
        </Reveal>
      </section>

      <section className="final-cta section">
        <div className="final-glow" aria-hidden="true" />
        <Reveal>
          <Image className="cta-icon" src="/assets/whocall-app-icon.png" alt="WhoCall" width={145} height={145} />
          <p className="eyebrow centered"><span /> Şimdi App Store’da</p>
          <h2>Bilinmeyen numaralara<br />karşı bir adım önde.</h2>
          <p>WhoCall’u indir, arayanı daha bilinçli değerlendir.</p>
          <AppStoreButton />
        </Reveal>
      </section>

      <footer>
        <div className="footer-brand">
          <a className="brand inverse" href="#top">
            <Image src="/assets/whocall-app-icon.png" alt="" width={44} height={44} />
            <span>whoCall</span>
          </a>
          <p>Numarayı sorgula. Arayanı anında öğren.</p>
        </div>
        <div className="footer-links">
          <div>
            <h3>WhoCall</h3>
            <a href="#nasil-calisir">Nasıl çalışır?</a>
            <a href="#uygulama">Uygulama</a>
            <AppStoreButton compact />
          </div>
          <div>
            <h3>Yasal</h3>
            <a href="/privacy-policy">Privacy Policy</a>
            <a href="/terms-of-use">Terms of Use</a>
          </div>
          <div>
            <h3>İletişim</h3>
            <a href="mailto:support@levelappstudio.com">support@levelappstudio.com</a>
          </div>
        </div>
        <div className="footer-bottom">
          <span>© 2026 BLAVI LLC. Tüm hakları saklıdır.</span>
          <span>Türkiye için tasarlandı.</span>
        </div>
      </footer>
    </main>
  );
}
