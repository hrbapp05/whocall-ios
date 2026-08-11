import SwiftUI

struct PostAuthenticationFlowView: View {
    let requiresProfileCompletion: Bool
    let onFinished: () -> Void

    @State private var stage = Stage.paywall

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
