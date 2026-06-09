import SwiftUI

@main
struct CueWatchApp: App {
    @StateObject private var coordinator = WatchCoordinator()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(coordinator)
                .onAppear { coordinator.activate() }
        }
    }
}
