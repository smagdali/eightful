import Foundation
import HealthKit
import UserNotifications
import WidgetKit
import EightfulCore

/// Coordinates HealthKit observer updates with notification delivery.
/// Runs on iPhone where background delivery is more reliable than watchOS.
@MainActor
public final class NotificationScheduler {
    public static let shared = NotificationScheduler()

    private var observer: HKObserverQuery?
    private var isStarted = false

    public func start() {
        guard !isStarted else { return }
        isStarted = true
        observer = HealthKitReader.shared.observeUpdates { [weak self] in
            Task { await self?.evaluate() }
        }
        // Also evaluate on a timer around the report time (in case observer has been quiet).
        scheduleFallbackRefresh()
    }

    public func stop() {
        if let q = observer { HKHealthStore().stop(q) }
        observer = nil
        isStarted = false
    }

    private func scheduleFallbackRefresh() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Eightful"
        content.body = "" // silent trigger; real notification content fires from evaluate()
        content.sound = nil

        let comps = DateComponents(hour: 19, minute: 55) // kicks evaluation ahead of 8pm
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req = UNNotificationRequest(identifier: "eightful.fallback.evaluate", content: content, trigger: trigger)
        // The notification itself does nothing visible; observer-driven evaluation is the real path.
        // Keep silent/low-noise: we just rely on HKObserverQuery which iOS typically delivers reliably.
        center.add(req, withCompletionHandler: nil)
    }

    public func evaluate(now: Date = Date()) async {
        let settings = SettingsStore.shared.settings
        guard settings.notificationsEnabled else { return }

        let history = HistoryStore.shared.load(now: now)
        let state: DayState
        do {
            state = try await HealthKitReader.shared.currentDayState(settings: settings, now: now)
        } catch {
            return
        }

        // Update complication timelines (watchOS widget kit relay).
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

        let action = NotificationDecision.evaluate(
            state: state,
            now: now,
            settings: settings,
            history: history
        )

        switch action {
        case .suppress:
            return
        case .nudge(let zone):
            guard let msg = Optional(NotificationCopy.nudge(zone: zone, steps: state.steps)) else { return }
            await deliver(title: msg.title, body: msg.body, id: "eightful.nudge.\(zone.rawValue)")
            HistoryStore.shared.save(history.markingNudged(zone))
        case .report(let s):
            guard let msg = NotificationCopy.message(for: .report(s)) else { return }
            await deliver(title: msg.title, body: msg.body, id: "eightful.report")
            HistoryStore.shared.save(history.markingReported())
        }
    }

    private func deliver(title: String, body: String, id: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        do { try await UNUserNotificationCenter.current().add(req) } catch { /* noop */ }
    }
}
