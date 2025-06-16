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
    
    /// Indicates if we're currently offline and using cached subscription status
    @Published public private(set) var isUsingCachedStatus: Bool = false
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let productIdentifier: String
    
    // MARK: - Offline Caching
    
    private let subscriptionCacheKey: String
    private let lastUpdateKey: String
    private let subscriptionExpiryKey: String
    private let subscriptionPeriodKey: String
    
    // Default cache timeout for unknown subscription periods
    private let defaultCacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // MARK: - Initialization
    
    public init(productIdentifier: String = "default", entitlementId: String = "premium") {
        self.productIdentifier = productIdentifier
        
        // Generate keys based on product identifier for isolation
        self.subscriptionCacheKey = "\(productIdentifier)_SubscriptionStatus"
        self.lastUpdateKey = "\(productIdentifier)_LastUpdate"
        self.subscriptionExpiryKey = "\(productIdentifier)_SubscriptionExpiry"
        self.subscriptionPeriodKey = "\(productIdentifier)_SubscriptionPeriod"
        
        DebugLogger.revenueCat("RevenueCatManager initialized for product: \(productIdentifier)")
        
        // Load cached subscription status on initialization
        loadCachedSubscriptionStatus()
        
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
            
            // Cache the successful purchase result
            cacheSubscriptionStatus(isActive: isSubscriptionActive)
            isUsingCachedStatus = false
            
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
            
            // Cache the successful restore result
            cacheSubscriptionStatus(isActive: isSubscriptionActive)
            isUsingCachedStatus = false
            
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
            isUsingCachedStatus = false
            
            // Cache the successful result
            cacheSubscriptionStatus(isActive: isSubscriptionActive)
            
        } catch {
            DebugLogger.revenueCat("Failed to get customer info: \(error.localizedDescription)", level: .error)
            
            // Fall back to cached status if available
            if isCacheValid() {
                DebugLogger.revenueCat("Using cached subscription status due to network error", level: .info)
                isUsingCachedStatus = true
            } else {
                DebugLogger.revenueCat("No valid cache available, defaulting to inactive", level: .warning)
                isSubscriptionActive = false
                isUsingCachedStatus = false
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helpers
    
    /// Updates the `isSubscriptionActive` property based on CustomerInfo.
    /// Replace "premium" with your actual entitlement identifier.
    private func updateSubscriptionStatus(customerInfo: CustomerInfo) {
        let entitlementID = "premium" 
        let isActive = customerInfo.entitlements.all[entitlementID]?.isActive == true 
        self.isSubscriptionActive = isActive
        
        // Extract subscription details for intelligent caching
        if let entitlement = customerInfo.entitlements.all[entitlementID],
           entitlement.isActive {
            
            let expirationDate = entitlement.expirationDate
            let periodType = entitlement.periodType
            
            DebugLogger.revenueCat("Active subscription - Period: \(periodType.rawValue), Expires: \(expirationDate?.description ?? "Never")")
            
            // Store subscription details for cache validity calculation
            if let expirationDate = expirationDate {
                UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: subscriptionExpiryKey)
            }
            UserDefaults.standard.set(periodType.rawValue, forKey: subscriptionPeriodKey)
        } else {
            // Clear subscription details if not active
            UserDefaults.standard.removeObject(forKey: subscriptionExpiryKey)
            UserDefaults.standard.removeObject(forKey: subscriptionPeriodKey)
        }
        
        DebugLogger.revenueCat("Subscription status updated: isActive = \(isActive) for entitlement '\(entitlementID)'")
    }
    
    // MARK: - Offline Caching Methods
    
    /// Loads cached subscription status from UserDefaults
    private func loadCachedSubscriptionStatus() {
        let cachedStatus = UserDefaults.standard.bool(forKey: subscriptionCacheKey)
        let lastUpdate = UserDefaults.standard.double(forKey: lastUpdateKey)
        
        if isCacheValid(lastUpdate: lastUpdate) {
            isSubscriptionActive = cachedStatus
            isUsingCachedStatus = true
            DebugLogger.revenueCat("Loaded cached subscription status: \(cachedStatus)")
        } else {
            DebugLogger.revenueCat("Cached subscription status expired or not found")
            isUsingCachedStatus = false
        }
    }
    
    /// Caches the current subscription status to UserDefaults
    private func cacheSubscriptionStatus(isActive: Bool) {
        UserDefaults.standard.set(isActive, forKey: subscriptionCacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
        UserDefaults.standard.synchronize()
        
        DebugLogger.revenueCat("Cached subscription status: \(isActive)")
    }
    
    /// Checks if the cached subscription status is still valid based on subscription period and expiry
    private func isCacheValid(lastUpdate: Double? = nil) -> Bool {
        let updateTime = lastUpdate ?? UserDefaults.standard.double(forKey: lastUpdateKey)
        
        guard updateTime > 0 else {
            return false // No cache exists
        }
        
        let currentTime = Date().timeIntervalSince1970
        let timeSinceUpdate = currentTime - updateTime
        
        // Check if we have actual subscription expiry date
        let subscriptionExpiry = UserDefaults.standard.double(forKey: subscriptionExpiryKey)
        if subscriptionExpiry > 0 {
            let timeUntilExpiry = subscriptionExpiry - currentTime
            
            // Cache is valid if:
            // 1. Subscription hasn't expired yet
            // 2. We're within a reasonable offline grace period based on subscription type
            let gracePeriod = getOfflineGracePeriod()
            let isValid = timeUntilExpiry > -gracePeriod
            
            DebugLogger.revenueCat("Cache validity check - Time until expiry: \(Int(timeUntilExpiry))s, Grace period: \(Int(gracePeriod))s, Valid: \(isValid)")
            return isValid
        } else {
            // Fallback to time-based validation if no expiry date available
            let isValid = timeSinceUpdate < defaultCacheValidityDuration
            DebugLogger.revenueCat("Cache validity check (fallback) - Age: \(Int(timeSinceUpdate))s, Valid: \(isValid)")
            return isValid
        }
    }
    
    /// Gets the appropriate offline grace period based on subscription type
    private func getOfflineGracePeriod() -> TimeInterval {
        let periodTypeRaw = UserDefaults.standard.string(forKey: subscriptionPeriodKey) ?? ""
        
        // Map RevenueCat period types to reasonable offline grace periods
        switch periodTypeRaw {
        case "P1W": // Weekly
            return 2 * 24 * 60 * 60 // 2 days grace
        case "P1M": // Monthly  
            return 7 * 24 * 60 * 60 // 1 week grace
        case "P1Y": // Yearly
            return 30 * 24 * 60 * 60 // 30 days grace
        case "P3M": // Quarterly
            return 14 * 24 * 60 * 60 // 2 weeks grace
        case "P6M": // Semi-annual
            return 21 * 24 * 60 * 60 // 3 weeks grace
        default:
            DebugLogger.revenueCat("Unknown subscription period '\(periodTypeRaw)', using default grace period", level: .warning)
            return defaultCacheValidityDuration // 24 hours default
        }
    }
    
    /// Clears cached subscription data (useful for testing or logout)
    public func clearCache() {
        UserDefaults.standard.removeObject(forKey: subscriptionCacheKey)
        UserDefaults.standard.removeObject(forKey: lastUpdateKey)
        UserDefaults.standard.removeObject(forKey: subscriptionExpiryKey)
        UserDefaults.standard.removeObject(forKey: subscriptionPeriodKey)
        UserDefaults.standard.synchronize()
        
        isUsingCachedStatus = false
        DebugLogger.revenueCat("Cleared subscription cache")
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
     @StateObject private var revenueCatManager = RevenueCatManager(productIdentifier: "MyApp")
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
 struct MyApp: App {
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
