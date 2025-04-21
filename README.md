# CoreKit Swift Package

This package provides reusable core components for the ios applications, including onboarding, settings UI, notification management, review prompts, and RevenueCat integration.

## Modules

*   **DebugTools:** Provides a centralized logging system (`DebugLogger`) using OSLog.
*   **ThemeManager:** Provides theme constants and helpers (`AppTheme`).
*   **Onboarding:** Provides a framework (`OnboardingManager`, `OnboardingView`, `OnboardingStep` protocol) for creating custom onboarding flows.
*   **Settings:** Provides a SwiftUI view (`SettingsView`) and data structures (`SettingsSection`, `SettingsItem`) for building declaration settings screens.
*   **NotificationManager:** Provides a service (`NotificationService`) for requesting permissions and scheduling local notifications.
*   **ReviewManager:** Provides functions (`incrementSignificantEventCount`, `requestReviewIfNeeded`) to manage prompting users for App Store reviews.
*   **RevenueCatManager:** Provides a manager class (`RevenueCatManager`) to interact with the RevenueCat SDK for fetching offerings, making purchases, and checking subscription status.
*   **UserProfile:** (Placeholder) Intended for managing user profile data (persistence likely handled by the main app).

## Requirements

*   iOS 15.0+
*   Swift 5.9+
*   Xcode 15+

## Dependencies

*   [RevenueCat/purchases-ios](https://github.com/RevenueCat/purchases-ios) (v4.0.0+)

---

## Usage Examples

Below are examples demonstrating how to use the main components of CoreKit from your application target.

---

### DebugLogger (`DebugTools`)

```swift
import CoreKit // Import the whole package
// Or: import DebugTools // Import just the module

// --- Basic Logging ---
DebugLogger.log("This is a general debug message.")
DebugLogger.log("User profile loaded.", level: .info)
DebugLogger.log("Network request failed!", level: .error)

// --- Using Convenience Functions ---
DebugLogger.onboarding("Showing welcome step.")
DebugLogger.review("Significant event threshold met.", level: .info)
DebugLogger.notification("Notification permission granted.", level: .info)
DebugLogger.revenueCat("Fetching offerings.", level: .debug)

// --- Function Tracing ---
func myImportantFunction() throws {
    // Automatically logs entry and exit
    try DebugLogger.trace {
        DebugLogger.log("Doing important work...")
        // ... function body ...
        if Bool.random() { throw MyError.someError }
    }
}

enum MyError: Error { case someError }

// --- Configuration (Optional - Usually done once at app start) ---
// Show only warnings and errors:
// DebugLogger.enabledLogLevels = [.warning, .error]
// Disable function tracing globally:
// DebugLogger.isTracingEnabled = false
```

### Why Use `DebugLogger` Instead of `print()`?

While `print()` is simple for quick debugging, `DebugLogger` (built on Apple's `OSLog`) offers significant advantages for building robust, maintainable applications:

*   **Structured Levels:** Log messages have levels (`debug`, `info`, `warning`, `error`). You can filter logs by severity in Console.app to focus on critical issues.
*   **Categorization:** Logs are grouped by subsystem (your app) and category (e.g., `Network`, `Onboarding`, `UI`). This allows you to easily isolate logs from specific features.
*   **Performance:** `OSLog` is highly performant. Messages for log levels or categories that are disabled have negligible overhead, making it safe to leave detailed logs in your code, even in release builds (if desired levels are disabled). `print()` statements have more overhead.
*   **System Console Integration:** Logs appear in the standard macOS `Console.app`. This allows you to view and filter logs from your app (and the system) on connected devices *without* needing Xcode attached. Essential for diagnosing issues in TestFlight builds or when debugging complex interactions.
*   **Configuration:** Log levels can be controlled dynamically (e.g., via environment variables or configuration profiles, though our current `DebugLogger` uses a static set). This allows enabling more verbose logging for specific debugging sessions without recompiling.
*   **Context:** Automatically includes useful metadata like timestamps and thread IDs (managed by the system logger). Our implementation also adds file/function/line.


---

### Onboarding (`Onboarding`)

```swift
import SwiftUI
import CoreKit // Or import Onboarding

// 1. Define your custom step views in your App Target
struct MyAppWelcomeStep: OnboardingStep {
    var id = "myAppWelcome"
    var title = "Welcome to Power Words!"
    var description = "Let's get started with positive affirmations."
    var imageName: String? = "sparkles"

    var body: some View {
        VStack { /* Your custom layout */
            Text(title).font(.largeTitle)
            if let imageName = imageName { Image(systemName: imageName).font(.largeTitle).padding() }
            Text(description)
        }
    }
}

struct MyAppFeatureStep: OnboardingStep {
    var id = "myAppFeatures"
    var title = "Discover Features"
    var description = "Learn how to create and manage your words."
    var imageName: String? = "wand.and.stars"

    var body: some View {
        VStack { /* Your custom layout */
             Text(title).font(.largeTitle)
             if let imageName = imageName { Image(systemName: imageName).font(.largeTitle).padding() }
             Text(description)
        }
    }
}

// 2. In your App's View hierarchy (e.g., ContentView or App struct)

struct MainAppView: View {
    @State private var showOnboarding = !OnboardingManager().isOnboardingComplete // Check initial state
    
    // Create the manager instance and provide *your* custom steps
    @StateObject private var onboardingManager = OnboardingManager(steps: [
        MyAppWelcomeStep(),
        MyAppFeatureStep()
        // Add other steps here
    ])

    var body: some View {
        YourMainAppContent()
            .fullScreenCover(isPresented: $showOnboarding) {
                // Onboarding is complete (or skipped)
                print("Onboarding finished, dismissing cover.")
            } content: {
                OnboardingView(manager: onboardingManager, allowSkip: true) {
                    // This is the onComplete closure from OnboardingView
                    showOnboarding = false // Dismiss the view
                }
            }
            // Or use .sheet instead of .fullScreenCover
    }
}

struct YourMainAppContent: View {
    var body: some View { Text("Main App Content") }
}
```

---

### RevenueCatManager (`RevenueCatManager`)

```swift
import SwiftUI
import CoreKit // Or import RevenueCatManager
import RevenueCat // Needed for Package type

struct PremiumView: View {
    // Get the manager instance (e.g., via @EnvironmentObject or @StateObject)
    @StateObject private var revenueCatManager = RevenueCatManager()
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            if revenueCatManager.isLoading {
                ProgressView()
            } else if revenueCatManager.isSubscriptionActive {
                Text("You have Premium!")
                // Show premium features
            } else {
                Text("Unlock Premium Features")
                
                // Display Offerings (example)
                if let offerings = revenueCatManager.offerings {
                    if let currentOffering = offerings.current {
                        ForEach(currentOffering.availablePackages) { package in
                            Button {
                                purchase(package: package)
                            } label: {
                                Text("\(package.storeProduct.localizedTitle) - \(package.storeProduct.localizedPriceString)")
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom)
                        }
                    } else {
                         Text("No current offering found.")
                    }
                } else {
                    Text("Loading plans...")
                }
                
                Button("Restore Purchases") {
                    restore()
                }
            }
        }
        .task { // Use .task for async work on view appear
            // Ensure SDK is configured (do this once at app launch)
            // RevenueCatManager.configure(apiKey: "YOUR_REVENUECAT_API_KEY") // Done in AppDelegate/App struct ideally

            await revenueCatManager.checkSubscriptionStatus()
            await revenueCatManager.fetchOfferings()
        }
        .alert("Error", isPresented: $showErrorAlert) {
             Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    func purchase(package: Package) {
        Task {
            do {
                _ = try await revenueCatManager.purchase(package: package)
                // Purchase successful, state updated automatically by manager (ideally via listener)
                // Or re-check status here if needed
            } catch {
                alertMessage = "Purchase failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
    
    func restore() {
         Task {
            do {
                _ = try await revenueCatManager.restorePurchases()
                 // Restore successful, state updated
                 alertMessage = "Purchases Restored!" // Example success feedback
                 showErrorAlert = true // Re-using alert for simplicity
            } catch {
                alertMessage = "Restore failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}

// --- In your App Delegate or App struct ---
import CoreKit // Or import RevenueCatManager

@main
struct PowerWordsApp: App {
    init() {
        // Configure RevenueCat ONCE on app launch
        RevenueCatManager.configure(apiKey: "YOUR_REVENUECAT_PUBLIC_API_KEY")
    }

    var body: some Scene {
        WindowGroup {
            // ... your main view ...
        }
    }
}
```
*Remember to replace `"premium"` in `RevenueCatManager.swift`'s `updateSubscriptionStatus` function with your actual RevenueCat Entitlement ID.*

---

### ReviewManager (`ReviewManager`)

```swift
import CoreKit // Or import ReviewManager

// --- Somewhere in your app logic (e.g., ViewModel or View action) ---

// Call this when a significant positive event happens for the user
// e.g., completing a task, achieving a goal, using a key feature 5 times etc.
ReviewManager.incrementSignificantEventCount()

// Call this occasionally at logical points where a review prompt
// wouldn't interrupt the user excessively (e.g., after finishing a task,
// NOT during an animation or multi-step process).
// The function contains its own logic to decide IF it should prompt.
ReviewManager.requestReviewIfNeeded()

// --- Optional: Resetting (for testing) ---
// ReviewManager.resetReviewRequestData()
```

---

### NotificationService (`NotificationManager`)

```swift
import CoreKit // Or import NotificationManager
import UserNotifications // Still needed for UNAuthorizationStatus etc.

// --- Typically called early in the app lifecycle (e.g., AppDelegate or on appear) ---
func setupNotifications() {
    NotificationService.shared.checkAuthorizationStatus { status in
        if status == .notDetermined {
            NotificationService.shared.requestAuthorization { granted, error in
                if granted {
                    print("Notifications Authorized!")
                    // Register for remote notifications if needed (UIApplication.shared.registerForRemoteNotifications())
                } else if let error = error {
                     print("Notification authorization error: \(error.localizedDescription)")
                } else {
                    print("Notifications Denied.")
                }
            }
        } else if status == .authorized {
             print("Notifications already authorized.")
             // Register for remote notifications if needed
        } else {
             print("Notifications are denied or restricted.")
        }
    }
}

// --- Scheduling a local notification ---
func scheduleReminder() {
    NotificationService.shared.scheduleLocalNotification(
        identifier: "dailyReminder",
        title: "Power Words Practice",
        body: "Time for your daily affirmation practice!",
        timeInterval: 60, // e.g., 60 seconds from now (use CalendarNotificationTrigger for specific times)
        repeats: false
    )
}

// --- Cancelling a notification ---
func cancelReminder() {
    NotificationService.shared.cancelNotification(identifier: "dailyReminder")
}

// --- Handling Notification Delegate Callbacks ---
// If you need custom foreground presentation or response handling beyond
// what's default in NotificationService, you need to set your app's own
// UNUserNotificationCenter delegate (e.g., in AppDelegate) AFTER CoreKit's
// setup, or provide delegate methods within NotificationService if that suits your design.
// Example in AppDelegate:
// UNUserNotificationCenter.current().delegate = self // In didFinishLaunching...
// Then implement the delegate methods in AppDelegate.
```

---

### SettingsView (`Settings`)

```swift
import SwiftUI
import CoreKit // Or import Settings

struct AppSettingsView: View {
    // Example state variables for your app's settings
    @AppStorage("username") private var username: String = ""
    @State private var enableFeatureX = true
    @State private var showingResetAlert = false
    
    // Assume you have an instance of OnboardingManager if needed
    // @EnvironmentObject var onboardingManager: OnboardingManager // If passed via environment
    @StateObject var onboardingManager = OnboardingManager() // Or create if owned here

    var body: some View {
        // Use CoreKit's SettingsView, providing sections and items
        SettingsView(navigationTitle: "App Settings") {
            // Section 1: Account
            SettingsSection(title: "Account") {
                 // If you need complex views like TextField, they might need
                 // custom SettingsItem types or be placed directly in the Form
                 // For simplicity here, using standard items:
                 SettingsLinkItem(title: "Edit Profile", iconName: "person.fill", destination: EditProfileView())
            }
            
            // Section 2: Features
            SettingsSection(title: "Features") {
                SettingsToggleItem(title: "Enable Feature X", iconName: "star.fill", isOn: $enableFeatureX)
                // Add other feature toggles...
            }

            // Section 3: Data Management
             SettingsSection(title: "Data") {
                 SettingsButtonItem(title: "Reset Onboarding", iconName: "arrow.counterclockwise.circle", iconColor: .orange) {
                     showingResetAlert = true
                 }
                 // Add other buttons like "Clear Cache", "Export Data" etc.
             }
             
             // Section 4: About & Support
             SettingsSection(title: "About") {
                 SettingsExternalLinkItem(title: "Privacy Policy", iconName: "lock.shield.fill", url: URL(string: "https://yoursite.com/privacy")!)
                 SettingsExternalLinkItem(title: "Terms of Service", iconName: "doc.text.fill", url: URL(string: "https://yoursite.com/terms")!)
                 SettingsLinkItem(title: "About This App", iconName: "info.circle.fill", destination: AboutAppView())
             }
        }
        .alert("Reset Onboarding?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                Task { @MainActor in // Ensure UI updates on main thread
                    onboardingManager.resetOnboardingState()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// Placeholder destination views
struct EditProfileView: View { var body: some View { Text("Edit Profile Screen") } }
struct AboutAppView: View { var body: some View { Text("About App Screen") } }

#Preview {
    AppSettingsView()
}
```

---

### UserProfileManager (`UserProfile`)

Manages the user's profile data, including persistence and access.

```swift
import SwiftUI
import CoreKit // Or UserProfile

struct ProfileView: View {
    // Get the manager instance (e.g., via @EnvironmentObject or @StateObject)
    @StateObject private var profileManager = UserProfileManager()
    @State private var newName: String = ""

    var body: some View {
        VStack {
            if let user = profileManager.currentUser {
                Text("User ID: \(user.id)")
                Text("Name: \(user.name ?? "N/A")")
                Text("Email: \(user.email ?? "N/A")")
                Text("Member Since: \(user.creationDate, style: .date)")
                
                TextField("New Name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    
                Button("Update Name") {
                    if !newName.isEmpty {
                        profileManager.updateUserProfile(name: newName)
                        newName = "" // Clear field
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Set Last Login") {
                     profileManager.updateUserProfile(lastLoginDate: Date())
                }
                .buttonStyle(.bordered)
                
                Button("Clear Profile (Logout)") {
                    profileManager.clearCurrentUser()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.top)
                
            } else {
                Text("No user profile loaded.")
                Button("Create Default Profile") {
                     let defaultProfile = UserProfile(name: "Demo User")
                     profileManager.setCurrentUser(defaultProfile)
                }
            }
        }
        .padding()
    }
}
```

---

## 🛠️ Installation

### Add via Xcode

1. In Xcode, open your app project.
2. Go to **File > Add Packages...**
3. Enter the local path or Git URL to CoreKit (e.g., `/path/to/CoreKit` or `https://github.com/yourname/CoreKit.git`).
4. Select the `CoreKit` package product.
5. Choose the specific library targets (modules) you want to include in your app from the list provided.

### Add via Package.swift

Add `CoreKit` as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(path: "../CoreKit") // Or use .package(url: "https://...", from: "1.0.0")
],
targets: [
    .target(
        name: "YourAppTarget",
        dependencies: [
            .product(name: "Onboarding", package: "CoreKit"),
            .product(name: "UserProfile", package: "CoreKit"),
            // Add other CoreKit modules as needed
        ]
    )
]
```

---

## ⚙️ Configuration

Before using certain modules, you might need to configure them with app-specific details (like API keys or branding). A central configuration object or individual module setup functions will be provided.

```swift
// Example (Conceptual - actual API may differ)
import CoreKit
import RevenueCatManager
import DebugTools

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Configure RevenueCat
    RevenueCatManager.configure(apiKey: "your_revenuecat_api_key")
    
    // Configure Debug Tools (e.g., enable logging)
    DebugTools.setup(logLevel: .debug)
    
    // ... rest of your setup
    return true
}
```

---

## 📦 Usage Example

### Importing and Using a Module

```swift
import SwiftUI
import Onboarding // Import the specific module
import UserProfile

struct ContentView: View {
    @StateObject var userProfileManager = UserProfileManager() // Example
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome, \(userProfileManager.currentUser?.name ?? "Guest")")
                // ... your app content
            }
            .navigationTitle("My App")
        }
        .onAppear {
            if !userProfileManager.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            // Present the Onboarding flow provided by the module
            OnboardingView { // Example View from Onboarding module
                // Action on completion
                userProfileManager.markOnboardingComplete()
                showOnboarding = false
            }
        }
    }
}
```

---

## 🏗️ Contribution

Contributions are welcome! Please follow the existing module structure:

1.  **Create a new folder** under `Sources/` for your module (e.g., `Sources/NewFeature`).
2.  **Add a corresponding target** in `Package.swift`.
3.  **Add a test target** under `Tests/` (e.g., `Tests/NewFeatureTests`).
4.  **Ensure the module is decoupled** and uses `Utilities` or other CoreKit modules where appropriate.
5.  **Include a README** within the module's source folder if necessary.
6.  **Write unit tests** with good coverage.
7.  **Update this main README** to include the new module. 
