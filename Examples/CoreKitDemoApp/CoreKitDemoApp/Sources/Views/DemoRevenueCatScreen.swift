import SwiftUI
import RevenueCatManager
import RevenueCat // Needed for Package, Offering types etc.
import DebugTools

/// A screen demonstrating the CoreKit RevenueCatManager module.
@available(iOS 15.0, macOS 12.0, *) // Needs Task/async
struct DemoRevenueCatScreen: View {
    
    @StateObject private var revenueCatManager = RevenueCatManager()
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var showSuccessAlert = false // Separate alert for success messages
    @State private var successMessage = ""
    
    var body: some View {
        Form { // Use Form for layout
            Section("Status") {
                Text("Is Loading: \(revenueCatManager.isLoading ? "Yes" : "No")")
                Text("Subscription Active: \(revenueCatManager.isSubscriptionActive ? "Yes (Premium)" : "No")")
                    .foregroundColor(revenueCatManager.isSubscriptionActive ? .green : .red)
            }
            
            // Display Offerings if not subscribed
            if !revenueCatManager.isSubscriptionActive {
                if let offerings = revenueCatManager.offerings {
                    if let currentOffering = offerings.current {
                        Section("Purchase Premium ('\(currentOffering.serverDescription)')") {
                            if currentOffering.availablePackages.isEmpty {
                                Text("No products found in current offering.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(currentOffering.availablePackages) { package in
                                    Button {
                                        purchase(package: package)
                                    } label: {
                                        VStack(alignment: .leading) {
                                            Text(package.storeProduct.localizedTitle)
                                                .font(.headline)
                                            Text(package.storeProduct.localizedDescription)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("Price: \(package.storeProduct.localizedPriceString)")
                                                .font(.footnote)
                                                .bold()
                                        }
                                    }
                                    .buttonStyle(.plain) // Use plain style inside Form
                                }
                            }
                        }
                    } else {
                        Section("Offerings") {
                             Text("No current offering available from RevenueCat.")
                                .foregroundColor(.gray)
                        }
                    }
                } else if !revenueCatManager.isLoading { // Only show loading if not already loading
                    Section("Offerings") {
                         Text("Fetching offerings...")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section("Actions") {
                 Button("Refresh Offerings") {
                    fetchOfferings()
                 }
                 Button("Restore Purchases") {
                     restorePurchases()
                 }
                 Button("Check Status Manually") {
                     checkStatus()
                 }
            }
            
            Section("Debug Note") {
                Text("This demo requires a valid RevenueCat API key configured in DemoApp.swift and matching product setup in App Store Connect / RevenueCat dashboard to function fully.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("RevenueCat Demo")
        .task { // Use .task for async work on view appear
            // Ensure SDK is configured (done in DemoApp.swift)
            await checkStatus() // Check status first
            await fetchOfferings() // Then fetch offerings
        }
        .alert("Error", isPresented: $showErrorAlert, actions: { 
             Button("OK", role: .cancel) { }
        }, message: { Text(alertMessage) })
        .alert("Success", isPresented: $showSuccessAlert, actions: { 
             Button("OK", role: .cancel) { }
        }, message: { Text(successMessage) })
    }

    // MARK: - Actions
    
    func fetchOfferings() {
        Task {
            await revenueCatManager.fetchOfferings()
        }
    }
    
    func checkStatus() {
        Task {
            await revenueCatManager.checkSubscriptionStatus()
        }
    }

    func purchase(package: Package) {
        Task {
            do {
                _ = try await revenueCatManager.purchase(package: package)
                // Status should update via listener if implemented, 
                // otherwise manually check/refresh
                successMessage = "Purchase successful!"
                showSuccessAlert = true
                await checkStatus() // Re-check status after purchase attempt
            } catch {
                alertMessage = "Purchase failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
    
    func restorePurchases() {
         Task {
            do {
                _ = try await revenueCatManager.restorePurchases()
                successMessage = "Purchases Restored! Status updated."
                showSuccessAlert = true 
                await checkStatus() // Re-check status after restore attempt
            } catch {
                alertMessage = "Restore failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
     if #available(iOS 15.0, macOS 12.0, *) {
         NavigationView {
             DemoRevenueCatScreen()
         }
     } else {
         Text("Preview requires iOS 15+ or macOS 12+")
     }
} 