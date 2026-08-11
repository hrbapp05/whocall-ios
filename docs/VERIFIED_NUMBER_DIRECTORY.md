# Doğrulanmış numara dizini

## Amaç

Telefon OTP ile doğrulanan bir WhoCall kullanıcısının numarası başka biri tarafından
sorgulandığında, eski MySQL/API kaydından önce kullanıcının doğrulanmış profil adı
döndürülebilir. Bu bilgi yalnız kullanıcının kendi cihazında tutulursa başka cihazlar
tarafından görülemez; ortak ve güvenilir bir server-side dizin gerekir.

## Kayıt akışı

1. Firebase Phone Auth, kullanıcının numara sahipliğini doğrular.
2. Uygulama ad ve soyadı zorunlu toplar ve Firebase Auth `displayName` alanını günceller.
3. Güvenilir Cloud Function/backend, token içindeki doğrulanmış `phone_number` ile profili eşler.
4. Kullanıcı "Arama sonuçlarında görünürlük" seçeneğini açtıysa dizin kaydı yayınlanır.
5. Client'ın başka bir telefon numarası adına kayıt oluşturmasına izin verilmez.

Önerilen server-side kayıt:

```text
verifiedNumberProfiles/{serverGeneratedID}
  uid
  phoneHmac
  displayName
  isVisible
  verifiedAt
  updatedAt
  schemaVersion
```

Ham telefon numarası public Firestore doküman kimliği yapılmamalıdır. Düz SHA-256 da Türk
GSM numara alanı taranabildiği için yeterli değildir; yalnız server'da bulunan bir secret ile
HMAC üretilmelidir.

## Sorgu önceliği

```text
Girilen numara
  → normalize et
  → kimliği doğrulanmış directory lookup çağrısı
      → görünür, doğrulanmış profil varsa onu döndür
      → yoksa mevcut WhoCall API /api/v1/phone/lookup çağrısına düş
```

Mobil uygulamanın Firestore koleksiyonunu doğrudan taramasına izin verilmemelidir. Callable
Cloud Function veya mevcut backend içinde sınırlı bir lookup endpoint'i; Firebase Auth,
App Check, rate limit ve abuse kontrolleriyle korunmalıdır.

## Apple ile giriş ve zorunlu isim

Sign in with Apple isteği `.fullName` scope'unu istemelidir. Apple isim bilgisini yalnız ilk
yetkilendirmede verir ve kullanıcı istenen scope'u paylaşmayabilir. Bu nedenle Apple'dan gelen
isim ilk fırsatta güvenli profile kaydedilir; isim gelmezse uygulamadaki zorunlu ad/soyad ekranı
tamamlanmadan dizin kaydı yayınlanmaz.

Apple ile giriş telefon numarası sağlamaz. Bir numarayı sahiplenmek isteyen Apple kullanıcısı
ayrıca Phone Auth OTP doğrulamasını tamamlamalı ve Apple credential'ı aynı Firebase kullanıcı
hesabına link edilmelidir.

Apple kaynakları:

- https://developer.apple.com/documentation/authenticationservices/implementing-user-authentication-with-sign-in-with-apple
- https://developer.apple.com/documentation/signinwithapple/authenticating-users-with-sign-in-with-apple

## Rehber ve sistem arama geçmişi

Contacts izni yalnız sorgu sonucunu cihazdaki rehber adıyla eşleştirmek için kullanılır; rehber
sunucuya yüklenmez. iOS 18+ sınırlı kişi erişimi de desteklenir.

iOS public SDK, Telefon uygulamasının hücresel "Son Aramalar" listesini üçüncü taraf
uygulamalara okumak için bir API sağlamaz. CallKit yalnız uygulamanın kendi VoIP çağrılarını
yönetir; Call Directory ise gelen arayanı tanımlama/engelleme kayıtları sağlar. Bu nedenle
dashboard, sistem call log'u yerine gerçek WhoCall sorgu geçmişini gösterir ve izin verilen
rehber kayıtlarıyla isimleri yerel olarak zenginleştirir.

Apple kaynakları:

- https://developer.apple.com/documentation/contacts/accessing-the-contact-store
- https://developer.apple.com/documentation/callkit
- https://developer.apple.com/documentation/callkit/identifying-and-blocking-calls
