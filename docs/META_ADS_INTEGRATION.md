# Meta Ads ve Conversions API entegrasyonu

Son güncelleme: 30 Ağustos 2026

## Üretim yapılandırması

- Meta uygulaması: `WhoCall`
- Meta uygulama durumu: **Published**
- Meta App ID: `2267534710688963`
- iOS bundle ID: `com.levelappstudio.whocall`
- App Store ID: `6800227705`
- Meta Dataset ID: `1399269285480560`
- Meta reklam hesabı uygulamaya yetkilendirildi.
- Dataset, WhoCall mobil uygulamasına ve reklam hesabına bağlandı.
- RevenueCat projesinde **Meta Ads > Conversions API** entegrasyonu etkinleştirildi.
- Conversions API erişim anahtarı yalnızca Meta ve RevenueCat panellerinde tutulur; iOS uygulamasına, Firebase'e veya GitHub'a yazılmaz.
- Meta Client Token yalnızca git tarafından yok sayılan `Config/Secrets.xcconfig` dosyasındadır. Client Token public istemci yapılandırması olsa da repoya eklenmez.

## Veri akışı

1. Kullanıcı yasal metinleri kabul edip giriş akışını tamamladıktan sonra iOS, App Tracking Transparency iznini ister.
2. İzin verilirse Meta SDK uygulama aktivasyon sinyalini gönderir ve RevenueCat'e Meta anonim kimliği ile kullanılabilir cihaz reklam kimlikleri aktarılır.
3. RevenueCat, doğruladığı abonelik ve tüketilebilir kredi satın alma olaylarını sunucu tarafında Meta Conversions API'ye yollar.
4. Meta'ya gönderilen varsayılan satın alma olayları `StartTrial`, `Subscribe` ve `fb_mobile_purchase` olur.
5. Uygulama, satın alma hunisinin gelir içermeyen `ViewContent` (paywall görüntüleme), `InitiateCheckout` (satın alma başlangıcı) ve `whocall_paywall_dismissed` (paywall kapatma) olaylarını doğrudan Meta SDK ile gönderir.

Meta SDK'nın otomatik satın alma/gelir kaydı hem uygulama yapılandırmasında hem Meta panelinde kapalıdır. Başarılı abonelik ve kredi satın alma olayları istemciden ikinci kez gönderilmez; RevenueCat doğrulanmış gelir olaylarının tek kaynağıdır.

## Gizlilik sınırları

- Sorgulanan telefon numarası, kişi adı, sorgu sonucu, yorum, etiket ve rapor Meta'ya gönderilmez.
- Kullanıcının kendi telefon numarası, e-posta adresi veya adı Meta eşleştirme alanı olarak kullanılmaz.
- ATT izni vermeyen kullanıcılar uygulamayı eksiksiz kullanmaya devam eder.
- RevenueCat'teki **Send events when ATT consent is not authorized** seçeneği kapalıdır.
- Meta Events Manager'da otomatik gelişmiş eşleştirme ve telefon/e-posta/ad eşleştirmesi kapalıdır.
- Conversions API anahtarı hiçbir istemci paketine veya kaynak kontrolüne girmez.

## Doğrulama

- Meta iOS SDK `18.1.0` sürümüne sabitlendi.
- iOS ARM64 Debug derlemesi `CODE_SIGNING_ALLOWED=NO` ile başarıyla tamamlandı.
- Meta SDK ve RevenueCat cihaz kimliği bağlantısı derleme sırasında doğrulandı.
- RevenueCat panelinde entegrasyon etkin ve olay listesi hazır.
- App Store Connect gizlilik etiketinde `Device ID` ile `Purchase History`; reklam ölçümü, analitik, kullanıcıyla bağlantı ve izleme kullanımlarına göre yayınlandı.

Canlı olay doğrulaması yeni bir uygulama kurulumu, ATT onayı ve gerçek ya da sandbox satın alma gerektirir. İlk uygun satın alma sonrasında RevenueCat müşteri geçmişindeki Meta teslimat satırı ve Meta Events Manager > Test Events ekranı birlikte kontrol edilmelidir. Meta panelinde işlenen olayların görünmesi gecikebilir.
