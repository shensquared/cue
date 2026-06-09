import SwiftUI

@main
struct CommentatorWatchApp: App {
    @StateObject private var coordinator = WatchCoordinator()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(coordinator)
                .onAppear { coordinator.activate() }
        }
    }
}
