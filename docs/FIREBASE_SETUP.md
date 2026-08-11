# Firebase telefon doğrulama kurulumu

WhoCall, Firebase Authentication'ın telefon sağlayıcısını kullanır. Uygulama hedefi
`com.levelappstudio.whocall` paket kimliğiyle kayıtlı olmalıdır.

## Firebase Console

1. WhoCall Firebase projesinde iOS uygulamasını `com.levelappstudio.whocall` paket kimliğiyle ekleyin.
2. İndirilen gerçek `GoogleService-Info.plist` dosyasını `Whocall/Resources/` altına yerleştirin. Dosya Git tarafından yok sayılır ve repoya eklenmez.
3. Authentication > Sign-in method altında **Phone** sağlayıcısını açın.
4. Firebase test telefonlarını yalnızca geliştirme/doğrulama için kullanın; production build gerçek SMS akışını kullanır.

## Xcode ve APNs

- Uygulama hedefinde Push Notifications capability ile Background Modes > Remote notifications açıktır.
- Release build `aps-environment=production`, Debug build `aps-environment=development` kullanır.
- Firebase Console > Project settings > Cloud Messaging bölümüne App Store Connect ekibinin APNs Authentication Key dosyasını, Key ID ve Team ID ile yükleyin.
- `FirebaseAppDelegateProxyEnabled` kapalı olduğu için APNs token'ı ve bildirim callback'leri `AppDelegate` tarafından Firebase Auth'a açıkça iletilir.

## reCAPTCHA fallback

Sessiz APNs doğrulaması kullanılamazsa Firebase Auth reCAPTCHA akışına düşer. Release sırasında
`GoogleService-Info.plist` içindeki `REVERSED_CLIENT_ID`, `FIREBASE_REVERSED_CLIENT_ID`
build setting'i olarak aktarılmalı ve uygulamanın URL scheme listesinde bulunmalıdır.

## Release doğrulaması

- Gerçek telefon ve SMS kodu kaynak koda, Git'e veya loglara yazılmaz.
- OTP alanı altı haneli kod, paste ve iOS `oneTimeCode` AutoFill desteği sağlar.
- Başarılı giriş Firebase auth-state listener üzerinden uygulamanın ana akışını açar; çıkış Firebase oturumunu da kapatır.
