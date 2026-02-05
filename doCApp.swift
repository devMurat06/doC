import SwiftUI

@main
struct doCApp: App {
    @StateObject private var dataManager = DataManager()
    @State private var isUnlocked = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if dataManager.settings.pinEnabled && !isUnlocked {
                    PINLockView(isUnlocked: $isUnlocked)
                        .environmentObject(dataManager)
                } else {
                    ContentView()
                        .environmentObject(dataManager)
                        .preferredColorScheme(dataManager.settings.isDarkMode ? .dark : .light)
                }
            }
            .onAppear {
                // If PIN not enabled, unlock immediately
                if !dataManager.settings.pinEnabled {
                    isUnlocked = true
                }
            }
        }
    }
}
