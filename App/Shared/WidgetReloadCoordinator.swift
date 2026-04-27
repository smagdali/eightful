import Foundation

/// Debounces WidgetCenter.reloadAllTimelines to keep us inside Apple's
/// rough daily reload budget (40-70/day observed). The caller separately
/// decides when to reload on "material change" (tier/zone crossing);
/// this coordinator only adds an idle-fallback so the complication
/// doesn't go totally stale while the user walks inside the same band.
public final class WidgetReloadCoordinator {
    public static let shared = WidgetReloadCoordinator()

    private let defaults: UserDefaults
    private enum Key { static let lastReload = "eightful.widgetReload.v1" }

    /// Fallback interval - minimum time between "nothing interesting
    /// changed" reloads. 15 min keeps us at most ~96 reloads/day, well
    /// inside Apple's budget and plenty fresh.
    public let idleFallback: TimeInterval = 15 * 60

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var lastReload: Date? {
        defaults.object(forKey: Key.lastReload) as? Date
    }

    public func shouldReloadOnIdle(now: Date = Date()) -> Bool {
        guard let last = lastReload else { return true }
        return now.timeIntervalSince(last) >= idleFallback
    }

    public func markReloaded(at date: Date = Date()) {
        defaults.set(date, forKey: Key.lastReload)
    }
}
