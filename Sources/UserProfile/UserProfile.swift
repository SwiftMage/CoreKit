import Foundation

/// Represents the data model for a user's profile.
/// 
/// This struct holds common user attributes that might be persisted 
/// and accessed throughout the application.
public struct UserProfile: Codable, Identifiable, Equatable {
    
    /// A unique identifier for the user (e.g., UUID string).
    public let id: String
    
    /// The user's display name (optional).
    public var name: String?
    
    /// The user's email address (optional).
    public var email: String?
    
    /// The URL string for the user's avatar image (optional).
    public var avatarUrl: String?
    
    /// The date when the user profile was created.
    public let creationDate: Date
    
    /// The date when the user last logged in or was active (optional).
    public var lastLoginDate: Date?
    
    // Add other relevant user attributes as needed, e.g.:
    // public var preferences: UserPreferences?
    
    /// Initializes a new user profile.
    /// - Parameters:
    ///   - id: The unique identifier. Defaults to a new UUID string.
    ///   - name: The display name.
    ///   - email: The email address.
    ///   - avatarUrl: The avatar URL string.
    ///   - creationDate: The creation date. Defaults to the current date.
    ///   - lastLoginDate: The last login date.
    public init(
        id: String = UUID().uuidString,
        name: String? = nil,
        email: String? = nil,
        avatarUrl: String? = nil,
        creationDate: Date = Date(),
        lastLoginDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.creationDate = creationDate
        self.lastLoginDate = lastLoginDate
    }
} 