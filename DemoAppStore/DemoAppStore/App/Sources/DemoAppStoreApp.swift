import SwiftUI
import PresentationHome
import PresentationDetail

@main
struct DemoAppStoreApp: App {
    init() {
        AppDI.register()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
