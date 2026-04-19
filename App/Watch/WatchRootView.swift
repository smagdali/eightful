import SwiftUI
import StepsToEightCore

struct WatchRootView: View {
    @State private var state: DayState?
    @State private var phase: Phase = .loading
    private let settings = SettingsStore.shared

    enum Phase { case loading, needsAuth, error(String), ready }

    var body: some View {
        VStack(spacing: 6) {
            switch phase {
            case .loading:
                ProgressView()
            case .needsAuth:
                VStack(spacing: 6) {
                    Text("Grant Health access")
                        .font(.headline).multilineTextAlignment(.center)
                    Text("Open the StepsToEight iPhone app and tap Grant Health, or approve the prompt here.")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Button("Request again") { Task { await grantAndLoad() } }
                        .buttonStyle(.borderedProminent)
                }
            case .error(let msg):
                Text(msg).font(.caption2).foregroundStyle(.red).multilineTextAlignment(.center)
            case .ready:
                if let s = state {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: s.steps), number: .decimal))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(s.effectiveTier.color)
                    Text("\(s.points) pt\(s.points == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if s.workoutGreen {
                        Label("workout", systemImage: "heart.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .task { await grantAndLoad() }
    }

    private func grantAndLoad() async {
        phase = .loading
        do {
            try await HealthKitReader.shared.requestAuthorization()
        } catch {
            phase = .needsAuth
            return
        }
        do {
            state = try await HealthKitReader.shared.currentDayState(settings: settings.settings)
            phase = .ready
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            phase = .needsAuth
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
