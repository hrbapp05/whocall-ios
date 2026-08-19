import SwiftUI

enum LegalDocument: Hashable, Identifiable {
    case termsOfUse
    case kvkkNotice
    case privacyPolicy

    var id: Self { self }

    var title: String {
        switch self {
        case .termsOfUse: "Kullanım Koşulları"
        case .kvkkNotice: "KVKK Aydınlatma Metni"
        case .privacyPolicy: "Gizlilik Politikası"
        }
    }

    fileprivate var intro: String {
        switch self {
        case .termsOfUse:
            "WhoCall hesabınızı, numara sorgularını, topluluk özelliklerini ve satın alımları kullanırken geçerli olan temel kurallar."
        case .kvkkNotice:
            "Bu metin, kişisel verilerinizin kim tarafından, hangi amaçlarla ve hangi hukuki sebeplerle işlendiğini açıklar."
        case .privacyPolicy:
            "WhoCall’un topladığı bilgileri, bunları nasıl kullandığını, kimlerle paylaştığını ve size sunulan kontrolleri açıklar."
        }
    }

    fileprivate var sections: [LegalSectionContent] {
        switch self {
        case .termsOfUse: termsSections
        case .kvkkNotice: kvkkSections
        case .privacyPolicy: privacySections
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(DesignTokens.ColorToken.brandBlue, in: .rect(cornerRadius: 18))

                    Text(document.title)
                        .font(.system(size: 32, weight: .bold))
                        .tracking(-1)

                    Text(document.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Son güncelleme: 19 Ağustos 2026")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }

                ForEach(Array(document.sections.enumerated()), id: \.element.id) { index, section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(index + 1). \(section.title)")
                            .font(.headline)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: .rect(cornerRadius: 22))
                }

                Link("support@levelappstudio.com", destination: URL(string: "mailto:support@levelappstudio.com")!)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .padding(20)
        }
        .background(DesignTokens.ColorToken.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconName: String {
        switch document {
        case .termsOfUse: "doc.text.fill"
        case .kvkkNotice: "person.text.rectangle.fill"
        case .privacyPolicy: "lock.shield.fill"
        }
    }
}

struct LegalSectionContent: Identifiable {
    let id: String
    let title: String
    let body: String
}

private let termsSections: [LegalSectionContent] = [
    .init(id: "service", title: "WhoCall hizmeti", body: "WhoCall, Türkiye cep telefonu numaraları için kısaltılmış isim sonuçları ile topluluk etiketleri, yorumları, raporları ve güven göstergeleri sunabilir. Sonuçların her zaman mevcut, güncel veya hatasız olacağı garanti edilmez; önemli kararların tek dayanağı olarak kullanılmamalıdır."),
    .init(id: "account", title: "Hesap ve doğrulama", body: "Hesap oluştururken yalnızca kontrolünüzde olan kendi telefon numaranızı kullanabilirsiniz. SMS doğrulama kodunu gizli tutmalı; yanlış veya yanıltıcı profil bilgileri vermemelisiniz."),
    .init(id: "use", title: "Kabul edilebilir kullanım", body: "WhoCall yalnızca kişisel ve hukuka uygun amaçlarla kullanılabilir. Taciz, tehdit, ayrımcılık, kişisel bilgileri ifşa etme, toplu veri toplama, sonuçları satma, güvenlik veya ödeme kontrollerini aşma ve otomatik sorgu gönderme yasaktır."),
    .init(id: "community", title: "Topluluk içerikleri ve sıfır tolerans", body: "WhoCall; sakıncalı içeriklere ve kötüye kullanan kullanıcılara karşı sıfır tolerans uygular. Yorum, etiket veya rapor gönderdiğinizde içeriğin makul ölçüde doğru olduğuna ve üçüncü kişilerin haklarını ihlal etmediğine dikkat etmelisiniz. Küfür, hakaret, tehdit, taciz, nefret söylemi, kişisel bilgileri ifşa etme, spam, yanıltıcı rapor ve hukuka aykırı içerikler kesinlikle yasaktır."),
    .init(id: "moderation", title: "Şikâyet, engelleme ve moderasyon", body: "Uygunsuz yorumları ve etiketleri uygulama içinden şikâyet edebilirsiniz. Bir kullanıcıyı engellediğinizde o kullanıcının içerikleri ekranınızdan hemen kaldırılır ve geliştiriciye moderasyon bildirimi gönderilir. Bildirimler en geç 24 saat içinde incelenir; ihlal eden içerik kaldırılır ve içeriği sağlayan kullanıcı uygulamadan çıkarılabilir."),
    .init(id: "purchases", title: "Krediler ve Premium", body: "Krediler nakde çevrilemez ve devredilemez. Premium abonelikler, satın alma ekranında belirtilen dönem boyunca yenilenir ve Apple Hesabı ayarlarından yönetilir. Ödemeler Apple tarafından işlenir; zorunlu haller dışında iade koşulları Apple politikalarına tabidir."),
    .init(id: "termination", title: "Hesabın kapatılması", body: "Bu koşullara veya yürürlükteki hukuka aykırı kullanımda erişim sınırlandırılabilir. Profil bölümünden hesabınızı silebilirsiniz. Hesaba bağlı yorum ve raporlar silinir; kimlikle ilişkilendirilmeyen topluluk istatistikleri, Apple satın alma kayıtları ve yasal olarak saklanması gereken işlemler ilgili saklama sürelerince korunabilir."),
    .init(id: "law", title: "Uygulanacak hukuk ve iletişim", body: "Koşullar Türkiye Cumhuriyeti hukukuna tabidir ve zorunlu tüketici haklarını sınırlamaz. Sorularınızı support@levelappstudio.com adresine gönderebilirsiniz."),
]

private let kvkkSections: [LegalSectionContent] = [
    .init(id: "controller", title: "Veri sorumlusu", body: "WhoCall hizmeti bakımından veri sorumlusu BLAVI LLC’dir. KVKK kapsamındaki başvurularınızı support@levelappstudio.com adresine iletebilirsiniz."),
    .init(id: "data", title: "İşlenen kişisel veriler", body: "Kendi telefon numaranız, SMS doğrulama durumu, Firebase kullanıcı kimliğiniz, adınız ve soyadınız; sorgu ve topluluk katkılarınız; Premium/ürün kimlikleri, abonelik durumu ve kredi hareketleri; güvenlik, hata ve kötüye kullanım önleme için gerekli teknik kayıtlar işlenebilir. WhoCall telefon rehberinize erişmez."),
    .init(id: "purpose", title: "İşleme amaçları", body: "Hesabınızı doğrulamak, numara sorgulama hizmetini sunmak, görünürlük tercihinizi uygulamak, yorum/etiket/rapor özelliklerini çalıştırmak, satın alımları ve kredileri yönetmek, dolandırıcılık ve kötüye kullanımı önlemek, destek sağlamak ve hukuki yükümlülükleri yerine getirmek."),
    .init(id: "basis", title: "Yöntem ve hukuki sebep", body: "Veriler uygulama ve bağlı hizmetler üzerinden otomatik yöntemlerle elde edilir. İşleme; sözleşmenin kurulması veya ifası, hukuki yükümlülük, bir hakkın tesisi veya korunması, temel haklara zarar vermemek kaydıyla meşru menfaat ve gerektiğinde ayrı olarak alınan açık rıza şartlarına dayanabilir."),
    .init(id: "transfer", title: "Aktarımlar", body: "Hizmetin sunulması amacıyla sınırlı veriler Google Firebase, Apple, RevenueCat, WhoCall API ve barındırma/altyapı sağlayıcılarıyla paylaşılabilir. Yurt dışı aktarımlar yürürlükteki mevzuatta öngörülen güvencelere uygun şekilde gerçekleştirilir."),
    .init(id: "rights", title: "Haklarınız", body: "KVKK’nın 11. maddesi kapsamındaki bilgi alma, düzeltme, silme, yok etme ve itiraz haklarınızı kullanabilirsiniz. Uygulama içinden arama görünürlüğünü kapatabilir ve hesabınızı silebilirsiniz. Başvurularda güvenli kimlik doğrulaması istenebilir."),
]

private let privacySections: [LegalSectionContent] = [
    .init(id: "collection", title: "Topladığımız bilgiler", body: "WhoCall; hesap ve telefon doğrulama bilgilerini, sağladığınız ad-soyadı, gerçekleştirdiğiniz sorguları ve topluluk katkılarını, satın alma durumunu ve hizmet güvenliği için gereken sınırlı teknik bilgileri işler. Ödeme kartı bilgilerinizi almaz ve telefon rehberinizi toplamaz."),
    .init(id: "visibility", title: "Arama görünürlüğü", body: "Kendi numaranızı SMS ile doğrulayıp ad ve soyadınızı eklediğinizde, görünürlük açıkken doğrulanmış profiliniz veri tabanı sonucuna öncelik verebilir. Sonuçlarda soyadının yalnızca baş harfi gösterilir. Görünürlüğü profilinizden kapatabilirsiniz."),
    .init(id: "providers", title: "Hizmet sağlayıcıları", body: "Firebase kimlik doğrulama ve sunucu altyapısı; RevenueCat ve Apple satın alma/abonelik işlemleri; WhoCall API numara sorguları için kullanılır. Sağlayıcılardan, verileri bu politikayla uyumlu şekilde korumaları beklenir. Kişisel bilgiler reklam ağlarına satılmaz."),
    .init(id: "retention", title: "Saklama ve güvenlik", body: "Veriler hizmeti sunmak, hesabı sürdürmek, anlaşmazlıkları çözmek, kötüye kullanımı önlemek veya hukuki yükümlülükleri karşılamak için gereken süreyle sınırlı tutulur. Kimlik doğrulama, erişim kontrolleri, istek sınırları ve takma adlı tanımlayıcılar kullanılır."),
    .init(id: "choices", title: "Tercihleriniz", body: "Arama görünürlüğünü kapatabilir, hesabınızı uygulama içinden silebilir ve destek adresimiz üzerinden erişim, düzeltme veya silme talebinde bulunabilirsiniz. Açık rızaya dayalı isteğe bağlı bir işlem varsa rızanızı geri çekebilirsiniz."),
]
