import SwiftUI
import DebugTools
import RevenueCatManager
import ReviewManager
import NotificationManager
import Onboarding
import ThemeManager

// Import the specific module target needed

// Settings module is now used in DemoSettingsScreen, not directly here.
// import Settings

/// A placeholder detail view for SettingsLinkItem navigation.
@available(iOS 14.0, macOS 11.0, *) // Keep for DemoSettingsScreen link
struct DemoDetailView: View {
    let title: String
    
    var body: some View {
        Text("Detail View for \(title)")
            .navigationTitle(title)
    }
}

// MARK: - ViewModel for Review Section

@MainActor // Ensure UI updates happen on the main thread
class ReviewSectionViewModel: ObservableObject {
    // Use the same UserDefaults key as ReviewManager
    private let userDefaultsKey = "significantEventCount"

    @Published var significantEventCount: Int
    @Published var reviewEventThreshold: Int
    @Published var reviewDaysThreshold: Int // Add state for days threshold

    init() {
        // Initialize from UserDefaults and current ReviewManager config
        self.significantEventCount = UserDefaults.standard.integer(forKey: userDefaultsKey)
        let currentConfig = ReviewManager.configuration
        self.reviewEventThreshold = currentConfig.minSignificantEvents
        self.reviewDaysThreshold = currentConfig.minDaysSinceFirstLaunch // Initialize days
        
        // Observe UserDefaults changes externally (e.g., from ReviewManager)
        // Note: This requires a more robust observation mechanism than shown here 
        // for perfect sync if UserDefaults is changed by completely separate processes.
        // For this demo app, manually syncing after ReviewManager calls is sufficient.
        DebugLogger.review("ReviewSectionViewModel initialized. Count: \(significantEventCount), Events Threshold: \(reviewEventThreshold), Days Threshold: \(reviewDaysThreshold)", level: .trace)
    }

    // Function to be called after ReviewManager updates UserDefaults
    func syncEventCountFromUserDefaults() {
        let newCount = UserDefaults.standard.integer(forKey: userDefaultsKey)
        if newCount != significantEventCount { // Only update if changed
            significantEventCount = newCount
            DebugLogger.review("ViewModel synced event count from UserDefaults: \(newCount)", level: .trace)
        }
    }

    // Function to update the review threshold in ReviewManager
    func updateReviewThreshold(_ newValue: Int) {
        guard newValue != reviewEventThreshold else { return } // Avoid unnecessary updates
        
        reviewEventThreshold = newValue
        
        let newConfig = ReviewConfiguration(
            minSignificantEvents: newValue,
            minDaysSinceFirstLaunch: self.reviewDaysThreshold // Preserve current days value
        )
        ReviewManager.configuration = newConfig
        DebugLogger.review("ViewModel updated ReviewManager events threshold to \(newValue)", level: .debug)
    }
    
    // Function to update the review days threshold in ReviewManager
    func updateReviewDaysThreshold(_ newValue: Int) {
        guard newValue != reviewDaysThreshold else { return } // Avoid unnecessary updates
        
        reviewDaysThreshold = newValue
        
        let newConfig = ReviewConfiguration(
            minSignificantEvents: self.reviewEventThreshold, // Preserve current events value
            minDaysSinceFirstLaunch: newValue
        )
        ReviewManager.configuration = newConfig
        DebugLogger.review("ViewModel updated ReviewManager days threshold to \(newValue)", level: .debug)
    }
}

/// The main view for the DemoApp.
/// Added @available for macOS 12+ due to Section/onChange usage.
/// Note: Previews require macOS 13+ or iOS 17+.
@available(iOS 15.0, macOS 12.0, *) 
struct ContentView: View {
    // State variable to toggle function tracing in DebugLogger
    @State private var isTracingEnabled: Bool = DebugLogger.isTracingEnabled

    // --- State for Onboarding Demo ---
    // Create the manager instance with our demo steps
    @StateObject private var onboardingManager = OnboardingManager(steps: [
        DemoStep1(), DemoStep2(), DemoStep3()
    ])
    // State to control the presentation of the onboarding sheet
    @State private var showOnboardingSheet: Bool = false

    // ViewModel for the Review Section
    @StateObject private var reviewViewModel = ReviewSectionViewModel()

    // State for Notification Manager Demo
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    private let demoNotificationId = "coreKitDemoNotification"
    @State private var enableCloudKitDemo: Bool = false // Add state for CloudKit toggle

    var body: some View {
        NavigationView {
            List {
                Text("CoreKit Feature Examples").font(.headline)
                
                // --- Call Section Views ---
                debugToolsSection
                settingsSectionLink
                onboardingSection
                reviewManagerSection
                notificationManagerSection
                themeManagerSection
                userProfileSection
                revenueCatSectionLink
                examplePlaceholderSection // Keep the placeholder distinct
            }
            .navigationTitle("CoreKit Demo")
            .onChange(of: isTracingEnabled) { newValue in
                 DebugLogger.isTracingEnabled = newValue
                 DebugLogger.log("Function tracing toggled: \(newValue)", level: .info)
            }
        }
        .sheet(isPresented: $showOnboardingSheet, onDismiss: {
            // Mark onboarding as complete when the sheet is dismissed
            // (either by finishing or swiping down)
            if !onboardingManager.isOnboardingComplete {
                 DebugLogger.onboarding("Onboarding sheet dismissed, calling completeOnboarding.")
                 onboardingManager.completeOnboarding() // Use the correct method
            }
        }) { 
            // Present the OnboardingContainerView
            OnboardingContainerView(steps: onboardingManager.steps) {
                // This is the onFinish action from the container's button
                 DebugLogger.onboarding("Onboarding finished via button tap, calling completeOnboarding.")
                 onboardingManager.completeOnboarding() // Use the correct method
                 showOnboardingSheet = false // Dismiss the sheet
            }
        }
        .onAppear {
            // checkOnboardingStatus() // Removed automatic triggering
            checkNotificationStatus()
        }
        .task {
            await checkNotificationStatusAsync()
        }
    }
    
    // --- Computed View Properties for Sections ---
    
    @available(iOS 15.0, macOS 12.0, *) 
    private var debugToolsSection: some View {
        Section("Debug Tools (DebugLogger)") {
             Text("Use DebugLogger to output categorized and leveled logs via OSLog. Check your Xcode console or the Console app.")
                 .font(.caption)
             Button("Log General Debug") { logGeneralDebug() }
             Button("Log Network Info") { logNetworkInfo() }
             Button("Log UI Warning") { logUIWarning() }
             Button("Log CoreData Error") { logCoreDataError() }
             Button("Log Review Message") { logReviewMessage() }
             Button("Log Notification Message") { logNotificationMessage() }
             Button("Log RevenueCat Message") { logRevenueCatMessage() }
             Button("Trigger Trace Example Function") { exampleTraceFunction() }
             Toggle("Enable Function Tracing", isOn: $isTracingEnabled)
        }
    }
    
    @available(iOS 15.0, macOS 12.0, *) 
    private var settingsSectionLink: some View {
         Section("Settings Module") {
             NavigationLink("Show Settings Demo") {
                 DemoSettingsScreen()
             }
         }
    }
    
    @available(iOS 15.0, macOS 12.0, *) 
    private var onboardingSection: some View {
         Section("Onboarding Module") {
             Button("Show Onboarding Flow") {
                 if onboardingManager.isOnboardingComplete {
                     onboardingManager.resetOnboardingState()
                 }
                 showOnboardingSheet = true
             }
             Button("Reset Onboarding State (for testing)") {
                 onboardingManager.resetOnboardingState()
             }
             Text("Onboarding Complete: \(onboardingManager.isOnboardingComplete ? "Yes" : "No")")
                 .font(.caption).foregroundColor(.gray)
         }
    }
    
    @ViewBuilder
    private var reviewManagerSection: some View {
        Section("Review Manager") {
            #if canImport(UIKit)
            Text("Manages StoreKit review requests based on events and time.")
                 .font(.caption)
            Text("Current Significant Event Count: \(reviewViewModel.significantEventCount)")
                 .font(.footnote)

            Stepper("Min Events Threshold: \(reviewViewModel.reviewEventThreshold)", 
                    value: $reviewViewModel.reviewEventThreshold, 
                    in: 1...20) // Range 1 to 20 for demo
                .onChange(of: reviewViewModel.reviewEventThreshold) { newValue in
                    reviewViewModel.updateReviewThreshold(newValue)
                }

            // Add Stepper for Min Days Threshold
            Stepper("Min Days Threshold (0=disabled): \(reviewViewModel.reviewDaysThreshold)",
                    value: $reviewViewModel.reviewDaysThreshold,
                    in: 0...30) // Range 0 to 30 for demo
                .onChange(of: reviewViewModel.reviewDaysThreshold) { newValue in
                    reviewViewModel.updateReviewDaysThreshold(newValue)
                }

            Button("Increment Significant Event") {
                ReviewManager.incrementSignificantEventCount()
                reviewViewModel.syncEventCountFromUserDefaults()
                
                ReviewManager.requestReviewIfNeeded()
            }
            Button("Request Review If Needed") {
                ReviewManager.requestReviewIfNeeded()
            }
            Button("Reset Review Data (for testing)") {
                ReviewManager.resetReviewRequestData()
                reviewViewModel.syncEventCountFromUserDefaults()
            }
            #else
            Text("ReviewManager requires UIKit (iOS, tvOS, visionOS) to function fully.")
                 .font(.caption)
                 .foregroundColor(.gray)
            #endif
        }
    }
    
    private var notificationManagerSection: some View {
        Section("Notification Manager") {
             Text("Request permissions and schedule local notifications.")
                 .font(.caption)
             Text("Authorization Status: \(authStatusString(notificationAuthStatus))")
                 .font(.footnote)
             Button("Request Notification Permission") {
                 requestNotificationPermission()
             }
             .disabled(notificationAuthStatus == .authorized || notificationAuthStatus == .denied)
             Button("Schedule Demo Notification (5s)") {
                 scheduleDemoNotification()
             }
             .disabled(notificationAuthStatus != .authorized)
             Button("Cancel Demo Notification") {
                  cancelDemoNotification()
             }
             
             Divider()
             
             // CloudKit Push Demo Section
             Toggle("Enable CloudKit Push Demo", isOn: $enableCloudKitDemo)
                 .tint(.orange)
             
             // Add Text explaining requirements if toggle is on
             if enableCloudKitDemo {
                 Text("Requires manual setup: Enable Push & CloudKit capabilities, implement AppDelegate methods (call NotificationService helpers), create CKSubscription.")
                     .font(.caption2)
                     .foregroundColor(.gray)
                 
                 Button("Register for Remote Notifications") {
                     // Called after permission granted & toggle enabled
                     NotificationService.shared.registerForRemoteNotifications()
                 }
                 .disabled(notificationAuthStatus != .authorized)
                 
                 Button("Create CKSubscription (Placeholder)") {
                     // App-specific logic to create and save a CKQuerySubscription
                     DebugLogger.notification("Placeholder: Create CKSubscription button tapped.", level: .warning)
                 }
                 .disabled(notificationAuthStatus != .authorized)
             }
        }
    }
    
    @available(iOS 15.0, macOS 12.0, *) 
    private var themeManagerSection: some View {
        Section("Theme Manager (AppTheme)") {
             Text("Provides shared AppFonts and AppColors (requires Asset Catalog setup for custom colors).")
                 .font(.caption)
             Text("Title Font Example").font(AppFonts.title)
             Text("Headline Font Example").font(AppFonts.headline)
             Text("Body Font Example").font(AppFonts.body)
             Text("Caption Font Example").font(AppFonts.caption)
             Text("Button Font Example").font(AppFonts.button)
             Text("Regular 14pt").font(AppFonts.regular(size: 14))
             Text("Bold 16pt").font(AppFonts.bold(size: 16))
             Divider()
             Text("Error Color Example").foregroundColor(AppColors.error)
             Text("Success Color Example").foregroundColor(AppColors.success)
             Text("Warning Color Example").foregroundColor(AppColors.warning)
             Divider()
             Text("Note: Custom colors like `primary`, `background`, etc., require adding an Asset Catalog (e.g., Media.xcassets) to the ThemeManager target in Package.swift.")
                 .font(.caption2)
                 .foregroundColor(.gray)
        }
    }
    
    /// Provides a navigation link to the User Profile demo screen.
    @available(iOS 15.0, macOS 12.0, *) // Match DemoUserProfileScreen availability
    private var userProfileSection: some View {
         Section("User Profile Module") {
             NavigationLink("Show User Profile Demo") {
                 DemoUserProfileScreen()
             }
         }
    }

    /// Provides a navigation link to the RevenueCat demo screen.
    @available(iOS 15.0, macOS 12.0, *) // Match DemoRevenueCatScreen availability
    private var revenueCatSectionLink: some View {
         Section("RevenueCat Module") {
             NavigationLink("Show RevenueCat Demo") {
                 DemoRevenueCatScreen()
             }
         }
    }

    // Keep placeholder distinct to simplify main list structure
    @available(iOS 15.0, macOS 12.0, *) 
    private var examplePlaceholderSection: some View {
         Section("Example Section") {
             Text("Placeholder for future feature demonstration")
         }
    }
    
    // --- Helper Functions ---
    private func checkOnboardingStatus() {
         // Availability check removed as ContentView itself is iOS 15+/macOS 12+
         if !onboardingManager.isOnboardingComplete {
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                  showOnboardingSheet = true
             }
         }
    }
    
    // --- Helper Functions for Debug Tools Demo --- 
    // Re-adding the missing helper functions
    private func logGeneralDebug() {
        DebugLogger.log("This is a general debug message triggered from the DemoApp.")
    }
    private func logNetworkInfo() {
        DebugLogger.network("Simulating a network request successful.", level: .info)
    }
    private func logUIWarning() {
        DebugLogger.ui("A minor UI layout issue detected.", level: .warning)
    }
    private func logCoreDataError() {
        DebugLogger.coreData("Failed to save context!", level: .error)
    }
    private func logReviewMessage() {
        DebugLogger.review("Checking review request conditions.", level: .debug)
    }
    private func logNotificationMessage() {
        DebugLogger.notification("Received remote notification payload.", level: .info)
    }
    private func logRevenueCatMessage() {
        DebugLogger.revenueCat("Processing restored purchases.", level: .debug)
    }
    private func exampleTraceFunction() {
        DebugLogger.trace {
            DebugLogger.log("Executing code within the traced function.", level: .info)
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    
    // Notification Manager Helpers
    private func checkNotificationStatus() {
        // Use legacy completion handler version if needed, or just rely on .task
        NotificationService.shared.checkAuthorizationStatus { status in
            self.notificationAuthStatus = status
        }
    }
    
    private func checkNotificationStatusAsync() async {
        // Example using async/await if NotificationService provided an async API
        // For now, using the completion handler version within Task
        await MainActor.run { // Ensure state update on main thread
            NotificationService.shared.checkAuthorizationStatus { status in
                self.notificationAuthStatus = status
                DebugLogger.notification("Checked notification status: \(status)", level: .debug)
            }
        }
    }
    
    private func requestNotificationPermission() {
        NotificationService.shared.requestAuthorization { granted, error in
             if let error = error {
                 DebugLogger.notification("Permission error: \(error.localizedDescription)", level: .error)
             } else {
                 // Update status after request
                 checkNotificationStatus()
                 
                 // If granted and CloudKit demo enabled, register for remote
                 if granted && enableCloudKitDemo {
                      DebugLogger.notification("Permission granted and CloudKit demo enabled. Requesting remote registration.", level: .info)
                      #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
                      NotificationService.shared.registerForRemoteNotifications()
                      #else
                      DebugLogger.notification("Cannot call registerForRemoteNotifications on this platform.", level: .warning)
                      #endif
                 }
             }
        }
    }
    
    private func scheduleDemoNotification() {
        guard notificationAuthStatus == .authorized else { return }
        NotificationService.shared.scheduleLocalNotification(
            identifier: demoNotificationId,
            title: "CoreKit Demo", 
            body: "This is a test notification from the DemoApp!", 
            timeInterval: 5, // 5 seconds from now
            repeats: false
        )
        DebugLogger.notification("Attempted to schedule demo notification.")
    }
    
    private func cancelDemoNotification() {
        NotificationService.shared.cancelNotification(identifier: demoNotificationId)
        DebugLogger.notification("Attempted to cancel demo notification.")
    }
    
    // Helper to convert status enum to string for display
    private func authStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
}

// Remove the incorrect #if available wrapper.
// Previews will only work on sufficiently new OS versions due to the
// @available attribute on ContentView itself.
#Preview {
    // Need to ensure ContentView can be initialized even if body has issues
    // on older OS. The @available on the struct handles this.
    if #available(iOS 15.0, macOS 12.0, *) {
        ContentView()
    } else {
        Text("Preview requires iOS 15+ or macOS 12+")
    }
} 
