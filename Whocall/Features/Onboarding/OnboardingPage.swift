import Foundation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case unknownNumbers
    case scan
    case details

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .unknownNumbers: "Bilinmeyen\nNumaraları Bul"
        case .scan: "Numarayı Tara,\nSonucu Gör"
        case .details: "Detaylı\nSonuçlara Ulaş"
        }
    }

    var message: String {
        switch self {
        case .unknownNumbers:
            "Seni arayan numaraları saniyeler içinde sorgula, kimin aradığını hızlıca öğren."
        case .scan:
            "Topluluk kayıtları ve veritabanı eşleşmeleriyle numara hakkında hızlı sonuç al."
        case .details:
            "Etiketleri, topluluk yorumlarını ve güven seviyesini tek ekranda incele."
        }
    }

    var heroAsset: String {
        switch self {
        case .unknownNumbers: "Intro1Hero"
        case .scan: "Intro2Hero"
        case .details: "Intro3Hero"
        }
    }
}

