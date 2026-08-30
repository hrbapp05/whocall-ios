# WhoCall Admin

Railway üzerinde çalışan yönetim arayüzüdür. Tarayıcı yalnızca Firebase Authentication ile giriş yapar; tüm okuma ve yazma işlemleri `adminQuery`, `adminMutate` ve moderasyon callable işlevleri üzerinden sunucuda yetkilendirilir.

## Yetki modeli

- Giriş yapan Firebase kullanıcısında `whoCallAdmin: true` custom claim bulunmalıdır.
- İçerik moderasyonu için aynı claim kabul edilir; mevcut `communityModerator` yetkisi korunur.
- Telefon numarası denetim kayıtlarına yazılmaz. Kayıt kimliği anahtarlı HMAC ile oluşturulur.
- Panel promosyon premium ve promosyon kredisi yönetir. App Store aboneliğini iptal etmez ve satın alınmış tüketilebilir krediyi değiştirmez; uygulamadan gelen son satın alma özeti yalnızca görüntülenir.
- `Kullanıcılar` ekranı yalnızca telefon doğrulaması tamamlanmış Firebase Authentication hesaplarını listeler. Ad, telefon veya RevenueCat App User ID ile arama; abonelik/kredi filtresi ve üyelik tarihi/kredi/son giriş sıralaması sağlar. Tam numara yalnızca yetkili admin oturumuna döner.
- Kullanıcı hesabı bu ekrandan geçici olarak devre dışı bırakılabilir veya yeniden etkinleştirilebilir; diğer profil ve hak işlemleri `Yönet` düğmesiyle numara ekranında açılır.
- `Ayarlar ve Kampanyalar` ekranından başlangıç kredisi, kayıt sonrası paywall, tekil/toplu promosyon kredi, promosyon Premium ve push bildirimleri yönetilir.
- Toplu işlemler gönderilmeden önce açık onay ister ve sonuç sayıları denetim kaydına yazılır.
- Raporlar ekranı kayıtlı üyelerin raporlayan/hedef numarasını yetkili yöneticiye tam, diğer kayıtları maskeli gösterir; bekleyen, onaylanan ve reddedilen raporlar filtrelenebilir.

## Railway değişkenleri

`.env.example` içindeki dört `VITE_FIREBASE_*` değişkenini Railway servis değişkenlerine ekleyin. Bunlar Firebase Web App'in herkese açık yapılandırma değerleridir; servis hesabı veya secret key değildir.

Firebase Authentication > Settings > Authorized domains alanına Railway üretim domainini ekleyin.

Push bildirimleri için Firebase Console > Project settings > Cloud Messaging alanında uygulamanın APNs Authentication Key'i tanımlı olmalıdır. iOS uygulaması izin veren cihazın FCM anahtarını doğrulanmış hesaba bağlar; Railway tarafında ayrıca Firebase servis hesabı gerekmez.

İlk yönetici, mevcut `communityModerator` hesabıyla panelde oturum açtığında tek kullanımlık bootstrap işlemiyle otomatik atanır. Bootstrap belgesi oluştuktan sonra başka bir moderatör bu yolla admin olamaz.

Gerekirse Google Application Default Credentials bulunan güvenli bir yönetim ortamından aşağıdaki araç kullanılabilir:

```sh
node ../firebase/functions/scripts/set-admin-claim.js --phone=05XXXXXXXXX
```

Araç mevcut claim'leri korur ve yalnızca `whoCallAdmin` ile `communityModerator` claim'lerini ekler. Kullanıcı panelden çıkış yapıp yeniden giriş yaptığında yeni yetki token'a yansır.

## Yerel doğrulama

```sh
npm install
npm run check
npm run build
npm start
```
