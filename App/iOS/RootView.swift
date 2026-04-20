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
                HStack {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: state.steps), number: .decimal))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(state.displayColor.color)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(state.points) pt\(state.points == 1 ? "" : "s")")
                            .font(.headline)
                        Text(state.workoutGreen ? "Workout green" : state.effectiveTier.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private var permissionsSection: some View {
        Section("Permissions") {
            Button {
                Task { await requestHealthAuth() }
            } label: {
                Label("Grant Health access", systemImage: "heart.text.square")
            }
            Button {
                Task { await requestNotifAuth() }
            } label: {
                Label(notificationsAuthorized ? "Notifications on" : "Allow notifications", systemImage: "bell")
            }
            if let err = authError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var settingsSection: some View {
        Section("Settings") {
            Toggle("Notifications", isOn: Binding(
                get: { store.settings.notificationsEnabled },
                set: { val in store.update { $0.notificationsEnabled = val } }
            ))
            TimeOfDayPicker(
                label: "Nudge from",
                value: Binding(
                    get: { store.settings.nudgeStartTime },
                    set: { v in store.update { $0.nudgeStartTime = v } }
                )
            )
            TimeOfDayPicker(
                label: "Daily report at",
                value: Binding(
                    get: { store.settings.reportTime },
                    set: { v in store.update { $0.reportTime = v } }
                )
            )
            DOBOverrideRow(value: Binding(
                get: { store.settings.dobOverride },
                set: { v in store.update { $0.dobOverride = v } }
            ))
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Text("Tracks progress toward Vitality UK's 8-point daily activity target using your Health data. Not affiliated with Vitality.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func refresh() async {
        do {
            let state = try await HealthKitReader.shared.currentDayState(settings: store.settings)
            dayState = state
        } catch {
            authError = String(describing: error)
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
            authError = String(describing: error)
        }
    }

    private func requestNotifAuth() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notificationsAuthorized = granted
        } catch {
            authError = String(describing: error)
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

struct DOBOverrideRow: View {
    @Binding var value: Date?

    var body: some View {
        HStack {
            if let v = value {
                DatePicker("DOB override", selection: Binding(
                    get: { v },
                    set: { value = $0 }
                ), displayedComponents: .date)
                Button("Clear") { value = nil }
                    .font(.caption)
            } else {
                Button("Set DOB override") {
                    value = Calendar.current.date(byAdding: .year, value: -35, to: Date())
                }
                Text("(fallback if Health DOB is missing)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
