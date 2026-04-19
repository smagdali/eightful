import SwiftUI
import WidgetKit
import StepsToEightCore

struct WatchRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var state: DayState?
    @State private var phase: Phase = .loading
    @State private var lastUpdated: Date?
    @State private var observerToken: NSObjectProtocol?
    private let settings = SettingsStore.shared
    private let refreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

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
            if newPhase == .active {
                Task { await refresh() }
                startLivePedometer()
            } else if newPhase == .background {
                PedometerReader.shared.stopLiveUpdates()
            }
        }
        .onReceive(refreshTimer) { _ in
            Task { await refresh() }
        }
    }

    /// Start CoreMotion push updates so the step count increments in real time
    /// rather than waiting for HealthKit or our timer.
    private func startLivePedometer() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        PedometerReader.shared.startLiveUpdates(from: startOfDay) { steps in
            Task { @MainActor in
                if var s = state {
                    s = DayState(steps: steps, workoutGreen: s.workoutGreen, timestamp: Date())
                    state = s
                } else {
                    state = DayState(steps: steps, workoutGreen: false, timestamp: Date())
                }
                lastUpdated = Date()
                WidgetCenter.shared.reloadAllTimelines()
            }
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
            startLivePedometer()
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            phase = .needsAuth
        } catch {
            phase = .error(error.localizedDescription)
        }
    }
}
