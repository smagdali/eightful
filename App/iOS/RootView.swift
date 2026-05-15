import SwiftUI
import HealthKit
import UserNotifications
import EightfulCore

struct RootView: View {
    @StateObject private var store = SettingsStore.shared
    @State private var healthAuthorized = HealthKitReader.shared.isHealthDataAvailable
    @State private var notificationsAuthorized = false
    @State private var dayState: DayState?
    @State private var authError: String?

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                permissionsSection
                aboutSection
            }
            .navigationTitle("Eightful")
            .task {
                if ScreenshotMode.isActive {
                    dayState = ScreenshotMode.sampleDayState
                } else {
                    await refresh()
                }
            }
        }
    }

    private var statusSection: some View {
        Section("Today") {
            if let state = dayState {
                HStack(alignment: .firstTextBaseline) {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: state.steps), number: .decimal))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(state.displayColor.color)
                    Spacer()
                    Text("\(state.points) pt\(state.points == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(state.effectiveTier.color)
                }
                if let detail = state.workoutDetail, detail.points > 0 {
                    workoutDetailBanner(detail)
                }
            } else {
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private func workoutDetailBanner(_ d: WorkoutGreenDetail) -> some View {
        let name = d.workoutName ?? "Workout"
        let minutes = Int(d.durationMinutes.rounded())
        let headline = d.points == 8 ? "8-point goal reached" : "\(d.points)-point workout logged"
        let detail: String = {
            if d.avgHR > 0 && d.maxHR > 0 {
                let avgBPM = Int(d.avgHR.rounded())
                let pct = Int(d.percentOfMax.rounded())
                return "\(name): \(minutes) min at \(pct)% of max HR (\(avgBPM) bpm)"
            } else {
                return "\(name): \(minutes) min"
            }
        }()
        HStack(spacing: 8) {
            Image(systemName: "heart.fill").foregroundStyle(d.points == 8 ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.footnote).bold()
                Text(detail)
                    .font(.footnote)
            }
            Spacer(minLength: 0)
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            if healthAuthNeeded {
                Button {
                    Task { await requestHealthAuth() }
                } label: {
                    Label("Grant Health access", systemImage: "heart.text.square")
                }
            } else {
                Button {
                    openiOSSettings()
                } label: {
                    Label("Manage Health access in Settings", systemImage: "heart.text.square")
                        .foregroundStyle(.secondary)
                }
            }
            if !notificationsAuthorized {
                Button {
                    Task { await requestNotifAuth() }
                } label: {
                    Label("Allow notifications", systemImage: "bell")
                }
            }
            if let err = authError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }

    /// True until we've ever successfully read a DayState. Once `dayState` is
    /// non-nil, auth has happened at least once - switch the row to
    /// "Manage in Settings" so the user can revoke.
    private var healthAuthNeeded: Bool { dayState == nil }

    private func openiOSSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Eightful helps you reach your daily 8-point activity target with [Vitality Health](https://www.vitality.co.uk).")
                Text("Not affiliated with, endorsed by, or connected to Vitality Health Insurance. This is an independent tool.")
                Text("Your Health data stays on your device. Eightful reads your step count, workouts and heart rate from Apple Health and does all its calculations locally. Nothing is sent to a server - we don't run one.")
                Text("Eightful only sees what's in Apple Health. Vitality also awards points for activities that sync directly to them - parkrun, partner gyms - so your Vitality total may be higher than what's shown here on those days.")
                Text("Peloton support is experimental: rides recorded with your Apple Watch are detected via the bike's manufacturer tag, and scored on [Vitality's Peloton rules](https://www.vitality.co.uk/support/peloton/faqs/) (20 min minimum, 5 pts / 8 pts with HR). Please report rides that score differently from your Vitality statement.")
                Text("Home-screen widget and Settings tab contributed by [Adrian Lansdown](https://github.com/yayadrian). Thank you.")
                Text("Read more at [whitelabel.org/eightful](https://whitelabel.org/eightful).")
            }
            .font(.footnote)
        }
    }

    private func refresh() async {
        do {
            let state = try await HealthKitReader.shared.currentDayState(settings: store.settings)
            dayState = state
            authError = nil   // clear any previous error on successful read
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            // "Authorization not determined" - user hasn't tapped through the
            // HealthKit sheet yet. Not a real error to surface.
            authError = nil
        } catch {
            authError = "Couldn't read Health data."
        }
        let notif = await UNUserNotificationCenter.current().notificationSettings()
        notificationsAuthorized = notif.authorizationStatus == .authorized
    }

    private func requestHealthAuth() async {
        do {
            try await HealthKitReader.shared.requestAuthorization()
            healthAuthorized = true
            await refresh()
        } catch {
            authError = "Permission request failed - try again in a moment."
        }
    }

    private func requestNotifAuth() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notificationsAuthorized = granted
        } catch {
            authError = "Permission request failed - try again in a moment."
        }
    }
}
