import Foundation
import Combine
import RevenueCat // Import the SDK
import DebugTools

// MARK: - RevenueCat Manager

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
public class RevenueCatManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The user's current subscription/entitlement status.
    @Published public private(set) var isSubscriptionActive: Bool = false
    
    /// Available packages/offerings fetched from RevenueCat.
    @Published public private(set) var offerings: RevenueCat.Offerings? = nil
    
    /// Loading state for UI feedback.
    @Published public private(set) var isLoading: Bool = false
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        DebugLogger.revenueCat("RevenueCatManager initialized.")
        // TODO: Add listener for Purchases.shared.customerInfoStream
        // TODO: Fetch offerings on init?
    }
    
    // MARK: - Configuration
    
    /// Configures the RevenueCat SDK. Should be called once, typically at app launch.
    public static func configure(apiKey: String) {
        Purchases.logLevel = .debug // Adjust log level as needed
        // Consider platform-specific API keys if necessary
        Purchases.configure(withAPIKey: apiKey)
        DebugLogger.revenueCat("RevenueCat SDK configured with API key.")
        // TODO: Add App User ID tracking if applicable (e.g., after user logs in)
        // Purchases.shared.logIn("user_id")
    }
    
    // MARK: - Public Methods
    
    /// Fetches the latest offerings from RevenueCat.
    @MainActor
    public func fetchOfferings() async {
        DebugLogger.revenueCat("Fetching offerings...")
        isLoading = true
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            self.offerings = fetchedOfferings
            DebugLogger.revenueCat("Offerings fetched successfully.")
            // Process offerings (e.g., find current offering)
        } catch {
            DebugLogger.revenueCat("Error fetching offerings: \(error.localizedDescription)", level: .error)
            // Handle error (e.g., show alert to user)
        }
        isLoading = false
    }
    
    /// Initiates the purchase flow for a specific package.
    @MainActor
    public func purchase(package: Package) async throws -> CustomerInfo {
        DebugLogger.revenueCat("Attempting purchase for package: \(package.identifier)")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            let customerInfo = result.customerInfo

            DebugLogger.revenueCat("Purchase successful for package: \(package.identifier). Customer Info: \(customerInfo)")
            updateSubscriptionStatus(customerInfo: customerInfo)
            return customerInfo
        } catch {
            if let rcError = error as? RevenueCat.ErrorCode, rcError == .purchaseCancelledError {
                 DebugLogger.revenueCat("Purchase cancelled by user.", level: .info)
            } else {
                 DebugLogger.revenueCat("Purchase failed: \(error.localizedDescription)", level: .error)
            }
            throw error
        }
    }
    
    /// Restores previous purchases.
    @MainActor
    public func restorePurchases() async throws -> CustomerInfo {
        DebugLogger.revenueCat("Attempting to restore purchases...")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            DebugLogger.revenueCat("Purchases restored successfully. Customer Info: \(customerInfo)")
            updateSubscriptionStatus(customerInfo: customerInfo)
            return customerInfo
        } catch {
            DebugLogger.revenueCat("Failed to restore purchases: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
    
    /// Checks the current customer info to update subscription status.
    @MainActor
    public func checkSubscriptionStatus() async {
        DebugLogger.revenueCat("Checking subscription status...")
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
             DebugLogger.revenueCat("Failed to get customer info: \(error.localizedDescription)", level: .error)
        }
         isLoading = false
    }
    
    // MARK: - Private Helpers
    
    /// Updates the `isSubscriptionActive` property based on CustomerInfo.
    /// Replace "premium" with your actual entitlement identifier.
    /// Works for both subscriptions and lifetime purchases.
    private func updateSubscriptionStatus(customerInfo: CustomerInfo) {
        let entitlementID = "premium" 
        let isActive = customerInfo.entitlements.all[entitlementID]?.isActive == true 
        self.isSubscriptionActive = isActive
        DebugLogger.revenueCat("Premium status updated: isActive = \(isActive) for entitlement '\(entitlementID)'")
    }
    
    // TODO: Set up listener for customer info updates
    // private func listenForCustomerInfoUpdates() { ... Purchases.shared.customerInfoStream ... }
}

// MARK: - DebugLogger Category Extension (Example)

// Add this extension to your DebugLogger or a shared file
// public extension LoggingCategory {
//    static let revenueCat = "RevenueCat"
// }

// Add this to DebugLogger
// public static let revenueCatLog = Logger(subsystem: subsystem, category: LoggingCategory.revenueCat)
// public static func revenueCat(...) { _log(..., category: revenueCatLog, ...) }

/*
 // MARK: - Example Usage (RevenueCatManager)
 
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
 */ 