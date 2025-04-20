import Testing
@testable import UserProfile
import Combine

@Suite("UserProfileManager Tests")
struct UserProfileManagerTests {

    var manager: UserProfileManager!
    let defaults = UserDefaults.standard
    let currentUserKey = "currentUserProfile"
    let profilesKey = "userProfiles"
    
    // Use SetUp/TearDown tags for setup and cleanup
    @Test(.tags(.setUp))
    func setUp() {
        // Clear UserDefaults before each test to ensure clean state
        defaults.removeObject(forKey: currentUserKey)
        defaults.removeObject(forKey: profilesKey)
        defaults.removeObject(forKey: "onboardingComplete") // Clear helper flag too
        manager = UserProfileManager() 
    }
    
    @Test(.tags(.tearDown))
    func tearDown() {
        defaults.removeObject(forKey: currentUserKey)
        defaults.removeObject(forKey: profilesKey)
        defaults.removeObject(forKey: "onboardingComplete")
        manager = nil
    }

    @Test("Initialization - No Saved Data")
    func testInitializationEmpty() throws {
        #expect(manager.currentUser == nil)
        #expect(manager.profiles.isEmpty)
    }

    @Test("Add Profile")
    func testAddProfile() throws {
        let profile1 = manager.addProfile(name: "Alice", email: "alice@example.com")
        
        #expect(manager.profiles.count == 1)
        #expect(manager.profiles.first?.name == "Alice")
        #expect(manager.profiles.first?.email == "alice@example.com")
        #expect(manager.currentUser == profile1) // First added profile becomes current

        let profile2 = manager.addProfile(name: "Bob")
        #expect(manager.profiles.count == 2)
        #expect(manager.profiles.last?.name == "Bob")
        #expect(manager.currentUser == profile1) // Current user doesn't change
    }
    
    @Test("Update Profile")
    func testUpdateProfile() throws {
        let profile = manager.addProfile(name: "Charlie")
        let initialID = profile.id
        let initialDate = profile.creationDate
        
        var updatedProfile = profile
        updatedProfile.name = "Charles"
        updatedProfile.email = "charles@example.com"
        
        manager.updateProfile(updatedProfile)
        
        #expect(manager.profiles.count == 1)
        let fetchedProfile = manager.profiles.first!
        #expect(fetchedProfile.id == initialID)
        #expect(fetchedProfile.name == "Charles")
        #expect(fetchedProfile.email == "charles@example.com")
        #expect(fetchedProfile.creationDate == initialDate) // Creation date shouldn't change
        #expect(manager.currentUser == fetchedProfile) // Should also update current user if it was selected
    }
    
    @Test("Update Non-Current Profile")
    func testUpdateNonCurrentProfile() throws {
         _ = manager.addProfile(name: "User 1") // Sets current user
        var profile2 = manager.addProfile(name: "User 2")
        let profile2ID = profile2.id
        
        profile2.name = "User Two Updated"
        manager.updateProfile(profile2)
        
        #expect(manager.profiles.count == 2)
        #expect(manager.profiles.first?.name == "User 1") // Current unchanged
        #expect(manager.profiles.last?.name == "User Two Updated")
        #expect(manager.profiles.last?.id == profile2ID)
        #expect(manager.currentUser?.name == "User 1") // Current user remains User 1
    }

    @Test("Delete Profile - Current User")
    func testDeleteCurrentProfile() throws {
        let profile1 = manager.addProfile(name: "ToDelete")
        let profile2 = manager.addProfile(name: "ToKeep")
        manager.selectCurrentUser(profile: profile1) // Ensure profile1 is current
        
        #expect(manager.currentUser == profile1)
        
        manager.deleteProfile(id: profile1.id)
        
        #expect(manager.profiles.count == 1)
        #expect(manager.profiles.first?.name == "ToKeep")
        #expect(manager.currentUser == profile2) // Current user falls back to the next available
    }
    
    @Test("Delete Profile - Non-Current User")
    func testDeleteNonCurrentProfile() throws {
        let profile1 = manager.addProfile(name: "Current")
        let profile2 = manager.addProfile(name: "ToDelete")
        
        #expect(manager.currentUser == profile1)
        
        manager.deleteProfile(id: profile2.id)
        
        #expect(manager.profiles.count == 1)
        #expect(manager.profiles.first?.name == "Current")
        #expect(manager.currentUser == profile1) // Current user remains unchanged
    }
    
    @Test("Delete Profile - Last User")
    func testDeleteLastProfile() throws {
        let profile = manager.addProfile(name: "OnlyUser")
        #expect(manager.currentUser == profile)
        
        manager.deleteProfile(id: profile.id)
        
        #expect(manager.profiles.isEmpty)
        #expect(manager.currentUser == nil)
    }

    @Test("Select Current User")
    func testSelectCurrentUser() throws {
        let profile1 = manager.addProfile(name: "First")
        let profile2 = manager.addProfile(name: "Second")
        
        #expect(manager.currentUser == profile1)
        
        manager.selectCurrentUser(profile: profile2)
        #expect(manager.currentUser == profile2)
    }

    @Test("Persistence - Save and Load Profiles")
    func testPersistenceSaveLoadProfiles() throws {
        let p1 = manager.addProfile(name: "Save1")
        let p2 = manager.addProfile(name: "Save2")
        manager.selectCurrentUser(profile: p1)
        
        // Create a new instance to force loading from UserDefaults
        let newManager = UserProfileManager()
        
        #expect(newManager.profiles.count == 2)
        #expect(newManager.profiles.contains(where: { $0.id == p1.id && $0.name == "Save1" }))
        #expect(newManager.profiles.contains(where: { $0.id == p2.id && $0.name == "Save2" }))
        // Current user also persists
        #expect(newManager.currentUser?.id == p1.id)
    }
    
    @Test("Persistence - Load Empty State")
    func testPersistenceLoadEmpty() throws {
        // Ensure UserDefaults is empty (done in setUp)
        let newManager = UserProfileManager()
        #expect(newManager.profiles.isEmpty)
        #expect(newManager.currentUser == nil)
    }
    
    @Test("Helper - Onboarding Status")
    func testOnboardingHelper() throws {
        #expect(manager.hasCompletedOnboarding == false)
        
        manager.markOnboardingComplete()
        #expect(manager.hasCompletedOnboarding == true)
        #expect(UserDefaults.standard.bool(forKey: "onboardingComplete") == true)
    }
} 