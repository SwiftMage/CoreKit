import SwiftUI
import Settings // Import Settings module
import DebugTools // For logging if needed

/// A screen demonstrating the CoreKit Settings module.
@available(iOS 15.0, macOS 12.0, *) // Match ContentView availability for simplicity
struct DemoSettingsScreen: View {
    
    // --- State for Settings Demo ---
    @State private var demoToggleIsOn: Bool = false
    @State private var showingAlert: Bool = false
    @AppStorage("demoAppUsername") private var username: String = "DefaultUser"
    
    // Define the URL constant outside the body
    private let googleURL = URL(string: "https://www.google.com")
    
    var body: some View {
        // Use the actual SettingsView component
        SettingsView(navigationTitle: "Demo Settings") {
            // Section 1: Basic Items
            SettingsSection(title: "Examples", footer: "Demonstrates various item types.") {
                // Example Toggle Item
                SettingsToggleItem(title: "Demo Toggle", iconName: "switch.2", isOn: $demoToggleIsOn)
                
                // Example Link Item (navigating within the app)
                SettingsLinkItem(title: "Show Detail View", iconName: "doc.text", destination: DemoDetailView(title: "Settings Detail"))
                
                // Conditionally add External Link Item using a standard `if` check
                // Temporarily removed due to compiler error
                /*
                if let url = googleURL {
                    SettingsExternalLinkItem(title: "Visit Google", iconName: "safari.fill", url: url)
                }
                */
                
                // Example Button Item (performs an action)
                SettingsButtonItem(title: "Trigger Action", iconName: "play.circle", iconColor: .green) {
                    print("Settings Button Item Tapped!")
                    showingAlert = true
                }
            }
            
            // Section 2: AppStorage Example (Temporarily commented out to debug compiler error)
            /*
            SettingsSection(title: "Persistence") {
                // Displaying AppStorage value requires a specific SettingsItem or direct View
                // For this demo, we'll just show the reset button.
                // Removed direct HStack and TextField usage as they don't conform to SettingsItem.
                // To make AppStorage editable here, create a custom SettingsItem struct 
                // that wraps a TextField and conforms to the SettingsItem protocol.
                
                // Example: Button to reset username
                SettingsButtonItem(title: "Reset Username", iconName: "arrow.counterclockwise", iconColor: .orange) {
                    username = "DefaultUser"
                    DebugLogger.log("Demo username reset via Settings.")
                }
            }
            */
        }
        // Apply onChange to the SettingsView itself
        .onChange(of: demoToggleIsOn) { newValue in
             DebugLogger.ui("Setting 'Demo Toggle' changed to: \(newValue)")
        }
        // Alert modifier attached to the SettingsView content
        .alert("Button Tapped", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The settings button action was triggered.")
        }
    }
}

// Preview for DemoSettingsScreen
#Preview {
     if #available(iOS 15.0, macOS 12.0, *) {
         // Embed in NavigationView for preview context
         NavigationView {
             DemoSettingsScreen()
         }
     } else {
         Text("Preview requires iOS 15+ or macOS 12+")
     }
} 