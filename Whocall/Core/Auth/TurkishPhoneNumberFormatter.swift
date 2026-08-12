import Foundation

enum TurkishPhoneNumberFormatter {
    static func display(_ value: String) -> String {
        let digits = String(value.filter(\.isNumber).prefix(10))
        guard !digits.isEmpty else { return "" }

        var result = "(\(digits.prefix(3))"
        if digits.count >= 3 { result += ")" }
        if digits.count > 3 { result += " \(digits.dropFirst(3).prefix(3))" }
        if digits.count > 6 { result += " \(digits.dropFirst(6).prefix(2))" }
        if digits.count > 8 { result += " \(digits.dropFirst(8).prefix(2))" }
        return result
    }
}
