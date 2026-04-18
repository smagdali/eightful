import SwiftUI
import StepsToEightCore

struct WatchRootView: View {
    @State private var state: DayState?
    @State private var error: String?
    private let settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 6) {
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
            } else if let error {
                Text(error).font(.caption2).foregroundStyle(.red)
            } else {
                ProgressView()
            }
        }
        .padding()
        .task { await refresh() }
    }

    private func refresh() async {
        do {
            state = try await HealthKitReader.shared.currentDayState(settings: settings.settings)
        } catch {
            self.error = String(describing: error)
        }
    }
}
