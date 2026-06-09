import SwiftUI
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject private var coordinator: WatchCoordinator

    var body: some View {
        VStack(spacing: 12) {
            Text(statusText)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button(action: coordinator.triggerPressed) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 70)
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonTint)
            .handGestureShortcut(.primaryAction)
        }
        .padding()
    }

    private var statusText: String {
        switch coordinator.state {
        case .idle: return "Tap to comment"
        case .awaitingAck: return "Pausing…"
        case .recording: return "Recording — tap to stop"
        case .sending: return "Sending…"
        case .error(let msg): return msg
        }
    }

    private var buttonIcon: String {
        switch coordinator.state {
        case .recording: return "stop.fill"
        case .awaitingAck, .sending: return "hourglass"
        default: return "mic.fill"
        }
    }

    private var buttonTint: Color {
        switch coordinator.state {
        case .recording: return .red
        case .error: return .orange
        default: return .blue
        }
    }
}
