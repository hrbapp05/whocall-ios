import SwiftUI

struct PostAuthenticationFlowView: View {
    let requiresProfileCompletion: Bool
    let showsPaywall: Bool
    let onFinished: () -> Void

    @State private var stage: Stage

    init(
        requiresProfileCompletion: Bool,
        showsPaywall: Bool,
        onFinished: @escaping () -> Void
    ) {
        self.requiresProfileCompletion = requiresProfileCompletion
        self.showsPaywall = showsPaywall
        self.onFinished = onFinished
        _stage = State(initialValue: showsPaywall ? .paywall : .profile)
    }

    var body: some View {
        NavigationStack {
            switch stage {
            case .paywall:
                PremiumView(closeDelayMilliseconds: 2_500) {
                    if requiresProfileCompletion {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            stage = .profile
                        }
                    } else {
                        onFinished()
                    }
                }
                .transition(.opacity)
            case .profile:
                ProfileCompletionView(onComplete: onFinished)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

private extension PostAuthenticationFlowView {
    enum Stage {
        case paywall
        case profile
    }
}
