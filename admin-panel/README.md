# WhoCall Admin

Railway üzerinde çalışan yönetim arayüzüdür. Tarayıcı yalnızca Firebase Authentication ile giriş yapar; tüm okuma ve yazma işlemleri `adminQuery`, `adminMutate` ve moderasyon callable işlevleri üzerinden sunucuda yetkilendirilir.

## Yetki modeli

- Giriş yapan Firebase kullanıcısında `whoCallAdmin: true` custom claim bulunmalıdır.
- İçerik moderasyonu için aynı claim kabul edilir; mevcut `communityModerator` yetkisi korunur.
- Telefon numarası denetim kayıtlarına yazılmaz. Kayıt kimliği anahtarlı HMAC ile oluşturulur.
- Panel promosyon premium ve promosyon kredisi yönetir. App Store aboneliğini iptal etmez ve satın alınmış tüketilebilir krediyi değiştirmez.

## Railway değişkenleri

`.env.example` içindeki dört `VITE_FIREBASE_*` değişkenini Railway servis değişkenlerine ekleyin. Bunlar Firebase Web App'in herkese açık yapılandırma değerleridir; servis hesabı veya secret key değildir.

Firebase Authentication > Settings > Authorized domains alanına Railway üretim domainini ekleyin.

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
