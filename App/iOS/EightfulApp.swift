import SwiftUI
import HealthKit
import UserNotifications
import WidgetKit

@main
struct EightfulApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup { MainTabView() }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Mirror --screenshots into App Group defaults so the widget extension
        // (separate process) renders the same canned state. Only nudge the
        // widget when something might actually have changed (flag flipped, or
        // we're outside the idle-debounce window), to stay inside Apple's
        // ~40-70/day reload budget.
        let flagChanged = ScreenshotMode.syncFromLaunchArguments()
        if flagChanged || WidgetReloadCoordinator.shared.shouldReloadOnIdle() {
            WidgetCenter.shared.reloadAllTimelines()
            WidgetReloadCoordinator.shared.markReloaded()
        }
        NotificationScheduler.shared.start()
        return true
    }
}
