import type { Metadata } from "next";
import { LegalPage, type LegalSection } from "../components/LegalPage";

export const metadata: Metadata = {
  title: "Kullanım Koşulları",
  description: "WhoCall uygulamasının kullanım koşulları, abonelik ve topluluk kuralları.",
  alternates: { canonical: "/terms-of-use" },
};

const sections: LegalSection[] = [
  {
    id: "kabul",
    title: "Koşulların kabulü",
    content: <p>WhoCall uygulamasını veya web sitesini indirerek, açarak ya da kullanarak bu Kullanım Koşullarını ve Gizlilik Politikamızı kabul etmiş olursunuz. Kabul etmiyorsanız hizmeti kullanmayın. Hizmet BLAVI LLC tarafından Türkiye’deki kullanıcılar için sunulur.</p>,
  },
  {
    id: "hizmet",
    title: "Hizmetin kapsamı",
    content: <>
      <p>WhoCall, Türkiye cep telefonu numaraları için ad bilgisi, topluluk etiketleri, yorumlar, raporlar ve bunlardan türetilen güven seviyesi sunabilir. Sonuçlar mevcut veri kayıtlarına, doğrulanmış kullanıcı profillerine ve topluluk katkılarına dayanabilir.</p>
      <div className="legal-callout"><p>WhoCall resmi bir kimlik doğrulama, acil durum, finansal değerlendirme veya kolluk hizmeti değildir. Her numara için sonuç bulunması ya da tüm bilgilerin eksiksiz ve güncel olması garanti edilmez.</p></div>
    </>,
  },
  {
    id: "hesap",
    title: "Hesap ve telefon doğrulaması",
    content: <>
      <p>Hesap açmak için yalnızca size ait veya kullanım yetkiniz bulunan kendi telefon numaranızı kullanmalısınız. SMS doğrulama kodunu kimseyle paylaşmamalı ve hesabınızda gerçekleşen işlemlerin güvenliğini sağlamalısınız.</p>
      <p>Yanlış, yanıltıcı veya başkasına ait bilgilerle profil oluşturamaz; doğrulamayı aşmaya, hesapları toplu biçimde açmaya ya da hizmetin güvenlik önlemlerini etkisizleştirmeye çalışamazsınız.</p>
    </>,
  },
  {
    id: "kullanim",
    title: "İzin verilen ve yasaklanan kullanım",
    content: <>
      <p>WhoCall’u yalnızca kişisel, hukuka uygun ve bu koşullarla uyumlu amaçlarla kullanabilirsiniz. Aşağıdakiler yasaktır:</p>
      <ul>
        <li>Hizmeti taciz, takip, tehdit, ayrımcılık, doxing veya başka kişilerin mahremiyetini ihlal etmek için kullanmak.</li>
        <li>Sonuçları otomatik araçlarla toplamak, kopyalamak, yeniden satmak veya geniş ölçekli bir telefon dizini oluşturmak.</li>
        <li>API’ye veya uygulamaya yetkisiz erişmek; hız sınırlarını, ödeme sistemini ya da güvenlik kontrollerini aşmak.</li>
        <li>Zararlı yazılım, yanıltıcı içerik, reklam, spam, hakaret veya hukuka aykırı içerik göndermek.</li>
        <li>WhoCall’un ya da üçüncü kişilerin fikri mülkiyet haklarını ihlal etmek.</li>
      </ul>
    </>,
  },
  {
    id: "topluluk",
    title: "Topluluk içerikleri",
    content: <>
      <p>Yorum, etiket veya rapor gönderdiğinizde içeriğin doğru olduğuna iyi niyetle inandığınızı, gerekli haklara sahip olduğunuzu ve hukuka aykırı kişisel veri paylaşmadığınızı kabul edersiniz.</p>
      <p>İçeriğiniz üzerindeki haklarınız sizde kalır. İçeriği hizmeti işletmek, görüntülemek, güvenliğini sağlamak ve geliştirmek için kullanmamıza; teknik olarak çoğaltmamıza ve biçimlendirmemize dünya çapında, münhasır olmayan ve bedelsiz bir lisans verirsiniz. Kuralları ihlal eden içerikleri kaldırabilir, görünürlüğünü sınırlayabilir veya ilgili hesabın erişimini askıya alabiliriz.</p>
    </>,
  },
  {
    id: "satin-alim",
    title: "Krediler, Premium ve ödemeler",
    content: <>
      <h3>Sorgu kredileri</h3>
      <p>Krediler, uygulama içinde belirtilen sayı kadar ücretli sorgu sonucuna erişim sağlar. Krediler nakde çevrilemez, devredilemez ve kanunen zorunlu olmadıkça iade edilmez.</p>
      <h3>Premium abonelikler</h3>
      <p>Premium abonelikler, satın alma ekranında belirtilen dönem boyunca sınırsız sorgu gibi özellikler sunabilir. Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmezse Apple hesabınız üzerinden otomatik yenilenebilir. Ücret ve dönem satın alma onayından önce App Store’da gösterilir.</p>
      <h3>Yönetim ve iade</h3>
      <p>Aboneliğinizi Apple hesabınızın Abonelikler bölümünden yönetebilir veya iptal edebilirsiniz. Ödemeler Apple tarafından işlenir; iade talepleri Apple’ın geçerli kurallarına tabidir. Satın alımları geri yükleme özelliği uygulama içinde sunulabilir.</p>
    </>,
  },
  {
    id: "fikri-mulkiyet",
    title: "Fikri mülkiyet",
    content: <p>WhoCall adı, uygulama ikonu, tasarımlar, yazılım, metinler ve BLAVI LLC tarafından oluşturulan diğer tüm içerikler ilgili fikri mülkiyet mevzuatıyla korunur. Bu koşullar size yalnızca kişisel kullanım için sınırlı, geri alınabilir, devredilemez ve münhasır olmayan bir kullanım hakkı verir.</p>,
  },
  {
    id: "sorumluluk",
    title: "Garanti ve sorumluluk sınırı",
    content: <>
      <p>Hizmet, yürürlükteki hukukun izin verdiği ölçüde “olduğu gibi” sunulur. Sonuçların doğruluğu, eksiksizliği, belirli bir amaca uygunluğu veya kesintisiz erişim konusunda garanti vermeyiz. WhoCall sonuçları tek başına önemli bir kararın temeli yapılmamalıdır.</p>
      <p>Kanunen sınırlandırılamayan sorumluluklar hariç olmak üzere BLAVI LLC; dolaylı zararlar, veri kaybı, kâr kaybı, hizmet kesintisi veya kullanıcı ya da üçüncü kişi içeriklerinden doğan zararlardan sorumlu değildir. Toplam sorumluluğumuz, talebe yol açan olaydan önceki 12 ayda WhoCall için ödediğiniz tutarı aşmaz.</p>
    </>,
  },
  {
    id: "sona-erme",
    title: "Askıya alma ve sona erme",
    content: <p>Bu koşulları veya hukuku ihlal etmeniz, hizmetin güvenliğini tehlikeye atmanız ya da diğer kullanıcılara zarar vermeniz halinde erişiminizi sınırlayabilir veya sona erdirebiliriz. Hizmeti kullanmayı dilediğiniz zaman bırakabilirsiniz. Sona erme, önceden doğmuş ödeme ve sorumluluk hükümlerini ortadan kaldırmaz.</p>,
  },
  {
    id: "degisiklik-iletisim",
    title: "Değişiklikler ve iletişim",
    content: <>
      <p>Hizmeti ve bu koşulları zaman zaman güncelleyebiliriz. Önemli değişiklikleri uygun bir kanaldan duyururuz. Güncellenmiş koşullar yürürlüğe girdikten sonra hizmeti kullanmaya devam etmeniz yeni koşulları kabul ettiğiniz anlamına gelir.</p>
      <p>Bu koşullar hakkında <a href="mailto:support@levelappstuido.com">support@levelappstuido.com</a> adresinden bize ulaşabilirsiniz. Uyuşmazlıklarda uygulanması zorunlu tüketici hükümleri ve kanunlar saklıdır.</p>
    </>,
  },
];

export default function TermsOfUsePage() {
  return <LegalPage title="Kullanım Koşulları" intro="WhoCall’u kullanırken haklarınızı, sorumluluklarınızı ve topluluk kurallarını bu sayfada bulabilirsiniz." sections={sections} />;
}
