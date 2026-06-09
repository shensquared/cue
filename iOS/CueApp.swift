import SwiftUI

@main
struct CueApp: App {
    @StateObject private var coordinator = PhoneCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .onAppear { coordinator.activate() }
        }
    }
}
