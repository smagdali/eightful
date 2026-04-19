import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            RootView()
                .tabItem { Label("Today", systemImage: "figure.walk") }
            ReconciliationView()
                .tabItem { Label("Compare", systemImage: "chart.bar.doc.horizontal") }
        }
    }
}
