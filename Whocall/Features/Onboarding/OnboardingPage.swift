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
            "Topluluk Kayıtları Ve Veritabanı Eşleşmeleriyle Numara Hakkında Hızlı Sonuç Al."
        case .details:
            "Etiketleri, Topluluk Yorumlarını Ve Güven Seviyesini Tek Ekranda İncele."
        }
    }

    var mockupAsset: String {
        switch self {
        case .unknownNumbers: "Intro1Device"
        case .scan: "Intro2Device"
        case .details: "Intro3Device"
        }
    }

    var messageHeight: CGFloat {
        switch self {
        case .scan: 66
        case .unknownNumbers, .details: 44
        }
    }
}
