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
                settingsSection
                aboutSection
            }
            .navigationTitle("Eightful")
            .task { await refresh() }
        }
    }

    private var statusSection: some View {
        Section("Today") {
            if let state = dayState {
                HStack(alignment: .top) {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: state.steps), number: .decimal))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(state.displayColor.color)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(state.points) pt\(state.points == 1 ? "" : "s")")
                            .font(.headline)
                        Text(state.effectiveTier.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let detail = state.workoutDetail, detail.maxHR > 0 {
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
        let avgBPM = Int(d.avgHR.rounded())
        let pct = Int(d.percentOfMax.rounded())
        HStack(spacing: 8) {
            Image(systemName: "heart.fill").foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("8-point goal reached")
                    .font(.footnote).bold()
                Text("\(name): \(minutes) min at \(pct)% of max HR (\(avgBPM) bpm)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
    /// non-nil, auth has happened at least once — switch the row to
    /// "Manage in Settings" so the user can revoke.
    private var healthAuthNeeded: Bool { dayState == nil }

    private func openiOSSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            Toggle("Send me a nudge", isOn: Binding(
                get: { store.settings.notificationsEnabled },
                set: { val in store.update { $0.notificationsEnabled = val } }
            ))
            TimeOfDayPicker(
                label: "At",
                value: Binding(
                    get: { store.settings.nudgeTime },
                    set: { v in store.update { $0.nudgeTime = v } }
                )
            )
            .disabled(!store.settings.notificationsEnabled)

            DOBRow(
                healthDOB: HealthKitReader.shared.dateOfBirth(),
                value: Binding(
                    get: { store.settings.dobOverride },
                    set: { v in store.update { $0.dobOverride = v } }
                )
            )
        }
    }

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Eightful helps you reach the 8-point daily activity target popular in UK private health insurance activity rewards programmes.")
                Text("Not affiliated with, endorsed by, or connected to Vitality Health Insurance. This is an independent tool.")
                Text("Your Health data stays on your device. Eightful reads your step count, workouts and heart rate from Apple Health and does all its calculations locally. Nothing is sent to a server — we don't run one.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func refresh() async {
        do {
            let state = try await HealthKitReader.shared.currentDayState(settings: store.settings)
            dayState = state
            authError = nil   // clear any previous error on successful read
        } catch let err as NSError where err.domain == "com.apple.healthkit" && err.code == 5 {
            // "Authorization not determined" — user hasn't tapped through the
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
            authError = "Permission request failed — try again in a moment."
        }
    }

    private func requestNotifAuth() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notificationsAuthorized = granted
        } catch {
            authError = "Permission request failed — try again in a moment."
        }
    }
}

struct TimeOfDayPicker: View {
    let label: String
    @Binding var value: TimeOfDay

    var body: some View {
        DatePicker(label, selection: Binding(
            get: {
                let base = Calendar.current.startOfDay(for: Date())
                return Calendar.current.date(byAdding: DateComponents(hour: value.hour, minute: value.minute), to: base) ?? base
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                value = TimeOfDay(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
            }
        ), displayedComponents: .hourAndMinute)
    }
}

/// DOB picker prefilled from HealthKit when available. Editing the picker
/// stores an override; a small "Use Health value" control appears if an
/// override differs from HealthKit's stored DOB.
struct DOBRow: View {
    let healthDOB: Date?
    @Binding var value: Date?

    private var effective: Date {
        value ?? healthDOB ?? Calendar.current.date(byAdding: .year, value: -35, to: Date())!
    }

    private var showRevert: Bool {
        guard let hk = healthDOB, let override = value else { return false }
        return Calendar.current.isDate(override, inSameDayAs: hk) == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DatePicker(
                "Date of birth",
                selection: Binding(
                    get: { effective },
                    set: { newValue in value = newValue }
                ),
                in: ...Date(),
                displayedComponents: .date
            )
            if healthDOB == nil {
                Text("Not set in Health — pick your DOB so workout scoring can compute your max heart rate (220 − age).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if showRevert {
                Button("Use Health value") { value = nil }
                    .font(.caption)
            }
        }
    }
}
