#if canImport(UIKit)
import UIKit
#endif
import DebugTools
import StoreKit

// MARK: - Configuration Struct

/// Configuration settings for the review prompt logic.
public struct ReviewConfiguration {
    /// The minimum number of significant events required before prompting.
    public let minSignificantEvents: Int
    /// The minimum number of days since the app was first launched before prompting.
    public let minDaysSinceFirstLaunch: Int
    // let minDaysSinceLastPrompt: Int // Could add this later if needed

    /// Default configuration.
    public static let `default` = ReviewConfiguration(
        minSignificantEvents: 5,
        minDaysSinceFirstLaunch: 0
    )

    public init(minSignificantEvents: Int, minDaysSinceFirstLaunch: Int) {
        self.minSignificantEvents = minSignificantEvents
        self.minDaysSinceFirstLaunch = minDaysSinceFirstLaunch
    }
}

// MARK: - Review Manager Logic

public enum ReviewManager {
    
    // MARK: - Internal State
    public static var configuration: ReviewConfiguration = .default
    
    // Keys remain private
    private static let significantEventCountKey = "significantEventCount"
    private static let lastVersionPromptedForReviewKey = "lastVersionPromptedForReview"
    private static let firstLaunchDateKey = "firstLaunchDate"
    
    // Remove old private constants
    // private let minSignificantEvents = 5
    // private let minDaysSinceFirstLaunch = 7
    // private let minDaysSinceLastPrompt = 30

    // MARK: - Configuration
    
    /// Configures the review manager with custom thresholds.
    /// Call this once during app setup.
    /// - Parameter config: The configuration to use.
    public static func configure(config: ReviewConfiguration) {
        self.configuration = config
        DebugTools.DebugLogger.review("ReviewManager configured: Events=\(config.minSignificantEvents), Days=\(config.minDaysSinceFirstLaunch)")
    }

    // MARK: - Public API

    /// Increments the count of significant events tracked for review prompting.
    public static func incrementSignificantEventCount() {
        #if canImport(UIKit) || os(macOS)
        let currentCount = UserDefaults.standard.integer(forKey: significantEventCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: significantEventCountKey)
        DebugTools.DebugLogger.review("Incremented significant event count to \(newCount)", level: .debug)
        #else
        DebugTools.DebugLogger.review("Cannot increment event count: Platform not supported.")
        #endif
    }

    /// Checks conditions and potentially requests an App Store review.
    /// Call this periodically at appropriate, non-intrusive points in your app.
    public static func requestReviewIfNeeded() {
        #if canImport(UIKit) && !os(macOS)
        // --- iOS, tvOS, visionOS Implementation ---
        // --- Detailed Logging Start ---
        DebugTools.DebugLogger.review("Entering requestReviewIfNeeded() [iOS/tvOS/visionOS path]", level: .trace)
        
        // 1. Get required info
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            DebugTools.DebugLogger.review("Condition Check FAILED: Could not get active window scene.", level: .warning)
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Got active window scene.", level: .trace)
        
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            DebugTools.DebugLogger.review("Condition Check FAILED: Could not get current app version.", level: .warning)
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Got current app version: \(currentVersion)", level: .trace)
        
        let defaults = UserDefaults.standard
        let significantEventCount = defaults.integer(forKey: significantEventCountKey)
        let lastVersionPrompted = defaults.string(forKey: lastVersionPromptedForReviewKey)
        
        // 2. Set first launch date if needed
        var firstLaunchDate = defaults.object(forKey: firstLaunchDateKey) as? Date
        if firstLaunchDate == nil {
            firstLaunchDate = Date()
            defaults.set(firstLaunchDate, forKey: firstLaunchDateKey)
            DebugTools.DebugLogger.review("Setting first launch date: \(firstLaunchDate!)")
        }
        guard let unwrappedFirstLaunchDate = firstLaunchDate else { 
            DebugTools.DebugLogger.review("Condition Check FAILED: First launch date unexpectedly nil after check.", level: .error)
            return // Should not happen
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Got first launch date: \(unwrappedFirstLaunchDate)", level: .trace)

        // 3. Check conditions (using configured values)
        DebugTools.DebugLogger.review("Checking review request conditions: Events=\(significantEventCount)/\(configuration.minSignificantEvents), LastVersion=\(lastVersionPrompted ?? "None"), FirstLaunch=\(unwrappedFirstLaunchDate), MinDays=\(configuration.minDaysSinceFirstLaunch)")

        // Condition: Already prompted for this version?
        if currentVersion == lastVersionPrompted {
            DebugTools.DebugLogger.review("Condition Check FAILED: Already prompted for review on version \(currentVersion). Skipping.")
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Not yet prompted for version \(currentVersion).", level: .trace)

        // Condition: Minimum significant events (Use configuration)
        if significantEventCount < configuration.minSignificantEvents {
            DebugTools.DebugLogger.review("Condition Check FAILED: Not enough significant events (\(significantEventCount)/\(configuration.minSignificantEvents)). Skipping.")
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Sufficient significant events (\(significantEventCount)/\(configuration.minSignificantEvents)).", level: .trace)

        // Condition: Minimum days since first launch (Only if threshold > 0)
        if configuration.minDaysSinceFirstLaunch > 0 {
            let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: unwrappedFirstLaunchDate, to: Date()).day ?? 0
            if daysSinceFirstLaunch < configuration.minDaysSinceFirstLaunch {
                DebugTools.DebugLogger.review("Condition Check FAILED: Not enough days since first launch (\(daysSinceFirstLaunch)/\(configuration.minDaysSinceFirstLaunch)). Skipping.")
                return
            }
             DebugTools.DebugLogger.review("Condition Check PASSED: Sufficient days since first launch (\(daysSinceFirstLaunch)/\(configuration.minDaysSinceFirstLaunch)).", level: .trace)
        } else {
            DebugTools.DebugLogger.review("Condition Check SKIPPED: Minimum days threshold is 0.", level: .trace)
        }
        
        // 4. Request review
        DebugTools.DebugLogger.review("All conditions met. Preparing to call SKStoreReviewController.requestReview(in:) [iOS].", level: .info)
        SKStoreReviewController.requestReview(in: windowScene)
        DebugTools.DebugLogger.review("SKStoreReviewController.requestReview(in:) called. (Note: System may still decide not to show prompt).", level: .info)
        
        // 5. Update last prompted version
        defaults.set(currentVersion, forKey: lastVersionPromptedForReviewKey)
        DebugTools.DebugLogger.review("Updated last prompted version to \(currentVersion).")
        // Optionally reset significant event count here if desired after a prompt
        // defaults.set(0, forKey: significantEventCountKey)
        
        #elseif os(macOS) && canImport(StoreKit)
        // --- macOS Implementation ---
        DebugTools.DebugLogger.review("Entering requestReviewIfNeeded() [macOS path]", level: .trace)
        
        // 1. Get required info
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            DebugTools.DebugLogger.review("Condition Check FAILED: Could not get current app version.", level: .warning)
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Got current app version: \(currentVersion)", level: .trace)
        
        let defaults = UserDefaults.standard
        let significantEventCount = defaults.integer(forKey: significantEventCountKey)
        let lastVersionPrompted = defaults.string(forKey: lastVersionPromptedForReviewKey)
        
        // 2. Set first launch date if needed
        var firstLaunchDate = defaults.object(forKey: firstLaunchDateKey) as? Date
        if firstLaunchDate == nil {
            firstLaunchDate = Date()
            defaults.set(firstLaunchDate, forKey: firstLaunchDateKey)
            DebugTools.DebugLogger.review("Setting first launch date: \(firstLaunchDate!)")
        }
        guard let unwrappedFirstLaunchDate = firstLaunchDate else {
            DebugTools.DebugLogger.review("Condition Check FAILED: First launch date unexpectedly nil after check.", level: .error)
            return // Should not happen
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Got first launch date: \(unwrappedFirstLaunchDate)", level: .trace)
        
        // 3. Check conditions (using configured values)
        DebugTools.DebugLogger.review("Checking review request conditions: Events=\(significantEventCount)/\(configuration.minSignificantEvents), LastVersion=\(lastVersionPrompted ?? "None"), FirstLaunch=\(unwrappedFirstLaunchDate), MinDays=\(configuration.minDaysSinceFirstLaunch)")
        
        // Condition: Already prompted for this version?
        if currentVersion == lastVersionPrompted {
            DebugTools.DebugLogger.review("Condition Check FAILED: Already prompted for review on version \(currentVersion). Skipping.")
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Not yet prompted for version \(currentVersion).", level: .trace)
        
        // Condition: Minimum significant events (Use configuration)
        if significantEventCount < configuration.minSignificantEvents {
            DebugTools.DebugLogger.review("Condition Check FAILED: Not enough significant events (\(significantEventCount)/\(configuration.minSignificantEvents)). Skipping.")
            return
        }
        DebugTools.DebugLogger.review("Condition Check PASSED: Sufficient significant events (\(significantEventCount)/\(configuration.minSignificantEvents)).", level: .trace)
        
        // Condition: Minimum days since first launch (Only if threshold > 0)
        if configuration.minDaysSinceFirstLaunch > 0 {
            let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: unwrappedFirstLaunchDate, to: Date()).day ?? 0
            if daysSinceFirstLaunch < configuration.minDaysSinceFirstLaunch {
                DebugTools.DebugLogger.review("Condition Check FAILED: Not enough days since first launch (\(daysSinceFirstLaunch)/\(configuration.minDaysSinceFirstLaunch)). Skipping.")
                return
            }
            DebugTools.DebugLogger.review("Condition Check PASSED: Sufficient days since first launch (\(daysSinceFirstLaunch)/\(configuration.minDaysSinceFirstLaunch)).", level: .trace)
        } else {
            DebugTools.DebugLogger.review("Condition Check SKIPPED: Minimum days threshold is 0.", level: .trace)
        }
        
        // 4. Request review (macOS version doesn't need a window scene)
        DebugTools.DebugLogger.review("All conditions met. Preparing to call SKStoreReviewController.requestReview() [macOS].", level: .info)
        SKStoreReviewController.requestReview()
        DebugTools.DebugLogger.review("SKStoreReviewController.requestReview() called. (Note: System may still decide not to show prompt).", level: .info)
        
        // 5. Update last prompted version
        defaults.set(currentVersion, forKey: lastVersionPromptedForReviewKey)
        DebugTools.DebugLogger.review("Updated last prompted version to \(currentVersion).")
        
        #else
        DebugTools.DebugLogger.review("Review requests not available on this platform (requires UIKit or macOS with StoreKit).")
        #endif
    }

    /// Resets all stored data related to review prompts (for testing/debugging).
    public static func resetReviewRequestData() {
        #if canImport(UIKit) || os(macOS)
        UserDefaults.standard.removeObject(forKey: lastVersionPromptedForReviewKey)
        UserDefaults.standard.removeObject(forKey: significantEventCountKey)
        UserDefaults.standard.removeObject(forKey: firstLaunchDateKey)
        DebugTools.DebugLogger.review("Review request data reset.")
        #else
        DebugTools.DebugLogger.review("Cannot reset review data: Platform not supported.")
        #endif
    }
}

/*
 // MARK: - Example Usage (ReviewManager)
 
 import CoreKit // Or import ReviewManager
 
 // --- During App Setup (e.g., AppDelegate/App init) ---
 // Optionally configure with different thresholds:
 let customConfig = ReviewConfiguration(
     minSignificantEvents: 10, // Require 10 events
     minDaysSinceFirstLaunch: 14 // Require 14 days
 )
 ReviewManager.configure(config: customConfig)
 // If you don't call configure, default values (5 events, 0 days) are used.
 
 // --- Somewhere in your app logic (e.g., ViewModel or View action) ---
 
 // Call this when a significant positive event happens for the user
 // e.g., completing a task, achieving a goal, using a key feature N times etc.
 ReviewManager.incrementSignificantEventCount()
 
 // Call this occasionally at logical points where a review prompt
 // wouldn't interrupt the user excessively (e.g., after finishing a task).
 // The function contains its own logic (incl. configuration) to decide IF it should prompt.
 ReviewManager.requestReviewIfNeeded()
 
 // --- Platform Notes ---
 // On iOS, tvOS, visionOS: ReviewManager will use SKStoreReviewController.requestReview(in:) with a UIWindowScene
 // On macOS: ReviewManager will use SKStoreReviewController.requestReview() without window scene parameter
 
 // --- Optional: Resetting (for testing) ---
 // ReviewManager.resetReviewRequestData()
 
 */ 