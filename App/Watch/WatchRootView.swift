import SwiftUI
import WidgetKit
import EightfulCore

struct WatchRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var state: DayState?
    @State private var phase: Phase = .loading
    @State private var lastUpdated: Date?
    @State private var refreshTask: Task<Void, Never>?
    private let settings = SettingsStore.shared

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
                    Text("Open the Eightful iPhone app and tap Grant Health, or approve the prompt here.")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Button("Request again") { Task { await grantAndLoad() } }
                        .buttonStyle(.borderedProminent)
                }
            case .error(let msg):
                Text(msg).font(.caption2).foregroundStyle(.red).multilineTextAlignment(.center)
            case .ready:
                if let s = state {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: s.steps), number: .decimal))
                        .font(.system(size: 58, weight: .heavy, design: .rounded))
                        .foregroundStyle(s.displayColor.color)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text("\(s.points) pt\(s.points == 1 ? "" : "s")")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(s.displayColor.color.opacity(0.9))
                        if s.workoutGreen {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                        }
                    }
                    if let updated = lastUpdated {
                        Text(updated, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding()
        .task { await grantAndLoad(); startAdaptiveRefresh() }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                Task { await refresh() }     // immediate refresh on re-open / tap-through
                startAdaptiveRefresh()       // reset cadence to fast
            case .background, .inactive:
                stopAdaptiveRefresh()
            @unknown default: break
            }
        }
    }

    /// Re-poll on an adaptive interval: faster while stepping hard, slower while idle.
    /// Range: 15s (active) to 300s (idle). Activity of the user decides.
    private func startAdaptiveRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            var interval: TimeInterval = 30
            var lastSteps = state?.steps ?? 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if Task.isCancelled { break }
                await refresh()
                let now = state?.steps ?? lastSteps
                let delta = now - lastSteps
                lastSteps = now
                // <10 steps since last check = backing off, double the interval
                // 10..<100 = steady 60s
                // >=100 = user is moving, tighten to 15s
                if delta < 10 {
                    interval = min(300, interval * 2)
                } else if delta < 100 {
                    interval = 60
                } else {
                    interval = 15
                }
            }
        }
    }

    private func stopAdaptiveRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Re-read HealthKit data without re-prompting for auth.
    private func refresh() async {
        guard phase == .ready || phase == .loading else { return }
        if let s = try? await HealthKitReader.shared.currentDayState(settings: settings.settings) {
            let previous = state
            state = s
            lastUpdated = Date()
            phase = .ready
            // Only burn widget-reload budget when the user actually crossed
            // into/out of a tier or nudge zone, or workout-green flipped.
            // A fallback keeps the complication fresh-ish after 15 min of idle.
            let crossed = s.isMaterialChange(from: previous)
            let stale = WidgetReloadCoordinator.shared.shouldReloadOnIdle()
            if crossed || stale {
                WidgetCenter.shared.reloadAllTimelines()
                WidgetReloadCoordinator.shared.markReloaded()
            }
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
