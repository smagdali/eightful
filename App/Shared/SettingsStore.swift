import Foundation
import Combine
import EightfulCore

/// Persists AppSettings to UserDefaults (via App Group on real devices) and publishes changes.
/// On iOS, the store also relays settings to the paired Watch via WatchConnectivity.
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()

    private enum Key {
        static let settings = "eightful.settings.v1"
    }

    private let defaults: UserDefaults

    @Published public private(set) var settings: AppSettings

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = Self.load(from: defaults) ?? .default
    }

    private static func load(from defaults: UserDefaults) -> AppSettings? {
        guard let data = defaults.data(forKey: Key.settings) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    public func update(_ mutation: (inout AppSettings) -> Void) {
        var copy = settings
        mutation(&copy)
        save(copy)
    }

    public func replace(with newSettings: AppSettings) { save(newSettings) }

    private func save(_ newSettings: AppSettings) {
        settings = newSettings
        if let data = try? JSONEncoder().encode(newSettings) {
            defaults.set(data, forKey: Key.settings)
        }
    }
}
