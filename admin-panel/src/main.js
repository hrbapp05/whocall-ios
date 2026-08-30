import "./styles.css";
import "./users.css";
import "./campaigns.css";
import {initializeApp} from "firebase/app";
import {
  RecaptchaVerifier,
  getAuth,
  onAuthStateChanged,
  signInWithPhoneNumber,
  signOut,
} from "firebase/auth";
import {getFunctions, httpsCallable} from "firebase/functions";

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};
const missingConfig = Object.entries(config).filter(([, value]) => !value).map(([key]) => key);
const root = document.querySelector("#app");
const firebase = missingConfig.length ? null : initializeApp(config);
const auth = firebase ? getAuth(firebase) : null;
const functions = firebase ? getFunctions(firebase, "europe-west1") : null;
if (auth) auth.languageCode = "tr";

const state = {
  user: null,
  route: "overview",
  overview: null,
  phoneInput: "",
  phone: null,
  users: null,
  userSearch: "",
  userMembershipFilter: "all",
  userCreditFilter: "all",
  userSort: "joined-desc",
  reports: null,
  reportFilter: "all",
  configuration: null,
  audits: null,
  confirmation: null,
  recaptcha: null,
};

const query = functions ? httpsCallable(functions, "adminQuery") : null;
const mutate = functions ? httpsCallable(functions, "adminMutate") : null;
const moderate = functions ? httpsCallable(functions, "moderateCommunityReport") : null;
const claimInitialAdmin = functions ? httpsCallable(functions, "claimInitialAdmin") : null;

function escapeHTML(value) {
  return String(value ?? "").replace(/[&<>'"]/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;",
  })[character]);
}

function normalizePhone(value) {
  let digits = String(value || "").replace(/\D/g, "");
  if (digits.startsWith("0090")) digits = digits.slice(2);
  if (digits.length === 11 && digits.startsWith("0")) digits = `90${digits.slice(1)}`;
  if (digits.length === 10) digits = `90${digits}`;
  return /^905\d{9}$/.test(digits) ? `+${digits}` : null;
}

function dateTime(value) {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? "—" : new Intl.DateTimeFormat("tr-TR", {
    dateStyle: "medium", timeStyle: "short",
  }).format(date);
}

function showToast(message, kind = "success") {
  const toast = document.createElement("div");
  toast.className = `toast toast-${kind}`;
  toast.textContent = message;
  document.querySelector("#toast-region").append(toast);
  window.setTimeout(() => toast.remove(), 4200);
}

function messageFor(error) {
  const code = error?.code?.replace("functions/", "") || "";
  if (code === "permission-denied") return "Bu işlem için yönetici yetkiniz yok.";
  if (code === "resource-exhausted") return "İşlem sınırına ulaşıldı. Biraz sonra tekrar deneyin.";
  if (code === "unauthenticated") return "Oturumunuz sona erdi. Yeniden giriş yapın.";
  return error?.message?.replace(/^Firebase:\s*/i, "") || "İşlem tamamlanamadı.";
}

async function confirmAction(title, message) {
  const dialog = document.querySelector("#confirm-dialog");
  document.querySelector("#confirm-title").textContent = title;
  document.querySelector("#confirm-message").textContent = message;
  dialog.showModal();
  return new Promise((resolve) => dialog.addEventListener("close", () => {
    resolve(dialog.returnValue === "confirm");
  }, {once: true}));
}

function loginView(message = "") {
  root.innerHTML = `
    <main class="login-shell">
      <section class="login-visual">
        <div class="visual-orbit orbit-one"></div><div class="visual-orbit orbit-two"></div>
        <div class="visual-content">
          <span class="brand-mark brand-mark-large">W</span>
          <p class="eyebrow light">WHOCALL OPERATIONS</p>
          <h1>Topluluğu güvenle yönetin.</h1>
          <p>Numara dizini, üyelik hakları ve moderasyon kararları tek güvenli alanda.</p>
        </div>
      </section>
      <section class="login-panel">
        <div class="login-card">
          <span class="mobile-brand"><span class="brand-mark">W</span> WhoCall</span>
          <p class="eyebrow">YÖNETİCİ GİRİŞİ</p>
          <h2>Telefonunuzla doğrulayın</h2>
          <p class="muted">Yalnızca admin yetkisi tanımlanmış WhoCall hesabı giriş yapabilir.</p>
          ${message ? `<div class="notice notice-error">${escapeHTML(message)}</div>` : ""}
          <form id="phone-login" class="stack">
            <label>Telefon numarası<input id="admin-phone" inputmode="tel" autocomplete="tel" placeholder="05__ ___ __ __" required /></label>
            <button id="send-code-button" class="button button-primary" type="submit">Doğrulama kodu gönder</button>
          </form>
          <form id="otp-login" class="stack hidden">
            <label>6 haneli kod<input id="admin-otp" inputmode="numeric" autocomplete="one-time-code" maxlength="6" placeholder="000000" required /></label>
            <button class="button button-primary" type="submit">Güvenli giriş yap</button>
            <button class="button button-link" id="back-to-phone" type="button">Numarayı değiştir</button>
          </form>
          <p class="login-footnote">Tüm yönetim işlemleri kimlik doğrulamalı ve denetim kayıtlıdır.</p>
        </div>
      </section>
    </main>`;
  bindLogin();
}

function bindLogin() {
  let confirmationResult;
  const phoneForm = document.querySelector("#phone-login");
  const otpForm = document.querySelector("#otp-login");
  phoneForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const phone = normalizePhone(document.querySelector("#admin-phone").value);
    if (!phone) return showToast("Geçerli bir Türkiye GSM numarası girin.", "error");
    const button = phoneForm.querySelector("button");
    button.textContent = "Kod gönderiliyor…";
    try {
      if (state.recaptcha) state.recaptcha.clear();
      state.recaptcha = new RecaptchaVerifier(auth, "send-code-button", {size: "invisible"});
      button.disabled = true;
      confirmationResult = await signInWithPhoneNumber(auth, phone, state.recaptcha);
      phoneForm.classList.add("hidden");
      otpForm.classList.remove("hidden");
      document.querySelector("#admin-otp").focus();
      showToast("Doğrulama kodu gönderildi.");
    } catch (error) {
      showToast(messageFor(error), "error");
      state.recaptcha?.clear();
      state.recaptcha = null;
    } finally {
      button.disabled = false;
      button.textContent = "Doğrulama kodu gönder";
    }
  });
  otpForm?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const code = document.querySelector("#admin-otp").value.replace(/\D/g, "");
    if (code.length !== 6 || !confirmationResult) return showToast("6 haneli kodu girin.", "error");
    const button = otpForm.querySelector("button");
    button.disabled = true;
    try {
      await confirmationResult.confirm(code);
    } catch (error) {
      showToast(messageFor(error), "error");
      button.disabled = false;
    }
  });
  document.querySelector("#back-to-phone")?.addEventListener("click", () => loginView());
}

function navItem(route, label, icon) {
  return `<button class="nav-item ${state.route === route ? "active" : ""}" data-route="${route}">
    <span class="nav-icon">${icon}</span><span>${label}</span>
  </button>`;
}

function shell(content) {
  root.innerHTML = `
    <div class="app-shell">
      <aside class="sidebar">
        <a class="brand" href="#overview"><span class="brand-mark">W</span><span>WhoCall<small>Yönetim</small></span></a>
        <nav>
          ${navItem("overview", "Genel Bakış", "⌂")}
          ${navItem("number", "Numara Yönetimi", "⌕")}
          ${navItem("users", "Kullanıcılar", "♙")}
          ${navItem("reports", "Raporlar", "!")}
          ${navItem("campaigns", "Ayarlar ve Kampanyalar", "✦")}
          ${navItem("audits", "İşlem Geçmişi", "↺")}
        </nav>
        <div class="sidebar-account">
          <span class="avatar">${escapeHTML((state.user?.phoneNumber || "W").slice(-2))}</span>
          <span><strong>Yönetici</strong><small>${escapeHTML(state.user?.phoneNumber || "")}</small></span>
          <button id="sign-out" title="Çıkış yap" aria-label="Çıkış yap">↗</button>
        </div>
      </aside>
      <div class="workspace">
        <header class="topbar">
          <button id="mobile-menu" class="mobile-menu" aria-label="Menüyü aç">☰</button>
          <div><p class="eyebrow">WHOCALL OPERATIONS</p><h1>${routeTitle()}</h1></div>
          <span class="secure-pill"><i></i> Güvenli oturum</span>
        </header>
        <main class="content">${content}</main>
      </div>
    </div>`;
  bindShell();
}

function routeTitle() {
  return ({overview: "Genel Bakış", number: "Numara Yönetimi", users: "Kullanıcılar", reports: "Raporlar", campaigns: "Ayarlar ve Kampanyalar", audits: "İşlem Geçmişi"})[state.route];
}

function bindShell() {
  document.querySelectorAll("[data-route]").forEach((button) => button.addEventListener("click", () => {
    state.route = button.dataset.route;
    window.location.hash = state.route;
    renderRoute();
  }));
  document.querySelector("#sign-out")?.addEventListener("click", () => signOut(auth));
  document.querySelector("#mobile-menu")?.addEventListener("click", () => document.querySelector(".sidebar").classList.toggle("open"));
}

function loadingCards() {
  return `<div class="loading-grid">${Array.from({length: 4}, () => `<div class="skeleton"></div>`).join("")}</div>`;
}

async function renderOverview() {
  shell(state.overview ? overviewContent() : loadingCards());
  bindQuickSearch();
  if (!state.overview) {
    try {
      state.overview = (await query({action: "overview"})).data;
      shell(overviewContent());
      bindQuickSearch();
    } catch (error) { showToast(messageFor(error), "error"); }
  }
}

function overviewContent() {
  const stats = state.overview || {};
  return `
    <section class="hero-card">
      <div><p class="eyebrow light">CANLI DURUM</p><h2>Bugün neyi yönetmek istersiniz?</h2><p>Bir numarayı sorgulayarak profil, üyelik ve topluluk işlemlerine tek yerden ulaşın.</p></div>
      <form id="quick-search" class="hero-search"><input id="quick-phone" inputmode="tel" placeholder="05__ ___ __ __" aria-label="Telefon numarası" /><button class="button button-white">Numarayı aç</button></form>
    </section>
    <section class="stat-grid">
      ${statCard("Dizin profilleri", stats.profiles, "↗", "Doğrulanmış ve yönetilen")}
      ${statCard("Yönetilen hesaplar", stats.managedAccounts, "+", "Premium veya kredi tanımlı")}
      ${statCard("Dizinden çıkarılan", stats.excludedNumbers, "−", "API sonucuna geri düşmez")}
      ${statCard("Bekleyen içerik raporu", stats.pendingContentReports, "!", "Moderasyon kararı bekliyor", true)}
    </section>
    <section class="info-grid">
      <article class="panel"><span class="panel-symbol blue">⌕</span><h3>Numara ve profil</h3><p>Kaydı ekleyin, görünürlüğü değiştirin veya arama sonuçlarından tamamen çıkarın.</p><button class="text-action" data-go="number">Numara yönetimine git →</button></article>
      <article class="panel"><span class="panel-symbol amber">!</span><h3>Topluluk güvenliği</h3><p>Şikâyetleri inceleyin, içeriği kaldırın ve gerektiğinde hesabı askıya alın.</p><button class="text-action" data-go="reports">Raporları incele →</button></article>
      <article class="panel"><span class="panel-symbol violet">✦</span><h3>Kampanyalar</h3><p>Paywall deneyini, başlangıç kredisini, bildirimleri ve toplu hediyeleri yönetin.</p><button class="text-action" data-go="campaigns">Kampanyaları aç →</button></article>
    </section>`;
}

function statCard(label, value, icon, caption, alert = false) {
  return `<article class="stat-card ${alert && Number(value) > 0 ? "attention" : ""}"><span class="stat-icon">${icon}</span><p>${label}</p><strong>${Number(value || 0).toLocaleString("tr-TR")}</strong><small>${caption}</small></article>`;
}

function bindQuickSearch() {
  document.querySelector("#quick-search")?.addEventListener("submit", (event) => {
    event.preventDefault();
    state.phoneInput = document.querySelector("#quick-phone").value;
    state.route = "number";
    window.location.hash = "number";
    renderNumber(true);
  });
  document.querySelectorAll("[data-go]").forEach((button) => button.addEventListener("click", () => {
    state.route = button.dataset.go;
    window.location.hash = state.route;
    renderRoute();
  }));
}

function numberSearchContent() {
  return `<section class="search-panel panel"><div><p class="eyebrow">KAYIT BUL</p><h2>Telefon numarasıyla yönetin</h2><p class="muted">Tam numara yalnızca bu arama sırasında kullanılır; denetim kayıtlarına yazılmaz.</p></div><form id="number-search" class="number-search"><input id="number-input" inputmode="tel" placeholder="05__ ___ __ __" value="${escapeHTML(state.phoneInput)}" required /><button class="button button-primary">Kaydı getir</button></form></section>`;
}

async function renderNumber(autoSearch = false) {
  shell(`${numberSearchContent()}${state.phone ? phoneContent(state.phone) : emptyNumberState()}`);
  bindNumberSearch();
  if (autoSearch && state.phoneInput) await loadPhone(state.phoneInput);
}

function emptyNumberState() {
  return `<section class="empty-state"><span>⌕</span><h3>Bir numara arayın</h3><p>Profil, üyelik, kredi ve topluluk verileri burada açılacak.</p></section>`;
}

async function loadPhone(value) {
  const phone = normalizePhone(value);
  if (!phone) return showToast("Geçerli bir Türkiye GSM numarası girin.", "error");
  state.phoneInput = phone;
  shell(`${numberSearchContent()}${loadingCards()}`);
  bindNumberSearch();
  try {
    state.phone = (await query({action: "phone", phone})).data;
    shell(`${numberSearchContent()}${phoneContent(state.phone)}`);
    bindNumberSearch();
    bindPhoneActions();
  } catch (error) {
    state.phone = null;
    shell(`${numberSearchContent()}${emptyNumberState()}`);
    bindNumberSearch();
    showToast(messageFor(error), "error");
  }
}

function statusBadge(label, active, kind = "default") {
  return `<span class="status status-${active ? "active" : kind}"><i></i>${label}</span>`;
}

function phoneContent(data) {
  const profile = data.profile || {};
  const account = data.account || {};
  const community = data.community || {};
  return `<div class="record-heading"><div><p class="eyebrow">SEÇİLİ NUMARA</p><h2>${escapeHTML(data.phone)}</h2><code>${escapeHTML(data.recordID.slice(0, 15))}…</code></div><div class="badge-row">${statusBadge(data.isExcluded ? "Dizinden çıkarıldı" : profile.isVisible ? "Sorgulamaya açık" : "Sorgulamaya kapalı", !data.isExcluded && profile.isVisible, data.isExcluded ? "danger" : "muted")}${statusBadge(account.registered ? "Kayıtlı üye" : "Henüz üye değil", account.registered, "muted")}</div></div>
    <div class="management-grid">
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">DİZİN KAYDI</p><h3>Profil ve görünürlük</h3></div><span class="panel-symbol blue">◎</span></div>
        <form id="profile-form" class="form-grid"><label>Ad<input name="firstName" value="${escapeHTML(profile.firstName)}" required /></label><label>Soyad<input name="lastName" value="${escapeHTML(profile.lastName)}" required /></label><label class="toggle-row span-two"><span><strong>Sorgulama görünürlüğü</strong><small>Kapalıysa kullanıcıya görünürlük uyarısı gösterilir.</small></span><input name="isVisible" type="checkbox" ${profile.isVisible !== false ? "checked" : ""} /><i></i></label><div class="form-actions span-two"><button class="button button-primary">Kaydı kaydet</button>${data.isExcluded ? `<button class="button button-secondary" type="button" data-action="restore-phone">Dizine geri al</button>` : `<button class="button button-danger-soft" type="button" data-action="exclude-phone">Dizinden çıkar</button>`}</div></form>
      </section>
      <section class="panel"><div class="panel-heading"><div><p class="eyebrow">ÜYELİK</p><h3>Premium durumu</h3></div><span class="panel-symbol violet">★</span></div><div class="membership-state"><strong>${account.premiumActive ? "Aktif" : "Aktif değil"}</strong><small>${account.revenueCatPremiumActive ? "App Store / RevenueCat aboneliği" : account.promotionalPremiumExpiresAt ? `${dateTime(account.promotionalPremiumExpiresAt)} tarihine kadar promosyon` : account.promotionalPremiumActive ? "Süresiz promosyon" : "Etkin abonelik bulunmuyor"}</small></div><form id="premium-form" class="inline-form"><select name="duration"><option value="7-days">7 gün</option><option value="30-days">30 gün</option><option value="lifetime">Süresiz</option></select><button class="button button-primary">Promosyon tanımla</button></form><button class="button button-danger-soft full" data-action="revoke-premium">Promosyonu iptal et</button><p class="fineprint">App Store aboneliği panelden iptal edilmez; yalnızca WhoCall promosyon hakkı yönetilir.</p></section>
      <section class="panel"><div class="panel-heading"><div><p class="eyebrow">KREDİ</p><h3>Toplam kredi</h3></div><span class="panel-symbol cyan">◆</span></div><div class="credit-total"><strong>${Number(account.totalCreditBalance || 0)}</strong><span>kredi</span></div><p class="credit-breakdown">${Number(account.purchasedCreditBalance || 0)} satın alınmış + ${Number(account.promotionalCreditBalance || 0)} promosyon</p><form id="credit-form" class="inline-form"><input name="adjustment" type="number" min="-10000" max="10000" step="1" placeholder="+5 / -2" required /><button class="button button-primary">Uygula</button></form><p class="fineprint">Panel yalnızca promosyon kredisini değiştirir. App Store kredileri sunucuda işlem kimliğiyle tekilleştirilir ve sorgulama sırasında sunucudan düşülür.</p></section>
      <section class="panel"><div class="panel-heading"><div><p class="eyebrow">GÜVEN</p><h3>Profil güven seviyesi</h3></div><span class="panel-symbol green">✓</span></div><form id="trust-form" class="stack"><select name="trustLevel"><option value="automatic" ${!community.trustOverride ? "selected" : ""}>Raporlara göre otomatik</option><option value="high" ${community.trustOverride === "high" ? "selected" : ""}>Yüksek güven</option><option value="medium" ${community.trustOverride === "medium" ? "selected" : ""}>Orta güven</option><option value="risky" ${community.trustOverride === "risky" ? "selected" : ""}>Riskli</option></select><button class="button button-secondary">Güven seviyesini kaydet</button></form><p class="fineprint">Mevcut rapor sayısı: ${Number(community.reportCount || 0)}</p></section>
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">ETİKETLER</p><h3>Topluluk etiketleri</h3></div><span class="count-pill">${(community.tags || []).length}</span></div><div class="tag-list">${(community.tags || []).length ? community.tags.map((tag) => `<span class="tag">${escapeHTML(tag)}<button data-edit-tag="${escapeHTML(tag)}" title="Düzenle">✎</button><button data-delete-tag="${escapeHTML(tag)}" title="Sil">×</button></span>`).join("") : `<p class="muted">Henüz etiket yok.</p>`}</div><form id="tag-form" class="inline-form"><input name="tag" maxlength="24" placeholder="Yeni etiket" required /><button class="button button-primary">Etiket ekle</button></form></section>
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">YORUMLAR</p><h3>Topluluk yorumları</h3></div><span class="count-pill">${(community.comments || []).length}</span></div><div class="comment-list">${(community.comments || []).length ? community.comments.map(commentCard).join("") : `<p class="muted padded">Henüz yorum yok.</p>`}</div><form id="comment-form" class="comment-form"><input type="hidden" name="commentID" /><label>Yazar<input name="author" maxlength="40" value="WhoCall Ekibi" required /></label><label class="span-two">Yorum<textarea name="body" maxlength="500" placeholder="Yorum metni" required></textarea></label><div class="form-actions span-two"><button class="button button-primary"><span id="comment-submit-label">Yorum ekle</span></button><button id="cancel-comment-edit" class="button button-link hidden" type="button">Düzenlemeyi iptal et</button></div></form></section>
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">NUMARA RAPORLARI</p><h3>Bu numara hakkındaki bildirimler</h3></div><span class="count-pill">${(community.reports || []).filter((item) => (item.status || "pending") === "pending").length} bekleyen</span></div>${numberReportTable(community.reports || [], data.recordID)}</section>
    </div>`;
}

function commentCard(comment) {
  return `<article class="comment-card ${comment.isHidden ? "dimmed" : ""}"><div class="comment-avatar">${escapeHTML((comment.author || "W").slice(0, 1).toUpperCase())}</div><div><strong>${escapeHTML(comment.author)}</strong><small>${dateTime(comment.createdAt || comment.updatedAt)}</small><p>${escapeHTML(comment.body)}</p></div><div class="row-actions"><button data-edit-comment="${escapeHTML(comment.id)}" data-author="${escapeHTML(comment.author)}" data-body="${escapeHTML(comment.body)}">Düzenle</button><button class="danger-text" data-delete-comment="${escapeHTML(comment.id)}">Sil</button></div></article>`;
}

function numberReportTable(reports, communityID) {
  if (!reports.length) return `<p class="muted padded">Bu numara hakkında rapor bulunmuyor.</p>`;
  return `<div class="table-wrap"><table><thead><tr><th>Neden</th><th>Durum</th><th>Tarih</th><th>İşlem</th></tr></thead><tbody>${reports.map((report) => `<tr><td>${escapeHTML(report.reason)}</td><td>${statusBadge(report.status || "pending", report.status === "resolved", report.status === "dismissed" ? "muted" : "danger")}</td><td>${dateTime(report.updatedAt || report.createdAt)}</td><td>${(report.status || "pending") === "pending" ? `<button class="table-action" data-number-report="${escapeHTML(report.id)}" data-community="${escapeHTML(communityID)}" data-decision="uphold">Onayla</button><button class="table-action danger-text" data-number-report="${escapeHTML(report.id)}" data-community="${escapeHTML(communityID)}" data-decision="dismiss">Reddet</button>` : escapeHTML(report.decision || "—")}</td></tr>`).join("")}</tbody></table></div>`;
}

function bindNumberSearch() {
  document.querySelector("#number-search")?.addEventListener("submit", (event) => {
    event.preventDefault(); loadPhone(document.querySelector("#number-input").value);
  });
}

async function runMutation(payload, success) {
  try {
    await mutate({...payload, phone: state.phoneInput});
    showToast(success);
    await loadPhone(state.phoneInput);
    state.overview = null;
  } catch (error) { showToast(messageFor(error), "error"); }
}

function bindPhoneActions() {
  document.querySelector("#profile-form")?.addEventListener("submit", (event) => {
    event.preventDefault(); const form = new FormData(event.currentTarget);
    runMutation({action: "upsert-phone", firstName: form.get("firstName"), lastName: form.get("lastName"), isVisible: form.get("isVisible") === "on"}, "Numara kaydı güncellendi.");
  });
  document.querySelector("[data-action='exclude-phone']")?.addEventListener("click", async () => {
    if (await confirmAction("Numarayı dizinden çıkar", "Bu numara uygulama dizininde ve ana API sonucunda bulunamaz görünecek. Devam edilsin mi?")) runMutation({action: "exclude-phone", reason: "Yönetici tarafından dizinden çıkarıldı"}, "Numara dizinden çıkarıldı.");
  });
  document.querySelector("[data-action='restore-phone']")?.addEventListener("click", () => runMutation({action: "restore-phone"}, "Numara yeniden sorgulanabilir duruma alındı."));
  document.querySelector("#premium-form")?.addEventListener("submit", (event) => { event.preventDefault(); const form = new FormData(event.currentTarget); runMutation({action: "set-premium", duration: form.get("duration")}, "Promosyon premium tanımlandı."); });
  document.querySelector("[data-action='revoke-premium']")?.addEventListener("click", async () => { if (await confirmAction("Promosyonu iptal et", "WhoCall tarafından tanımlanan premium hakkı kaldırılacak. Apple aboneliği etkilenmez.")) runMutation({action: "set-premium", duration: "revoke"}, "Promosyon premium kaldırıldı."); });
  document.querySelector("#credit-form")?.addEventListener("submit", (event) => { event.preventDefault(); const adjustment = Number(new FormData(event.currentTarget).get("adjustment")); runMutation({action: "adjust-credits", adjustment}, "Kredi bakiyesi güncellendi."); });
  document.querySelector("#trust-form")?.addEventListener("submit", (event) => { event.preventDefault(); runMutation({action: "set-trust", trustLevel: new FormData(event.currentTarget).get("trustLevel")}, "Güven seviyesi güncellendi."); });
  document.querySelector("#tag-form")?.addEventListener("submit", (event) => { event.preventDefault(); runMutation({action: "add-tag", tag: new FormData(event.currentTarget).get("tag")}, "Etiket eklendi."); });
  document.querySelectorAll("[data-edit-tag]").forEach((button) => button.addEventListener("click", () => { const next = window.prompt("Etiketi düzenle", button.dataset.editTag); if (next && next !== button.dataset.editTag) runMutation({action: "update-tag", currentTag: button.dataset.editTag, tag: next}, "Etiket güncellendi."); }));
  document.querySelectorAll("[data-delete-tag]").forEach((button) => button.addEventListener("click", async () => { if (await confirmAction("Etiketi sil", `“${button.dataset.deleteTag}” etiketi kalıcı olarak silinecek.`)) runMutation({action: "delete-tag", currentTag: button.dataset.deleteTag}, "Etiket silindi."); }));
  const commentForm = document.querySelector("#comment-form");
  commentForm?.addEventListener("submit", (event) => { event.preventDefault(); const form = new FormData(event.currentTarget); const commentID = form.get("commentID"); runMutation({action: commentID ? "update-comment" : "add-comment", commentID, author: form.get("author"), body: form.get("body")}, commentID ? "Yorum güncellendi." : "Yorum eklendi."); });
  document.querySelectorAll("[data-edit-comment]").forEach((button) => button.addEventListener("click", () => { commentForm.elements.commentID.value = button.dataset.editComment; commentForm.elements.author.value = button.dataset.author; commentForm.elements.body.value = button.dataset.body; document.querySelector("#comment-submit-label").textContent = "Yorumu güncelle"; document.querySelector("#cancel-comment-edit").classList.remove("hidden"); commentForm.scrollIntoView({behavior: "smooth", block: "center"}); }));
  document.querySelector("#cancel-comment-edit")?.addEventListener("click", () => { commentForm.reset(); commentForm.elements.commentID.value = ""; document.querySelector("#comment-submit-label").textContent = "Yorum ekle"; document.querySelector("#cancel-comment-edit").classList.add("hidden"); });
  document.querySelectorAll("[data-delete-comment]").forEach((button) => button.addEventListener("click", async () => { if (await confirmAction("Yorumu sil", "Bu yorum kalıcı olarak silinecek.")) runMutation({action: "delete-comment", commentID: button.dataset.deleteComment}, "Yorum silindi."); }));
  document.querySelectorAll("[data-number-report]").forEach((button) => button.addEventListener("click", () => runMutation({action: "resolve-number-report", communityID: button.dataset.community, reportID: button.dataset.numberReport, decision: button.dataset.decision}, "Numara raporu sonuçlandırıldı.")));
}

async function renderUsers() {
  shell(state.users ? usersContent() : loadingCards());
  if (state.users) bindUserActions();
  else await loadUsers(false);
}

async function loadUsers(append) {
  try {
    const result = (await query({
      action: "users",
      limit: 100,
      pageToken: append ? state.users?.nextPageToken : null,
    })).data;
    state.users = {
      items: append ? [...(state.users?.items || []), ...(result.items || [])] : (result.items || []),
      nextPageToken: result.nextPageToken || null,
    };
    shell(usersContent());
    bindUserActions();
  } catch (error) {
    shell(usersContent(true));
    bindUserActions();
    showToast(messageFor(error), "error");
  }
}

function usersContent(loadFailed = false) {
  const items = state.users?.items || [];
  const term = state.userSearch.trim().toLocaleLowerCase("tr-TR");
  const digits = state.userSearch.replace(/\D/g, "");
  const filtered = items.filter((user) => {
    const matchesSearch = !term ||
      user.displayName.toLocaleLowerCase("tr-TR").includes(term) ||
      String(user.revenueCatAppUserID || "").toLocaleLowerCase("tr-TR").includes(term) ||
      (digits && user.phone.replace(/\D/g, "").includes(digits));
    const matchesMembership = state.userMembershipFilter === "all" ||
      (state.userMembershipFilter === "premium" ? user.premiumActive : !user.premiumActive);
    const credits = Number(user.totalCreditBalance || 0);
    const matchesCredits = state.userCreditFilter === "all" ||
      (state.userCreditFilter === "zero" && credits === 0) ||
      (state.userCreditFilter === "1-5" && credits >= 1 && credits <= 5) ||
      (state.userCreditFilter === "6-20" && credits >= 6 && credits <= 20) ||
      (state.userCreditFilter === "21-plus" && credits >= 21);
    return matchesSearch && matchesMembership && matchesCredits;
  }).sort((left, right) => {
    if (state.userSort === "joined-asc") {
      return (Date.parse(left.createdAt || "") || 0) - (Date.parse(right.createdAt || "") || 0);
    }
    if (state.userSort === "credits-desc") {
      return Number(right.totalCreditBalance || 0) - Number(left.totalCreditBalance || 0);
    }
    if (state.userSort === "credits-asc") {
      return Number(left.totalCreditBalance || 0) - Number(right.totalCreditBalance || 0);
    }
    if (state.userSort === "name-asc") {
      return left.displayName.localeCompare(right.displayName, "tr", {sensitivity: "base"});
    }
    if (state.userSort === "last-signin-desc") {
      return (Date.parse(right.lastSignInAt || "") || 0) - (Date.parse(left.lastSignInAt || "") || 0);
    }
    return (Date.parse(right.createdAt || "") || 0) - (Date.parse(left.createdAt || "") || 0);
  });
  const hasFilters = state.userSearch || state.userMembershipFilter !== "all" ||
    state.userCreditFilter !== "all" || state.userSort !== "joined-desc";
  const body = filtered.length ? filtered.map(userRow).join("") : `<tr><td colspan="8"><div class="table-empty"><strong>${loadFailed ? "Kullanıcılar yüklenemedi" : hasFilters ? "Eşleşen kullanıcı bulunamadı" : "Henüz doğrulanmış kullanıcı yok"}</strong><span>${loadFailed ? "Yenile düğmesiyle tekrar deneyin." : "Telefon doğrulaması tamamlanan hesaplar burada görünür."}</span></div></td></tr>`;
  return `<section class="page-intro"><div><p class="eyebrow">DOĞRULANMIŞ HESAPLAR</p><h2>Kullanıcılar</h2><p class="muted">Telefon doğrulamasıyla giriş yapan kullanıcıları görüntüleyin ve hesaplarını yönetin.</p></div><button id="refresh-users" class="button button-secondary">Yenile</button></section>
    <section class="panel users-panel"><form id="user-search" class="users-toolbar"><input name="search" value="${escapeHTML(state.userSearch)}" placeholder="Ad, telefon veya RevenueCat User ID ara" aria-label="Kullanıcı ara" /><button class="button button-primary">Ara</button>${state.userSearch ? `<button id="clear-user-search" class="button button-link" type="button">Aramayı temizle</button>` : ""}<span>${filtered.length} / ${items.length} kullanıcı gösteriliyor</span></form>
      <div class="users-filters">
        <label><span>Abonelik</span><select id="user-membership-filter"><option value="all" ${state.userMembershipFilter === "all" ? "selected" : ""}>Tümü</option><option value="premium" ${state.userMembershipFilter === "premium" ? "selected" : ""}>Premium</option><option value="standard" ${state.userMembershipFilter === "standard" ? "selected" : ""}>Premium değil</option></select></label>
        <label><span>Kredi</span><select id="user-credit-filter"><option value="all" ${state.userCreditFilter === "all" ? "selected" : ""}>Tümü</option><option value="zero" ${state.userCreditFilter === "zero" ? "selected" : ""}>0 kredi</option><option value="1-5" ${state.userCreditFilter === "1-5" ? "selected" : ""}>1–5 kredi</option><option value="6-20" ${state.userCreditFilter === "6-20" ? "selected" : ""}>6–20 kredi</option><option value="21-plus" ${state.userCreditFilter === "21-plus" ? "selected" : ""}>21+ kredi</option></select></label>
        <label><span>Sıralama</span><select id="user-sort"><option value="joined-desc" ${state.userSort === "joined-desc" ? "selected" : ""}>En yeni üyeler</option><option value="joined-asc" ${state.userSort === "joined-asc" ? "selected" : ""}>En eski üyeler</option><option value="credits-desc" ${state.userSort === "credits-desc" ? "selected" : ""}>Kredi: yüksekten düşüğe</option><option value="credits-asc" ${state.userSort === "credits-asc" ? "selected" : ""}>Kredi: düşükten yükseğe</option><option value="last-signin-desc" ${state.userSort === "last-signin-desc" ? "selected" : ""}>Son giriş</option><option value="name-asc" ${state.userSort === "name-asc" ? "selected" : ""}>Ada göre</option></select></label>
        ${hasFilters ? `<button id="clear-user-filters" class="button button-link" type="button">Tüm filtreleri temizle</button>` : ""}
      </div>
      <div class="table-wrap"><table class="users-table"><thead><tr><th>Kullanıcı</th><th>Telefon</th><th>Profil</th><th>Premium</th><th>Kredi</th><th>Son giriş</th><th>Hesap</th><th>İşlem</th></tr></thead><tbody>${body}</tbody></table></div>
      ${state.users?.nextPageToken ? `<div class="load-more"><button id="load-more-users" class="button button-secondary">Daha fazla kullanıcı yükle</button></div>` : ""}
    </section>`;
}

function userRow(user) {
  const premium = user.revenueCatPremiumActive ? "App Store" : user.promotionalPremiumActive ?
    (user.promotionalPremiumExpiresAt ? `Promosyon · ${dateTime(user.promotionalPremiumExpiresAt)}` : "Promosyon · Süresiz") : "Yok";
  return `<tr><td><span class="user-primary"><span class="avatar">${escapeHTML((user.displayName || "W").slice(0, 1).toUpperCase())}</span><span><strong>${escapeHTML(user.displayName)}</strong><small>${dateTime(user.createdAt)} tarihinde katıldı</small><code class="user-id" title="RevenueCat App User ID">RC: ${escapeHTML(user.revenueCatAppUserID || user.uid)}</code></span></span></td><td><strong>${escapeHTML(user.phone)}</strong><small class="user-meta">${escapeHTML(user.phoneMasked)}</small></td><td>${statusBadge(user.profilePublished ? user.isVisible ? "Görünür" : "Gizli" : "Yayınlanmadı", user.profilePublished && user.isVisible, "muted")}</td><td>${escapeHTML(premium)}</td><td><strong>${Number(user.totalCreditBalance || 0)}</strong><small class="credit-breakdown">${Number(user.purchasedCreditBalance || 0)} satın alınmış · ${Number(user.promotionalCreditBalance || 0)} promosyon</small></td><td>${dateTime(user.lastSignInAt)}</td><td>${statusBadge(user.disabled ? "Devre dışı" : "Aktif", !user.disabled, user.disabled ? "danger" : "muted")}</td><td><div class="user-actions"><button class="table-action" data-manage-user="${escapeHTML(user.phone)}">Yönet</button><button class="table-action ${user.disabled ? "" : "danger-text"}" data-user-status="${escapeHTML(user.uid)}" data-disabled="${user.disabled ? "false" : "true"}" data-user-name="${escapeHTML(user.displayName)}">${user.disabled ? "Etkinleştir" : "Devre dışı bırak"}</button></div></td></tr>`;
}

function bindUserActions() {
  document.querySelector("#refresh-users")?.addEventListener("click", () => {
    state.users = null;
    renderUsers();
  });
  document.querySelector("#user-search")?.addEventListener("submit", (event) => {
    event.preventDefault();
    state.userSearch = new FormData(event.currentTarget).get("search") || "";
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#clear-user-search")?.addEventListener("click", () => {
    state.userSearch = "";
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#user-membership-filter")?.addEventListener("change", (event) => {
    state.userMembershipFilter = event.currentTarget.value;
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#user-credit-filter")?.addEventListener("change", (event) => {
    state.userCreditFilter = event.currentTarget.value;
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#user-sort")?.addEventListener("change", (event) => {
    state.userSort = event.currentTarget.value;
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#clear-user-filters")?.addEventListener("click", () => {
    state.userSearch = "";
    state.userMembershipFilter = "all";
    state.userCreditFilter = "all";
    state.userSort = "joined-desc";
    shell(usersContent());
    bindUserActions();
  });
  document.querySelector("#load-more-users")?.addEventListener("click", () => loadUsers(true));
  document.querySelectorAll("[data-manage-user]").forEach((button) => button.addEventListener("click", () => {
    state.phoneInput = button.dataset.manageUser;
    state.phone = null;
    state.route = "number";
    window.location.hash = "number";
    renderNumber(true);
  }));
  document.querySelectorAll("[data-user-status]").forEach((button) => button.addEventListener("click", async () => {
    const disabled = button.dataset.disabled === "true";
    const verb = disabled ? "devre dışı bırakmak" : "yeniden etkinleştirmek";
    if (!await confirmAction("Kullanıcı hesabını güncelle", `${button.dataset.userName} hesabını ${verb} istediğinize emin misiniz?`)) return;
    try {
      await mutate({action: "set-user-disabled", uid: button.dataset.userStatus, disabled});
      showToast(disabled ? "Kullanıcı hesabı devre dışı bırakıldı." : "Kullanıcı hesabı yeniden etkinleştirildi.");
      state.users = null;
      await renderUsers();
    } catch (error) { showToast(messageFor(error), "error"); }
  }));
}

async function renderReports() {
  shell(state.reports ? reportsContent() : loadingCards());
  if (!state.reports) {
    try { state.reports = (await query({action: "reports", limit: 100})).data; shell(reportsContent()); bindReportActions(); }
    catch (error) { showToast(messageFor(error), "error"); }
  } else bindReportActions();
}

function reportsContent() {
  const allContent = state.reports?.content || [];
  const allNumbers = state.reports?.numbers || [];
  const matches = (report) => state.reportFilter === "all" ||
    (state.reportFilter === "pending" && (report.status || "pending") === "pending") ||
    (state.reportFilter === "resolved" && report.status === "resolved") ||
    (state.reportFilter === "dismissed" && report.status === "dismissed");
  const content = allContent.filter(matches);
  const numbers = allNumbers.filter(matches);
  const filterButton = (value, label) => `<button class="filter-chip ${state.reportFilter === value ? "active" : ""}" data-report-filter="${value}">${label}</button>`;
  return `<section class="page-intro"><div><p class="eyebrow">MODERASYON MERKEZİ</p><h2>Topluluk raporları</h2><p class="muted">Kayıtlı üyelerin numarası yalnızca yetkili yöneticiye tam, diğer kayıtlar maskeli gösterilir.</p></div><button id="refresh-reports" class="button button-secondary">Yenile</button></section><div class="filter-row">${filterButton("all", "Tümü")}${filterButton("pending", "Açık / işlem bekleyen")}${filterButton("resolved", "Onaylanan")}${filterButton("dismissed", "Kapanan / reddedilen")}</div><div class="report-layout"><section class="panel"><div class="panel-heading"><div><h3>İçerik şikâyetleri</h3><p class="muted">Yorum ve etiketler</p></div><span class="count-pill">${allContent.filter((item) => item.status === "pending").length} bekleyen</span></div><div class="report-list">${content.length ? content.map(contentReportCard).join("") : `<p class="muted padded">Bu filtrede içerik raporu yok.</p>`}</div></section><section class="panel"><div class="panel-heading"><div><h3>Numara raporları</h3><p class="muted">Spam ve yanlış bilgi bildirimleri</p></div><span class="count-pill">${allNumbers.filter((item) => (item.status || "pending") === "pending").length} bekleyen</span></div><div class="report-list">${numbers.length ? numbers.map(numberReportCard).join("") : `<p class="muted padded">Bu filtrede numara raporu yok.</p>`}</div></section></div>`;
}

function contentReportCard(report) {
  return `<article class="report-card"><div class="report-top"><span class="content-kind">${report.contentType === "comment" ? "Yorum" : "Etiket"}</span>${statusBadge(report.status || "pending", report.status === "resolved", report.status === "dismissed" ? "muted" : "danger")}</div><div class="report-parties"><span><small>Raporlayan</small><strong>${escapeHTML(report.reporterPhone || report.reporterPhoneMasked || "Eski kayıtta bilinmiyor")}</strong></span><span><small>Hedef numara</small><strong>${escapeHTML(report.targetPhone || report.targetPhoneMasked || "Bilinmiyor")}</strong></span></div><blockquote>${escapeHTML(report.contentSnapshot || "İçerik görüntülenemiyor")}</blockquote><p><strong>Neden:</strong> ${escapeHTML(report.reason)}</p><small>${dateTime(report.createdAt)} · Son tarih ${dateTime(report.reviewBy)}</small>${report.status === "pending" ? `<div class="report-actions"><button class="button button-secondary compact" data-content-report="${escapeHTML(report.id)}" data-decision="dismiss">Reddet</button><button class="button button-danger-soft compact" data-content-report="${escapeHTML(report.id)}" data-decision="remove-content">İçeriği kaldır</button><button class="button button-danger compact" data-content-report="${escapeHTML(report.id)}" data-decision="remove-content-and-suspend-user">Kaldır ve hesabı askıya al</button></div>` : `<p class="resolved-note">Karar: ${escapeHTML(report.decision || "—")} · ${dateTime(report.resolvedAt)}</p>`}</article>`;
}

function numberReportCard(report) {
  return `<article class="report-card"><div class="report-top"><code>${escapeHTML(report.communityID.slice(0, 16))}…</code>${statusBadge(report.status || "pending", report.status === "resolved", report.status === "dismissed" ? "muted" : "danger")}</div><div class="report-parties"><span><small>Raporlayan</small><strong>${escapeHTML(report.reporterPhone || report.reporterPhoneMasked || "Eski kayıtta bilinmiyor")}</strong></span><span><small>Raporlanan</small><strong>${escapeHTML(report.targetPhone || report.targetPhoneMasked || "Bilinmiyor")}</strong></span></div><h4>${escapeHTML(report.reason || "Diğer")}</h4><small>${dateTime(report.updatedAt || report.createdAt)}</small>${(report.status || "pending") === "pending" ? `<div class="report-actions"><button class="button button-secondary compact" data-global-number-report="${escapeHTML(report.id)}" data-community="${escapeHTML(report.communityID)}" data-decision="dismiss">Reddet</button><button class="button button-primary compact" data-global-number-report="${escapeHTML(report.id)}" data-community="${escapeHTML(report.communityID)}" data-decision="uphold">Onayla</button></div>` : `<p class="resolved-note">Karar: ${escapeHTML(report.decision || "—")}</p>`}</article>`;
}

function bindReportActions() {
  document.querySelector("#refresh-reports")?.addEventListener("click", () => { state.reports = null; renderReports(); });
  document.querySelectorAll("[data-report-filter]").forEach((button) => button.addEventListener("click", () => {
    state.reportFilter = button.dataset.reportFilter;
    shell(reportsContent());
    bindReportActions();
  }));
  document.querySelectorAll("[data-content-report]").forEach((button) => button.addEventListener("click", async () => {
    try { await moderate({reportID: button.dataset.contentReport, decision: button.dataset.decision}); showToast("İçerik raporu sonuçlandırıldı."); state.reports = null; state.overview = null; renderReports(); }
    catch (error) { showToast(messageFor(error), "error"); }
  }));
  document.querySelectorAll("[data-global-number-report]").forEach((button) => button.addEventListener("click", async () => {
    try { await mutate({action: "resolve-number-report", communityID: button.dataset.community, reportID: button.dataset.globalNumberReport, decision: button.dataset.decision}); showToast("Numara raporu sonuçlandırıldı."); state.reports = null; renderReports(); }
    catch (error) { showToast(messageFor(error), "error"); }
  }));
}

async function renderCampaigns() {
  shell(state.configuration ? campaignsContent() : loadingCards());
  if (!state.configuration) {
    try {
      state.configuration = (await query({action: "app-config"})).data;
      shell(campaignsContent());
      bindCampaignActions();
    } catch (error) { showToast(messageFor(error), "error"); }
  } else bindCampaignActions();
}

function audienceFields(prefix) {
  return `<label>Hedef kitle<select name="audience" data-audience-select="${prefix}"><option value="all">Tüm kullanıcılar</option><option value="single">Tek kullanıcı</option></select></label><label class="hidden" data-audience-phone="${prefix}">Telefon numarası<input name="phone" inputmode="tel" placeholder="05__ ___ __ __" /></label>`;
}

function campaignsContent() {
  const configuration = state.configuration || {};
  return `<section class="page-intro"><div><p class="eyebrow">BÜYÜME VE DENEYLER</p><h2>Ayarlar ve kampanyalar</h2><p class="muted">Yeni kullanıcı deneyimini ve sunucu taraflı promosyonları tek yerden yönetin.</p></div></section>
    <div class="management-grid campaign-grid">
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">UYGULAMA AYARLARI</p><h3>Kayıt sonrası deneyim</h3></div><span class="panel-symbol blue">⚙</span></div><form id="app-config-form" class="form-grid"><label>Yeni kullanıcı başlangıç kredisi<input name="signupCreditAmount" type="number" min="0" max="100" step="1" value="${Number(configuration.signupCreditAmount ?? 1)}" required /></label><label class="toggle-row"><span><strong>Giriş sonrası paywall</strong><small>Premium olmayan kullanıcıya kayıt tamamlanınca gösterilir.</small></span><input name="showPostLoginPaywall" type="checkbox" ${configuration.showPostLoginPaywall !== false ? "checked" : ""} /><i></i></label><div class="form-actions span-two"><button class="button button-primary">Ayarları kaydet</button></div></form><p class="fineprint">Başlangıç kredisi her doğrulanmış numaraya yalnızca bir kez verilir. Miktar değişikliği daha önce hediyesini alan hesapları etkilemez.</p></section>
      <section class="panel"><div class="panel-heading"><div><p class="eyebrow">KREDİ KAMPANYASI</p><h3>Promosyon kredisi gönder</h3></div><span class="panel-symbol cyan">◆</span></div><form id="bulk-credit-form" class="stack">${audienceFields("credit")}<label>Kredi miktarı<input name="amount" type="number" min="1" max="1000" value="1" required /></label><button class="button button-primary">Kredi gönder</button></form></section>
      <section class="panel"><div class="panel-heading"><div><p class="eyebrow">PREMIUM KAMPANYASI</p><h3>Promosyon Premium gönder</h3></div><span class="panel-symbol violet">★</span></div><form id="bulk-premium-form" class="stack">${audienceFields("premium")}<label>Süre<select name="duration"><option value="7-days">7 gün</option><option value="30-days">30 gün</option><option value="lifetime">Süresiz</option></select></label><button class="button button-primary">Premium gönder</button></form></section>
      <section class="panel span-two"><div class="panel-heading"><div><p class="eyebrow">BİLDİRİM</p><h3>Push bildirimi gönder</h3></div><span class="panel-symbol green">↗</span></div><form id="notification-form" class="form-grid">${audienceFields("notification")}<label class="span-two">Başlık<input name="title" maxlength="80" placeholder="WhoCall’dan haber var" required /></label><label class="span-two">Mesaj<textarea name="body" maxlength="240" placeholder="Bildirim metni" required></textarea></label><div class="form-actions span-two"><button class="button button-primary">Bildirimi gönder</button></div></form><p class="fineprint">Yalnızca bildirim izni veren ve geçerli cihaz anahtarı bulunan kullanıcılara ulaşır.</p></section>
    </div>`;
}

function bindAudienceFields() {
  document.querySelectorAll("[data-audience-select]").forEach((select) => {
    const phone = document.querySelector(`[data-audience-phone="${select.dataset.audienceSelect}"]`);
    const sync = () => {
      phone.classList.toggle("hidden", select.value !== "single");
      phone.querySelector("input").required = select.value === "single";
    };
    select.addEventListener("change", sync);
    sync();
  });
}

function campaignPayload(form) {
  const data = new FormData(form);
  return {audience: data.get("audience"), phone: data.get("phone") || null};
}

function bindCampaignActions() {
  bindAudienceFields();
  document.querySelector("#app-config-form")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    try {
      state.configuration = (await mutate({action: "set-app-config", signupCreditAmount: Number(data.get("signupCreditAmount")), showPostLoginPaywall: data.get("showPostLoginPaywall") === "on"})).data;
      showToast("Uygulama ayarları kaydedildi.");
      shell(campaignsContent()); bindCampaignActions();
    } catch (error) { showToast(messageFor(error), "error"); }
  });
  document.querySelector("#bulk-credit-form")?.addEventListener("submit", async (event) => {
    event.preventDefault(); const form = event.currentTarget; const data = new FormData(form); const payload = campaignPayload(form); const amount = Number(data.get("amount"));
    if (!await confirmAction("Kredi kampanyasını gönder", `${payload.audience === "all" ? "Tüm kullanıcılara" : "Seçilen kullanıcıya"} ${amount} kredi gönderilecek. Devam edilsin mi?`)) return;
    try { const result = (await mutate({action: "bulk-adjust-credits", ...payload, amount})).data; showToast(`${result.affectedAccounts} hesaba kredi gönderildi.`); }
    catch (error) { showToast(messageFor(error), "error"); }
  });
  document.querySelector("#bulk-premium-form")?.addEventListener("submit", async (event) => {
    event.preventDefault(); const form = event.currentTarget; const data = new FormData(form); const payload = campaignPayload(form); const duration = data.get("duration");
    if (!await confirmAction("Premium kampanyasını gönder", `${payload.audience === "all" ? "Tüm kullanıcılara" : "Seçilen kullanıcıya"} promosyon Premium tanımlanacak. Devam edilsin mi?`)) return;
    try { const result = (await mutate({action: "bulk-set-premium", ...payload, duration})).data; showToast(`${result.affectedAccounts} hesaba Premium gönderildi.`); }
    catch (error) { showToast(messageFor(error), "error"); }
  });
  document.querySelector("#notification-form")?.addEventListener("submit", async (event) => {
    event.preventDefault(); const form = event.currentTarget; const data = new FormData(form); const payload = campaignPayload(form);
    if (!await confirmAction("Push bildirimini gönder", `${payload.audience === "all" ? "Tüm uygun cihazlara" : "Seçilen kullanıcıya"} bildirim gönderilecek. Bu işlem geri alınamaz.`)) return;
    try { const result = (await mutate({action: "send-notification", ...payload, title: data.get("title"), body: data.get("body")})).data; showToast(`${result.successCount} cihaza bildirim gönderildi${result.failureCount ? `, ${result.failureCount} başarısız` : ""}.`); }
    catch (error) { showToast(messageFor(error), "error"); }
  });
}

async function renderAudits() {
  shell(state.audits ? auditsContent() : loadingCards());
  if (!state.audits) {
    try { state.audits = (await query({action: "audits", limit: 100})).data; shell(auditsContent()); }
    catch (error) { showToast(messageFor(error), "error"); }
  }
}

function auditsContent() {
  return `<section class="page-intro"><div><p class="eyebrow">DENETİM KAYDI</p><h2>Yönetici işlemleri</h2><p class="muted">Telefon numarası veya ad-soyad içermeyen güvenli değişiklik geçmişi.</p></div></section><section class="panel"><div class="timeline">${(state.audits || []).length ? state.audits.map((entry) => `<article class="timeline-item"><span></span><div><strong>${escapeHTML(entry.action)}</strong><p><code>${escapeHTML((entry.targetID || "").slice(0, 18))}…</code></p><small>${dateTime(entry.createdAt)}</small></div><pre>${escapeHTML(JSON.stringify(entry.details || {}, null, 2))}</pre></article>`).join("") : `<p class="muted padded">Henüz yönetici işlemi bulunmuyor.</p>`}</div></section>`;
}

function renderRoute() {
  if (!state.user) return loginView();
  if (state.route === "number") return renderNumber();
  if (state.route === "users") return renderUsers();
  if (state.route === "reports") return renderReports();
  if (state.route === "campaigns") return renderCampaigns();
  if (state.route === "audits") return renderAudits();
  return renderOverview();
}

async function bootstrap() {
  if (missingConfig.length) {
    root.innerHTML = `<main class="fatal"><span class="brand-mark">W</span><h1>Yapılandırma eksik</h1><p>Panelin Firebase web ayarları Railway ortamına eklenmemiş.</p></main>`;
    return;
  }
  state.route = ["overview", "number", "users", "reports", "campaigns", "audits"].includes(location.hash.slice(1)) ? location.hash.slice(1) : "overview";
  onAuthStateChanged(auth, async (user) => {
    if (!user) { state.user = null; loginView(); return; }
    try {
      const token = await user.getIdTokenResult(true);
      if (token.claims.whoCallAdmin !== true && token.claims.communityModerator === true) {
        await claimInitialAdmin({});
        const refreshedToken = await user.getIdTokenResult(true);
        if (refreshedToken.claims.whoCallAdmin === true) {
          state.user = user;
          renderRoute();
          return;
        }
      }
      if (token.claims.whoCallAdmin !== true) {
        await signOut(auth);
        loginView("Bu telefon hesabına WhoCall admin yetkisi tanımlanmamış.");
        return;
      }
      state.user = user;
      renderRoute();
    } catch (error) {
      await signOut(auth);
      loginView(messageFor(error));
    }
  });
  window.addEventListener("hashchange", () => { state.route = location.hash.slice(1) || "overview"; renderRoute(); });
}

bootstrap();
