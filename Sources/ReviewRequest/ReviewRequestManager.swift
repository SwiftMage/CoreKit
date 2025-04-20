import Foundation
import StoreKit

// Placeholder for managing App Store review requests
public class ReviewRequestManager {

    // Configuration (example)
    private let minSignificantEvents = 3
    private let minDaysSinceInstall = 7
    private let minDaysSinceLastRequest = 30

    private let userDefaults = UserDefaults.standard
    private let installDateKey = "reviewInstallDate"
    private let lastRequestDateKey = "reviewLastRequestDate"
    private let significantEventCountKey = "reviewSignificantEventCount"

    public init() {
        // Register install date if not already set
        if userDefaults.object(forKey: installDateKey) == nil {
            userDefaults.set(Date(), forKey: installDateKey)
        }
    }

    // Call this when a significant event occurs in your app
    public func logSignificantEvent() {
        let currentCount = userDefaults.integer(forKey: significantEventCountKey)
        userDefaults.set(currentCount + 1, forKey: significantEventCountKey)
        
        // Check if conditions are met to request a review
        tryRequestReview()
    }

    private func tryRequestReview() {
        guard let installDate = userDefaults.object(forKey: installDateKey) as? Date,
              let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        let now = Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: now).day ?? 0
        let significantEvents = userDefaults.integer(forKey: significantEventCountKey)

        // Check basic criteria
        guard significantEvents >= minSignificantEvents,
              daysSinceInstall >= minDaysSinceInstall else {
            return
        }

        // Check time since last request
        if let lastRequestDate = userDefaults.object(forKey: lastRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: now).day ?? 0
            guard daysSinceLastRequest >= minDaysSinceLastRequest else {
                return
            }
        }

        // Request the review
        SKStoreReviewController.requestReview(in: windowScene)
        userDefaults.set(now, forKey: lastRequestDateKey) // Record the time of the request
    }
    
    // For debug/testing purposes
    public func resetTracking() {
         userDefaults.removeObject(forKey: installDateKey)
         userDefaults.removeObject(forKey: lastRequestDateKey)
         userDefaults.removeObject(forKey: significantEventCountKey)
         print("Review request tracking reset.")
    }
}

// Make sure to import UIKit when using UIApplication
import UIKit 