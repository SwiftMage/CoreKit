import SwiftUI
import RevenueCatManager

/// The main application structure for the DemoApp.
/// This app demonstrates the features provided by the CoreKit package.
@main
struct DemoApp: App {
    
    init() {
        // --- Configure CoreKit Modules --- 
        
        // Configure RevenueCat ONCE on app launch
        // IMPORTANT: Replace "YOUR_RC_API_KEY" with your actual 
        // RevenueCat Public API Key (specifically the iOS one). 
        // The demo will not function correctly without a valid key.
        let revenueCatApiKey = "YOUR_RC_API_KEY" // <-- REPLACE THIS!
        if revenueCatApiKey == "YOUR_RC_API_KEY" {
            print("WARNING: RevenueCat API Key not set in DemoApp.swift. RevenueCat features will not work.")
        }
        RevenueCatManager.configure(apiKey: revenueCatApiKey)
        
        // Other module configurations can go here (e.g., DebugLogger levels)
    }
    
    var body: some Scene {
        WindowGroup {
            if #available(iOS 15.0, macOS 12.0, *) {
                ContentView()
            } else {
                Text("DemoApp requires iOS 15+ or macOS 12+")
                    .padding()
            }
        }
    }
} 
