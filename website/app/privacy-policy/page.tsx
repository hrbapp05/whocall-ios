import type { Metadata } from "next";
import { LegalPage, type LegalSection } from "../components/LegalPage";

export const metadata: Metadata = {
  title: "Gizlilik Politikası",
  description: "WhoCall uygulamasının gizlilik politikası ve kişisel verilerin işlenmesine ilişkin açıklamalar.",
  alternates: { canonical: "/privacy-policy" },
};

const sections: LegalSection[] = [
  {
    id: "kapsam",
    title: "Kapsam ve veri sorumlusu",
    content: <>
      <p>Bu Gizlilik Politikası, BLAVI LLC tarafından sunulan WhoCall iOS uygulaması ve WhoCall web sitesi için geçerlidir. WhoCall yalnızca Türkiye’de sunulan bir telefon numarası sorgulama ve topluluk bilgi hizmetidir.</p>
      <p>Gizlilikle ilgili talepleriniz için <a href="mailto:support@levelappstuido.com">support@levelappstuido.com</a> adresinden bize ulaşabilirsiniz.</p>
    </>,
  },
  {
    id: "toplanan-veriler",
    title: "İşlediğimiz veriler",
    content: <>
      <p>Uygulamayı nasıl kullandığınıza bağlı olarak aşağıdaki bilgileri işleyebiliriz:</p>
      <ul>
        <li>Hesap ve doğrulama bilgileri: kendi cep telefonu numaranız, SMS doğrulama durumu, Firebase kullanıcı kimliği ve isteğe bağlı ad-soyad bilginiz.</li>
        <li>Sorgu bilgileri: sorguladığınız telefon numarası ve size gösterilen sonuç. Son sorgular cihazınızda, doğrulanmış hesabınıza bağlı olarak tutulabilir.</li>
        <li>Topluluk içerikleri: eklediğiniz yorumlar, etiketler ve raporlar. Görünen adınız gizlilik amacıyla kısaltılabilir.</li>
        <li>Satın alma bilgileri: ürün kimliği, abonelik durumu, yenileme ve sona erme bilgileri ile kredi işlemleri. Ödeme kartı bilgilerinizi görmeyiz veya saklamayız.</li>
        <li>Teknik bilgiler: hizmet güvenliği, hata giderme ve kötüye kullanımın önlenmesi için gerekli istek, hata ve işlem bilgileri.</li>
      </ul>
      <div className="legal-callout"><p>WhoCall rehberinize erişim istemez ve telefonunuzdaki kişi listesini toplamaz.</p></div>
    </>,
  },
  {
    id: "amaclar",
    title: "Verileri neden kullanıyoruz?",
    content: <>
      <ul>
        <li>Telefon numaranızı doğrulamak ve hesabınıza güvenli erişim sağlamak.</li>
        <li>Numara sorgulama sonuçlarını, topluluk etiketlerini, yorumları ve güven seviyesini sunmak.</li>
        <li>Kendi doğrulanmış numaranız için ad ve görünürlük tercihlerinizi uygulamak.</li>
        <li>Premium abonelikleri, sorgu kredilerini ve satın alma geçmişini yönetmek.</li>
        <li>Spam, dolandırıcılık, hakaret ve hizmetin kötüye kullanımını önlemek; hız sınırlarını uygulamak.</li>
        <li>Yasal yükümlülükleri yerine getirmek ve kullanıcı taleplerine yanıt vermek.</li>
      </ul>
    </>,
  },
  {
    id: "hukuki-sebepler",
    title: "Hukuki sebepler",
    content: <p>Kişisel verileri; hizmet sözleşmesini yerine getirmek, açık rızanızın bulunduğu işlemleri yapmak, yasal yükümlülükleri karşılamak, hakların tesisi veya korunması ve hizmet güvenliğine ilişkin meşru menfaatlerimiz kapsamında işleriz. Türkiye’deki kullanıcılar bakımından 6698 sayılı Kişisel Verilerin Korunması Kanunu dâhil uygulanabilir mevzuata uygun hareket etmeyi amaçlarız.</p>,
  },
  {
    id: "paylasim",
    title: "Hizmet sağlayıcılar ve aktarım",
    content: <>
      <p>Hizmeti sunabilmek için sınırlı verileri aşağıdaki sağlayıcı kategorileriyle paylaşabiliriz:</p>
      <ul>
        <li>Google Firebase: telefonla kimlik doğrulama, güvenli sunucu işlevleri ve veri altyapısı.</li>
        <li>RevenueCat ve Apple: uygulama içi satın alımların, kredilerin ve abonelik haklarının yönetimi.</li>
        <li>WhoCall API ve barındırma sağlayıcıları: numara sorgularının güvenli biçimde işlenmesi ve hizmetin sunulması.</li>
      </ul>
      <p>Bu sağlayıcılar verileri kendi altyapılarında, Türkiye dışında işleyebilir. Aktarımlar uygulanabilir veri koruma kurallarına ve sağlayıcı sözleşmelerine uygun şekilde gerçekleştirilir. Verileri reklam ağına satmayız.</p>
    </>,
  },
  {
    id: "gorunurluk",
    title: "Arama görünürlüğü ve topluluk içerikleri",
    content: <>
      <p>Kendi numaranızı SMS ile doğrulayıp ad-soyad eklediğinizde, izin verdiğiniz sürece bu bilgi sorgu sonuçlarında gizlilik odaklı biçimde gösterilebilir. WhoCall, sonuçlarda soyadının yalnızca baş harfini göstermeyi amaçlar. Profilinizden arama sonuçlarındaki görünürlüğünüzü kapatabilirsiniz.</p>
      <p>Yorumlar ve etiketler diğer doğrulanmış kullanıcılar tarafından görülebilir. Uygunsuz ifadeleri engellemek için içerik filtresi ve raporlama araçları kullanılır. Herkese açık alana paylaşılmasını istemediğiniz kişisel bilgileri yazmamalısınız.</p>
    </>,
  },
  {
    id: "saklama-guvenlik",
    title: "Saklama ve güvenlik",
    content: <>
      <p>Verileri hizmet için gerekli olduğu, hesabınız aktif kaldığı veya yasal olarak saklamamız gerektiği süre boyunca tutarız. Sorgu geçmişi gibi bazı veriler yalnızca cihazınızda tutulabilir. Kötüye kullanımı önleyen geçici kayıtlar daha kısa sürelerle saklanabilir.</p>
      <p>Numaraları doğrudan belge kimliği olarak kullanmak yerine anahtarlı özetleme, kimlik doğrulama, erişim kuralları ve istek sınırlandırma gibi önlemler uygularız. Buna rağmen hiçbir elektronik sistem mutlak güvenlik garantisi vermez.</p>
    </>,
  },
  {
    id: "haklar",
    title: "Haklarınız ve hesap silme",
    content: <>
      <p>Uygulanabilir mevzuat kapsamında verilerinize erişme, düzeltme, silme, işlemeyi kısıtlama veya itiraz etme ve rızanızı geri çekme haklarına sahip olabilirsiniz. Arama görünürlüğünü uygulama içindeki profil alanından yönetebilirsiniz.</p>
      <p>Hesap veya veri silme talebinizi, doğrulanmış telefon numaranızı e-posta içine açıkça yazmadan, <a href="mailto:support@levelappstuido.com?subject=WhoCall%20Hesap%20Silme%20Talebi">support@levelappstuido.com</a> adresine “WhoCall Hesap Silme Talebi” başlığıyla gönderebilirsiniz. Güvenlik için talebi uygulama içinden veya hesabınızla ilişkilendirilebilen ek bir doğrulama adımıyla teyit etmenizi isteyebiliriz.</p>
    </>,
  },
  {
    id: "cocuklar-degisiklik",
    title: "Çocuklar ve politika değişiklikleri",
    content: <p>WhoCall 9 yaş altındaki çocuklara yönelik değildir. Bu politikayı hizmette veya mevzuatta meydana gelen değişikliklere göre güncelleyebiliriz. Önemli değişiklikleri uygulama, web sitesi veya uygun başka bir kanal üzerinden duyurur ve sayfanın üstündeki güncelleme tarihini değiştiririz.</p>,
  },
];

export default function PrivacyPolicyPage() {
  return <LegalPage title="Gizlilik Politikası" intro="WhoCall’da hangi verilerin neden işlendiğini ve seçeneklerinizi açık, anlaşılır bir dille anlatıyoruz." sections={sections} />;
}
