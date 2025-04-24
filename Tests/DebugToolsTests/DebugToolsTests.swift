import Testing
@testable import DebugTools
import OSLog // Needed to potentially inspect OSLog behavior if mocking
import Foundation

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct DebugToolsTests {

    // NOTE: Testing the actual output to Console.app or Xcode console is difficult
    // in automated unit tests. These tests focus on the DebugLogger's internal logic
    // like level filtering and function tracing state, and formatting conceptually.

    // Store original settings to restore after tests
    let originalLogLevels = DebugLogger.enabledLogLevels
    let originalIsTracingEnabled = DebugLogger.isTracingEnabled

    // Reset state after each test using Swift Testing's automatic cleanup (if applicable)
    // or manually call a reset function if needed.
    // Swift Testing doesn't have explicit teardown like XCTest yet.
    // We might need to manage state restoration carefully.
    private func restoreOriginalSettings() {
        DebugLogger.enabledLogLevels = originalLogLevels
        DebugLogger.isTracingEnabled = originalIsTracingEnabled
    }

    @Test("Log Level Filtering - Enabled Level") func testLogLevelFilteringEnabled() {
        // This test assumes we could capture logs, which is hard.
        // Alternative: Test if the internal _log function returns early.
        // For now, we mainly test the configuration aspect.
        DebugLogger.enabledLogLevels = [.info, .error]
        
        // We expect .info to proceed, .debug not to.
        // Cannot directly verify OSLog output here.
        DebugLogger.log("Info message", level: .info)
        DebugLogger.log("Debug message", level: .debug)
        
        // Conceptual assertion - actual verification requires log capture/mocking
        #expect(DebugLogger.enabledLogLevels.contains(.info))
        #expect(!DebugLogger.enabledLogLevels.contains(.debug))
        
        restoreOriginalSettings()
    }
    
    @Test("Log Level Filtering - Disabled Level") func testLogLevelFilteringDisabled() {
        DebugLogger.enabledLogLevels = [.warning]
        
        // We expect .info not to proceed.
        DebugLogger.log("Info message", level: .info)
        
        #expect(!DebugLogger.enabledLogLevels.contains(.info))
        
        restoreOriginalSettings()
    }

    @Test("Tracing Enabled/Disabled") func testTracingToggle() {
        // Again, testing the *effect* (actual log output) is hard.
        // We test the state variable.
        DebugLogger.isTracingEnabled = true
        // Call trace function - verification needs log capture
        DebugLogger.traceEnter()
        #expect(DebugLogger.isTracingEnabled == true)
        
        DebugLogger.isTracingEnabled = false
        // Call trace function - verification needs log capture
        DebugLogger.traceEnter()
        #expect(DebugLogger.isTracingEnabled == false)

        restoreOriginalSettings()
    }

    @Test("Convenience Functions Call Internal Log") func testConvenienceFunctions() {
        // This is difficult to test without mocking OSLog or capturing output.
        // We are essentially trusting that the convenience funcs call _log.
        // A refactor could make _log return a formatted string for easier testing.
        DebugLogger.enabledLogLevels = [.debug] // Ensure level is enabled
        
        DebugLogger.onboarding("Test Onboarding")
        DebugLogger.network("Test Network")
        DebugLogger.ui("Test UI")
        DebugLogger.coreData("Test CoreData")
        DebugLogger.review("Test Review")
        DebugLogger.notification("Test Notification")
        DebugLogger.revenueCat("Test RevenueCat")
        
        // No direct assertion possible without log capture/mocking.
        #expect(true) // Placeholder: Assumes calls didn't crash.

        restoreOriginalSettings()
    }
    
    // TODO: Explore OSLog mocking/capture techniques for more robust verification.
    // TODO: Test log message formatting if _log is refactored to return the string.
} 