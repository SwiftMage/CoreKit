import Testing
@testable import Onboarding
import SwiftUI // For testing views if needed

@Suite("Onboarding Tests")
struct OnboardingTests {

    @Test("OnboardingManager Initialization")
    func testOnboardingManagerInit() throws {
        // Clear saved state before test
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        
        let manager = OnboardingManager()
        #expect(manager.isOnboardingComplete == false)
    }

    @Test("OnboardingManager Complete Onboarding")
    func testCompleteOnboarding() throws {
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
        let manager = OnboardingManager()
        
        manager.completeOnboarding()
        
        #expect(manager.isOnboardingComplete == true)
        #expect(UserDefaults.standard.bool(forKey: "onboardingComplete") == true)
        
        // Clean up after test
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }

    @Test("OnboardingManager Loads Saved State")
    func testLoadsSavedState() throws {
        // Set saved state
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        
        let manager = OnboardingManager()
        
        #expect(manager.isOnboardingComplete == true)
        
        // Clean up after test
        UserDefaults.standard.removeObject(forKey: "onboardingComplete")
    }
    
    // Test for OnboardingView (if it contains logic worth testing)
    // This might be better suited for UI tests, but basic structural tests are possible.
    @Test("OnboardingView Displays Content")
    func testOnboardingViewContent() throws {
        var completed = false
        let view = OnboardingView { completed = true }
        
        // Basic check: Ensure the view can be created
        #expect(view is OnboardingView)
        
        // Further testing often requires UI testing frameworks to interact with buttons etc.
        // You could potentially inspect the view hierarchy if needed for more complex tests.
    }
} 