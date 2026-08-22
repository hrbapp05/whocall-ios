# Meta reklam ölçümü entegrasyon planı

Meta hesabı bağlanmadan önce kod veya üretim secret'ı eklenmeyecektir. Bağlantı sırasında Meta App ID, iOS Client Token, Dataset/Pixel ID ve sunucu tarafı Conversions API erişim anahtarı alınır. CAPI anahtarı yalnızca Firebase Secret Manager'da saklanır; iOS uygulamasına, GitHub'a veya Railway paneline konmaz.

## Önerilen olaylar

- Uygulama açılışı
- Telefon doğrulamasının tamamlanması (`CompleteRegistration`)
- Başarılı numara sorgusu (`Search`)
- Kredi satın alma ve doğrulanmış abonelik (`Purchase` / `Subscribe`)

StoreKit/RevenueCat satın alma olayları yalnızca doğrulanmış işlem sonucundan sonra gönderilir. SDK ve CAPI aynı olayı gönderiyorsa tekil `event_id` ile tekilleştirme yapılır.

## Gizlilik sınırları

- Sorgulanan üçüncü kişiye ait telefon numarası, ad, soyad, yorum, etiket veya arama sonucu Meta'ya gönderilmez.
- Olay parametrelerinde ham telefon numarası kullanılmaz.
- Kullanıcı eşleştirme verileri ancak geçerli hukuki dayanak ve gerekli izinler sağlanırsa normalleştirilip SHA-256 ile hashlenerek sunucudan gönderilir.
- App Tracking Transparency izni ile reklam ölçümü/onay ekranları mevcut gizlilik metni ve App Store privacy beyanlarıyla birlikte gözden geçirilir.
- Limited Data Use ve Türkiye hedeflemesi Meta hesabı bağlantısı sırasında kontrol edilir.

## Hesap açıldığında tamamlanacaklar

1. Meta uygulamasını WhoCall bundle ID `com.levelappstudio.whocall` ile bağlamak.
2. SDK yapılandırmasını `.xcconfig` üzerinden public App ID/Client Token ile yapmak.
3. Firebase üzerinde CAPI aktarım işlevini ve Secret Manager anahtarını oluşturmak.
4. Test Events ekranında SDK/CAPI olaylarını ve tekilleştirmeyi doğrulamak.
5. Gizlilik politikası, ATT metni ve App Store privacy cevaplarını son veri akışına göre güncellemek.
