# WhoCall yönetim paneli

WhoCall Admin, Railway üzerinde statik web arayüzü olarak çalışır. Tarayıcı Firebase telefon doğrulamasıyla oturum açar; tüm veriler Firebase callable işlevleri üzerinden okunur ve yazılır. Railway üzerinde Firebase servis hesabı, HMAC anahtarı veya API secret tutulmaz.

## Yetki ve güvenlik

- Her yönetim isteği sunucuda `whoCallAdmin: true` custom claim ile doğrulanır.
- İlk yönetici yalnızca mevcut `communityModerator` hesabı tarafından bir kez sahiplenilebilir. Sonraki yönetici atamaları güvenilir yönetim ortamından yapılmalıdır.
- Tam telefon numarası denetim kayıtlarına yazılmaz. Firestore belge kimlikleri sunucu secret'ı ile HMAC kullanılarak üretilir.
- Kritik işlemler onay penceresi ister ve `adminAuditLogs` koleksiyonuna kaydedilir.
- Railway projesi özel tutulur; panel public URL üzerinden erişilebilir olsa da yetkisiz kullanıcı veri okuyamaz veya işlem yapamaz.

## Yönetilebilen alanlar

- Uygulama dizinine numara/profil ekleme ve güncelleme
- Numarayı aramaya açık/kapalı yapma veya dizinden tamamen çıkarma
- Telefon numarasına promosyon Premium tanımlama/iptal etme
- Promosyon kredisi ekleme/eksiltme
- Güven seviyesini otomatik, yüksek, orta veya riskli olarak belirleme
- Etiket ve yorum ekleme, düzenleme, silme
- Numara ve içerik raporlarını inceleme; onaylama veya reddetme
- Yönetim işlem geçmişini görüntüleme

## Ürün sınırları

Paneldeki Premium ve kredi işlemleri WhoCall'ın sunucu tarafı promosyon haklarıdır. App Store/RevenueCat aboneliği panelden iptal edilmez ve kullanıcının satın aldığı tüketilebilir krediler değiştirilmez. Bu ayrım Apple satın alma kayıtlarının doğruluğunu korur.

97,8 milyon kayıtlı canlı API yalnızca arama sözleşmesi sunduğundan, panelde eklenen veya çıkarılan kayıtlar Firebase uygulama dizini katmanında yönetilir. Uygulama önce bu katmanı kontrol eder; yönetici tarafından çıkarılan numara ana API'ye geri düşmez.

## Railway kurulumu

Servis kök dizini `admin-panel`, Dockerfile yolu `Dockerfile`, sağlık kontrolü `/health` olmalıdır. Derleme için Firebase Web App'in herkese açık dört değişkeni gerekir:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_APP_ID`

Üretim alan adı Firebase Authentication yetkili alan adlarına eklenmelidir.
