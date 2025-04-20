import Testing
@testable import ThemeManager // Changed from Utilities
import SwiftUI // For Color, Font tests

@Suite("Utilities Tests")
struct UtilitiesTests {

    @Test("AppColors Load Correctly (Conceptual)")
    func testAppColors() throws {
        // Testing loading from Asset Catalog (`Color("name", bundle: .module)`)
        // in unit tests can be tricky as the bundle setup might differ.
        // This often works better in Integration or UI tests where the app bundle is structured correctly.
        
        // Basic checks: Ensure the color constants exist and are of type Color.
        #expect(AppColors.primary is Color)
        #expect(AppColors.secondary is Color)
        #expect(AppColors.accent == Color.blue) // Check system color example
        #expect(AppColors.background is Color)
        
        // A more robust test might involve checking the resolved UIColor/NSColor
        // if possible, but this depends on the test environment setup.
    }

    @Test("AppFonts Load Correctly")
    func testAppFonts() throws {
        let regularFont = AppFonts.regular(size: 16)
        let boldFont = AppFonts.bold(size: 20)

        #expect(regularFont is Font)
        #expect(boldFont is Font)
        
        // If using custom fonts, tests could potentially check if the font name matches,
        // though direct inspection of Font properties is limited.
        // Example for system font check (might be fragile):
        // #expect(String(describing: regularFont).contains("System"))
        // #expect(String(describing: boldFont).contains("System"))
        // #expect(String(describing: boldFont).contains("Bold"))
    }

    // Add tests for other Utilities components as they are added.
    // For example, if you add String extensions:
    /*
    @Test("String Extension - isEmail Valid")
    func testStringIsEmailValid() throws {
        #expect("test@example.com".isEmail == true)
        #expect("invalid-email".isEmail == false)
        #expect("test@domain".isEmail == false) // Basic check
    }
    */
} 