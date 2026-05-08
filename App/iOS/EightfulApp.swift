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
        // (separate process) renders the same canned state, then poke the widget.
        ScreenshotMode.syncFromLaunchArguments()
        WidgetCenter.shared.reloadAllTimelines()
        NotificationScheduler.shared.start()
        return true
    }
}
