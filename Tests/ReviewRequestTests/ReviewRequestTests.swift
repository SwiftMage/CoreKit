import Testing
@testable import ReviewRequest
import StoreKit // For SKStoreReviewController

// Note: Testing SKStoreReviewController directly is hard. 
// These tests focus on the logic *around* the request.

@Suite("ReviewRequest Tests")
struct ReviewRequestTests {
    
    var manager: ReviewRequestManager!
    let defaults = UserDefaults.standard
    let installDateKey = "reviewInstallDate"
    let lastRequestDateKey = "reviewLastRequestDate"
    let significantEventCountKey = "reviewSignificantEventCount"

    // Setup runs before each test
    @Test(.tags(.setUp)) // Using tags for setup/teardown logic
    func setUp() {
        // Clear UserDefaults before each test
        defaults.removeObject(forKey: installDateKey)
        defaults.removeObject(forKey: lastRequestDateKey)
        defaults.removeObject(forKey: significantEventCountKey)
        
        // Set a fixed install date in the past for testing date logic
        let installDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        defaults.set(installDate, forKey: installDateKey)
        
        manager = ReviewRequestManager()
        // Ideally, inject dependencies (like UserDefaults, date provider) 
        // for better testability instead of relying on global state.
    }
    
    // Teardown runs after each test
    @Test(.tags(.tearDown))
    func tearDown() {
        // Clean up UserDefaults after each test
        defaults.removeObject(forKey: installDateKey)
        defaults.removeObject(forKey: lastRequestDateKey)
        defaults.removeObject(forKey: significantEventCountKey)
        manager = nil
    }

    @Test("Initialization Sets Install Date")
    func testInitialization() throws {
        // Clear install date first to test its creation
        defaults.removeObject(forKey: installDateKey)
        let _ = ReviewRequestManager() // Re-initialize
        #expect(defaults.object(forKey: installDateKey) != nil)
    }
    
    @Test("Significant Event Logging Increments Count")
    func testLogSignificantEvent() throws {
        #expect(defaults.integer(forKey: significantEventCountKey) == 0)
        manager.logSignificantEvent()
        #expect(defaults.integer(forKey: significantEventCountKey) == 1)
        manager.logSignificantEvent()
        #expect(defaults.integer(forKey: significantEventCountKey) == 2)
    }
    
    // --- Tests for Review Request Conditions --- 
    // These assume the default thresholds (3 events, 7 days install, 30 days last request)
    
    @Test("Review Not Requested - Insufficient Events")
    func testReviewNotRequestedFewEvents() throws {
        // Requires mocking/spying on SKStoreReviewController.requestReview to be certain,
        // but we test the conditions leading up to it.
        manager.logSignificantEvent() // Event 1
        manager.logSignificantEvent() // Event 2
        // Expect requestReview not to be called (cannot verify directly here)
        #expect(defaults.object(forKey: lastRequestDateKey) == nil) 
    }
    
    @Test("Review Not Requested - Insufficient Days Since Install")
    func testReviewNotRequestedInstallDate() throws {
        // Set install date very recently
        defaults.set(Date(), forKey: installDateKey)
        manager = ReviewRequestManager() // Re-init with new date
        
        manager.logSignificantEvent() // Event 1
        manager.logSignificantEvent() // Event 2
        manager.logSignificantEvent() // Event 3 (meets event threshold)
        
        #expect(defaults.object(forKey: lastRequestDateKey) == nil) // Still shouldn't request
    }

    @Test("Review Requested - Conditions Met")
    func testReviewRequestedConditionsMet() throws {
        // Simulates conditions are met (enough events, enough time since install)
        // We can't directly verify SKStoreReviewController.requestReview was called,
        // but we can check if our manager *thinks* it requested it by checking lastRequestDateKey.
        
        manager.logSignificantEvent() // Event 1
        manager.logSignificantEvent() // Event 2
        manager.logSignificantEvent() // Event 3
        
        // Check that the last request date *was* set (proxy for request attempt)
        #expect(defaults.object(forKey: lastRequestDateKey) != nil)
    }
    
    @Test("Review Not Requested - Too Soon Since Last Request")
    func testReviewNotRequestedTooSoon() throws {
        // Set a last request date recently
        let lastRequest = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        defaults.set(lastRequest, forKey: lastRequestDateKey)
        manager = ReviewRequestManager() // Re-init

        // Log enough events
        manager.logSignificantEvent()
        manager.logSignificantEvent()
        manager.logSignificantEvent() 
        
        // Verify the last request date hasn't changed (meaning no new request was attempted)
        let newLastRequestDate = defaults.object(forKey: lastRequestDateKey) as? Date
        #expect(newLastRequestDate == lastRequest)
    }
    
    @Test("Reset Tracking Clears Data")
    func testResetTracking() throws {
        // Set some data
        defaults.set(3, forKey: significantEventCountKey)
        defaults.set(Date(), forKey: lastRequestDateKey)
        // installDateKey is set in setUp
        
        manager.resetTracking()
        
        #expect(defaults.object(forKey: installDateKey) == nil)
        #expect(defaults.object(forKey: lastRequestDateKey) == nil)
        #expect(defaults.integer(forKey: significantEventCountKey) == 0)
    }
} 