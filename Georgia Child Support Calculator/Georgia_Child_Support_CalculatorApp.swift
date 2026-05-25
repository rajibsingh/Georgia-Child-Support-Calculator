import SwiftUI

@main
struct WorkingNumbersApp: App {
    @State private var showWelcome = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                if showWelcome {
                    WelcomeView {
                        showWelcome = false
                    }
                }
            }
        }
    }
}
