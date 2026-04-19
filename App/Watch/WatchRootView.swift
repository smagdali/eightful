import SwiftUI
import WidgetKit
import StepsToEightCore

struct WatchRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var state: DayState?
    @State private var phase: Phase = .loading
    @State private var lastUpdated: Date?
    private let settings = SettingsStore.shared
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    enum Phase: Equatable { case loading, needsAuth, error(String), ready }

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
                    if let updated = lastUpdated {
                        Text("updated \(updated, format: .relative(presentation: .numeric))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .task { await grantAndLoad() }
        .onChange(of: scenePhase) { newPhase in
            // Tap-the-complication-to-refresh: scene goes active when the app
            // opens, which hits refresh() and tells the widget to reload.
            if newPhase == .active { Task { await refresh() } }
        }
        .onReceive(refreshTimer) { _ in
            Task { await refresh() }
        }
    }

    /// Re-read HealthKit data without re-prompting for auth.
    private func refresh() async {
        guard phase == .ready || phase == .loading else { return }
        if let s = try? await HealthKitReader.shared.currentDayState(settings: settings.settings) {
            state = s
            lastUpdated = Date()
            phase = .ready
            WidgetCenter.shared.reloadAllTimelines()
        }
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
            lastUpdated = Date()
            phase = .ready
            WidgetCenter.shared.reloadAllTimelines()
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            phase = .needsAuth
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
