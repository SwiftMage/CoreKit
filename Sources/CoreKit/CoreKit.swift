// MARK: - CoreKit
// This file re-exports all the modules that are part of the CoreKit package

// Re-export all modules for easier importing
@_exported import Onboarding
@_exported import ReviewManager
@_exported import NotificationManager
@_exported import UserProfile
@_exported import Settings
@_exported import RevenueCatManager
@_exported import DebugTools
@_exported import ThemeManager
@_exported import ParentalGate

// CoreKit Version
public enum CoreKitVersion {
    /// Current version of CoreKit
    public static let version = "1.0.0"
    
    /// Build number
    public static let build = "1"
}

// Use this to ensure CoreKit is properly loaded/linked
public func initializeCoreKit() {
    print("CoreKit v\(CoreKitVersion.version) initialized")
} 