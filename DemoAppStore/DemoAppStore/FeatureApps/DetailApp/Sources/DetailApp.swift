import SwiftUI
import PresentationDetail

@main
struct DetailApp: App {
    init() {
        DetailAppDI.register()
    }

    var body: some Scene {
        WindowGroup {
            DetailAppRootView()
        }
    }
}
