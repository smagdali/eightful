import SwiftUI
import HealthKit
import WidgetKit

@main
struct EightfulWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup { WatchRootView() }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Intentionally no HKObserverQuery here. Without the
        // healthkit.background-delivery entitlement (which we do NOT
        // grant on the watch to save battery) observers only fire
        // foreground anyway — in which case WatchRootView's scenePhase
        // + adaptive refresh already handle it. The observer here was
        // spawning the widget extension on every step-sample batch and
        // burning battery.
        Task { try? await HealthKitReader.shared.requestAuthorization() }
    }
}
