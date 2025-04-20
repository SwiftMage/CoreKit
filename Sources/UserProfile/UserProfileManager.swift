import Foundation
import Combine
import DebugTools

/// Manages the user's profile data, including persistence and access.
///
/// ## Overview
/// This class acts as a central hub for accessing and modifying persistent data 
/// tied to the active user. It handles loading/saving the user profile
/// and provides methods for basic profile operations.
///
/// ## Features
/// - **Current User Management:** Provides access to the currently active `UserProfile` via the `@Published var currentUser` property.
/// - **Persistence:** Handles saving and loading the `UserProfile` using `UserDefaults` (simple implementation). This could be adapted to use Keychain or Core Data for more complex needs.
/// - **Observability:** Conforms to `ObservableObject`, allowing SwiftUI views to react to changes in the `currentUser`.
/// - **Basic Operations:** Includes methods to update and clear the user profile.
///
/// ## Usage
/// Create an instance of `UserProfileManager` (often as a `@StateObject` in your root view or passed via the environment) 
/// and observe the `currentUser` property. Use the provided methods to modify the profile.
///
/// ```swift
/// @StateObject private var profileManager = UserProfileManager()
///
/// var body: some View {
///     Text("Welcome, \(profileManager.currentUser?.name ?? "Guest")")
///     Button("Update Name") {
///         profileManager.updateUserProfile(name: "New Name")
///     }
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class UserProfileManager: ObservableObject {
    
    /// The currently active user profile. Published for SwiftUI observation.
    /// Defaults to `nil` if no profile is saved or loaded.
    @Published public var currentUser: UserProfile? {
        didSet {
            // Save whenever the current user changes (including setting to nil).
            saveCurrentUser()
        }
    }
    
    // Key used for storing the profile in UserDefaults.
    private let userProfileKey = "currentUserProfileData"
    private let userDefaults = UserDefaults.standard

    /// Initializes the manager and loads the saved user profile, if any.
    public init() {
        DebugTools.DebugLogger.userProfile("Initializing UserProfileManager.")
        loadCurrentUser()
    }

    // MARK: - Profile Management

    /// Updates the properties of the current user profile.
    /// 
    /// If `currentUser` is `nil`, this method does nothing.
    /// Only non-nil parameters will be used for updating.
    /// - Parameters:
    ///   - name: The new display name (optional).
    ///   - email: The new email address (optional).
    ///   - avatarUrl: The new avatar URL string (optional).
    ///   - lastLoginDate: The new last login date (optional).
    public func updateUserProfile(
        name: String? = nil,
        email: String? = nil,
        avatarUrl: String? = nil,
        lastLoginDate: Date? = nil
    ) {
        // Ensure there is a current user to update.
        guard var userToUpdate = currentUser else {
            DebugTools.DebugLogger.userProfile("Attempted to update profile, but no current user exists.", level: .warning)
            return
        }
        
        DebugTools.DebugLogger.userProfile("Updating user profile ID: \(userToUpdate.id)")
        var updated = false
        
        // Update properties only if a new value is provided.
        if let newName = name {
            userToUpdate.name = newName
            updated = true
            DebugTools.DebugLogger.userProfile("  Updating name.")
        }
        if let newEmail = email {
            userToUpdate.email = newEmail
            updated = true
             DebugTools.DebugLogger.userProfile("  Updating email.")
        }
        if let newAvatarUrl = avatarUrl {
            userToUpdate.avatarUrl = newAvatarUrl
            updated = true
             DebugTools.DebugLogger.userProfile("  Updating avatar URL.")
        }
         if let newLastLoginDate = lastLoginDate {
            userToUpdate.lastLoginDate = newLastLoginDate
            updated = true
             DebugTools.DebugLogger.userProfile("  Updating last login date.")
        }
        
        // Only assign back to trigger save if something actually changed.
        if updated {
            currentUser = userToUpdate
             DebugTools.DebugLogger.userProfile("Profile update saved.", level: .info)
        } else {
             DebugTools.DebugLogger.userProfile("No profile updates provided.")
        }
    }

    /// Clears the current user profile data from storage and sets `currentUser` to `nil`.
    public func clearCurrentUser() {
        DebugTools.DebugLogger.userProfile("Clearing current user profile.", level: .info)
        userDefaults.removeObject(forKey: userProfileKey)
        currentUser = nil
    }
    
    /// Sets a specific user profile as the current user.
    /// Typically used if loading from a list or creating a new profile.
    /// - Parameter profile: The profile to set as current. It will be saved automatically.
    public func setCurrentUser(_ profile: UserProfile) {
         DebugTools.DebugLogger.userProfile("Setting current user: ID \(profile.id), Name: \(profile.name ?? "N/A")")
         currentUser = profile // This triggers the didSet which saves the user
    }

    // MARK: - Persistence (using UserDefaults + Codable)

    /// Saves the current `UserProfile` to UserDefaults.
    private func saveCurrentUser() {
        if let user = currentUser {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601 // Recommended for dates
                let encodedData = try encoder.encode(user)
                userDefaults.set(encodedData, forKey: userProfileKey)
                DebugTools.DebugLogger.userProfile("Saved user profile (ID: \(user.id)) to UserDefaults.", level: .debug)
            } catch {
                DebugTools.DebugLogger.userProfile("Failed to encode and save user profile: \(error.localizedDescription)", level: .error)
            }
        } else {
            // If currentUser is nil, remove the key from UserDefaults.
            userDefaults.removeObject(forKey: userProfileKey)
             DebugTools.DebugLogger.userProfile("Removed user profile from UserDefaults because currentUser is nil.", level: .debug)
        }
    }

    /// Loads the `UserProfile` from UserDefaults.
    private func loadCurrentUser() {
        guard let savedData = userDefaults.data(forKey: userProfileKey) else {
            DebugTools.DebugLogger.userProfile("No saved user profile data found in UserDefaults.")
            currentUser = nil
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedUser = try decoder.decode(UserProfile.self, from: savedData)
            currentUser = decodedUser
            DebugTools.DebugLogger.userProfile("Successfully loaded user profile (ID: \(decodedUser.id)) from UserDefaults.", level: .info)
        } catch {
             DebugTools.DebugLogger.userProfile("Failed to decode user profile from UserDefaults: \(error.localizedDescription). Clearing potentially corrupt data.", level: .error)
            // Clear potentially corrupt data
            userDefaults.removeObject(forKey: userProfileKey)
            currentUser = nil
        }
    }
} 