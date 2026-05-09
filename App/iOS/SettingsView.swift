import SwiftUI
import EightfulCore

struct SettingsView: View {
    @ObservedObject private var store = SettingsStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
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
            .navigationTitle("Settings")
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
                Text("Not set in Health - pick your DOB so workout scoring can compute your max heart rate (220 − age).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if showRevert {
                Button("Use Health value") { value = nil }
                    .font(.caption)
            }
        }
    }
}
