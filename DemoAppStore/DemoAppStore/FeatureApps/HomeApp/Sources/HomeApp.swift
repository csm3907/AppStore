import SwiftUI
import PresentationHome

@main
struct HomeApp: App {
    init() {
        HomeAppDI.register()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
