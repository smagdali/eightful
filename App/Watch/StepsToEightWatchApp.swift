import SwiftUI
import HealthKit
import WidgetKit

@main
struct StepsToEightWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup { WatchRootView() }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        Task {
            try? await HealthKitReader.shared.requestAuthorization()
            _ = HealthKitReader.shared.observeUpdates {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
