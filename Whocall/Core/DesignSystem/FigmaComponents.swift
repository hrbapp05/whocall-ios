import SwiftUI

struct CreditBadge: View {
    var amount: Int?
    @AppStorage(PurchaseStore.creditBalanceKey) private var storedAmount = 5

    init(amount: Int? = nil) {
        self.amount = amount
    }

    var body: some View {
        HStack(spacing: 5) {
            Image("CreditGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text("\(displayAmount)")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 13)
        .frame(height: 36)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayAmount) kredi")
    }

    private var displayAmount: Int { amount ?? storedAmount }
}

struct ToolbarCreditBadge: View {
    var amount: Int?
    @AppStorage(PurchaseStore.creditBalanceKey) private var storedAmount = 5

    init(amount: Int? = nil) {
        self.amount = amount
    }

    var body: some View {
        HStack(spacing: 5) {
            Image("CreditGlyph").resizable().scaledToFit().frame(width: 14, height: 14)
            Text("\(displayAmount)").font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.black)
        .frame(width: 48, height: 30)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayAmount) kredi")
    }

    private var displayAmount: Int { amount ?? storedAmount }
}

struct FigmaTag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(DesignTokens.ColorToken.brandBlue.opacity(0.11), in: .capsule)
    }
}

private struct EntranceMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let delay: Double
    let distance: CGFloat
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.96)
            .offset(y: isVisible || reduceMotion ? 0 : distance)
            .onAppear {
                guard !reduceMotion else {
                    isVisible = true
                    return
                }
                withAnimation(.spring(duration: 0.7, bounce: 0.24).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

private struct FloatingMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let distance: CGFloat
    let duration: Double
    let delay: Double
    @State private var isFloating = false

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (isFloating ? -distance : distance))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).delay(delay).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

extension View {
    func figmaEntrance(delay: Double = 0, distance: CGFloat = 18) -> some View {
        modifier(EntranceMotion(delay: delay, distance: distance))
    }

    func gentleFloat(distance: CGFloat = 4, duration: Double = 2.2, delay: Double = 0) -> some View {
        modifier(FloatingMotion(distance: distance, duration: duration, delay: delay))
    }
}
