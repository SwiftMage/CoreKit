import Testing // Use the new Swift Testing framework
@testable import Onboarding // Import the module to be tested
@testable import DebugTools // Needed if manager uses DebugLogger
import Combine
import Foundation

// MARK: - Mock Onboarding Step

@available(iOS 14.0, macOS 10.15, tvOS 14.0, watchOS 7.0, *)
private struct MockOnboardingStep: OnboardingStep {
    var id: String
    var title: String = "Mock Title"
    var description: String = "Mock Description"
    var imageName: String? = nil

    // Dummy View body
    var body: some View { Text(title) }
}

// MARK: - OnboardingManager Tests

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct OnboardingManagerTests {

    // Helper to create mock steps
    private func createMockSteps(count: Int) -> [any OnboardingStep] {
        (1...count).map { MockOnboardingStep(id: "mockStep\($0)") }
    }
    
    // Helper for isolated UserDefaults
    private func createTestUserDefaults() -> UserDefaults {
        // Use a unique suite name for each test run potentially, or clear between tests
        let suiteName = UUID().uuidString
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Failed to create test UserDefaults suite.")
        }
        // Clean up after test if needed, or ensure suite name is unique
        // defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
    
    // Test UserDefaults key used by the manager
    private let testOnboardingCompleteKey = "onboardingComplete"

    @Test("Initialization - Default State") func testInitializationDefault() {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)

        #expect(manager.currentStepIndex == 0, "Initial step index should be 0")
        #expect(manager.steps.count == 3, "Should hold the provided steps")
        #expect(manager.isOnboardingComplete == false, "Onboarding should not be complete by default")
        #expect(manager.isFirstStep == true, "Should be on the first step initially")
        #expect(manager.isLastStep == false, "Should not be on the last step initially")
    }

    @Test("Initialization - Loads Incomplete State from UserDefaults") func testInitializationLoadsIncomplete() {
        let testDefaults = createTestUserDefaults()
        testDefaults.set(false, forKey: testOnboardingCompleteKey) // Pre-set state
        
        // Injecting UserDefaults is tricky as the manager uses UserDefaults.standard directly.
        // For robust testing, OnboardingManager should allow UserDefaults injection.
        // Workaround: Temporarily modify standard (less safe for parallel tests) or skip test.
        // Let's assume for now we can test the side effect IF the key matches.
        UserDefaults.standard.set(false, forKey: testOnboardingCompleteKey) // DANGER: Modifies standard
        
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps) // Manager reads standard on init

        #expect(manager.currentStepIndex == 0, "Should start at step 0 if onboarding wasn't complete")
        #expect(manager.isOnboardingComplete == false, "isOnboardingComplete should be false from UserDefaults")
        
        // Cleanup standard defaults if modified
        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)
    }
    
    @Test("Initialization - Loads Complete State from UserDefaults") func testInitializationLoadsComplete() {
        let testDefaults = createTestUserDefaults()
        testDefaults.set(true, forKey: testOnboardingCompleteKey)

        UserDefaults.standard.set(true, forKey: testOnboardingCompleteKey) // DANGER: Modifies standard

        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)

        #expect(manager.currentStepIndex == 0, "Should still init at step 0 even if complete (current logic)")
        #expect(manager.isOnboardingComplete == true, "isOnboardingComplete should be true from UserDefaults")

        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)
    }

    @Test("Navigation - Next Step Basic") @MainActor func testNextStep() async {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)
        
        await manager.nextStep()
        #expect(manager.currentStepIndex == 1, "Index should advance to 1")
        
        await manager.nextStep()
        #expect(manager.currentStepIndex == 2, "Index should advance to 2")
        #expect(manager.isLastStep == true, "Should now be on the last step")
    }

    @Test("Navigation - Previous Step Basic") @MainActor func testPreviousStep() async {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)
        manager.currentStepIndex = 2 // Start at the end

        await manager.previousStep()
        #expect(manager.currentStepIndex == 1, "Index should move back to 1")

        await manager.previousStep()
        #expect(manager.currentStepIndex == 0, "Index should move back to 0")
        #expect(manager.isFirstStep == true, "Should now be on the first step")
    }
    
    @Test("Navigation - Cannot Go Before First Step") @MainActor func testPreviousStopsAtFirst() async {
         let steps = createMockSteps(count: 3)
         let manager = OnboardingManager(steps: steps)
         #expect(manager.currentStepIndex == 0)
         
         await manager.previousStep()
         #expect(manager.currentStepIndex == 0, "Index should remain 0 when trying to go back from first step")
    }
    
    @Test("Navigation - Next Step Completes on Last") @MainActor func testNextCompletesOnLast() async {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)
        manager.currentStepIndex = 2 // Start on last step
        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey) // Ensure clean state

        #expect(manager.isOnboardingComplete == false)
        await manager.nextStep() // This should trigger completion
        #expect(manager.currentStepIndex == 2, "Index should remain on last step after finishing")
        #expect(manager.isOnboardingComplete == true, "Onboarding should be marked complete")
        // Test side effect (NOTE: relies on key matching manager's internal key)
        #expect(UserDefaults.standard.bool(forKey: testOnboardingCompleteKey) == true, "UserDefaults should be updated")

        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)
    }
    
    @Test("Completion - Skip Completes") @MainActor func testSkipCompletes() async {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)
        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)

        #expect(manager.isOnboardingComplete == false)
        await manager.skipOnboarding()
        #expect(manager.isOnboardingComplete == true, "Onboarding should be marked complete after skip")
        #expect(UserDefaults.standard.bool(forKey: testOnboardingCompleteKey) == true, "UserDefaults should be updated after skip")

        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)
    }

    @Test("Reset - Resets State") @MainActor func testReset() async {
        let steps = createMockSteps(count: 3)
        let manager = OnboardingManager(steps: steps)
        manager.currentStepIndex = 1
        await manager.completeOnboarding() // Mark as complete first
        
        #expect(manager.isOnboardingComplete == true)
        #expect(UserDefaults.standard.bool(forKey: testOnboardingCompleteKey) == true)

        await manager.resetOnboardingState()
        
        #expect(manager.currentStepIndex == 0, "Index should reset to 0")
        #expect(manager.isOnboardingComplete == false, "Complete state should be reset to false")
        #expect(UserDefaults.standard.bool(forKey: testOnboardingCompleteKey) == false, "UserDefaults should be updated after reset")

        UserDefaults.standard.removeObject(forKey: testOnboardingCompleteKey)
    }

    // TODO: Add tests for edge cases (e.g., zero steps provided)
    // TODO: Refactor manager to allow UserDefaults injection for safer testing
}

// Helper extension if needed to make properties accessible for testing
// extension OnboardingManager {
//     var test_onboardingCompleteKey: String { onboardingCompleteKey }
// } 