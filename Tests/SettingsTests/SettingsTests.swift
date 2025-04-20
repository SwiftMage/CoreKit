import Testing
@testable import Settings
@testable import DebugTools
import SwiftUI

@Suite("Settings View Tests")
struct SettingsTests {

    @State private var toggleValue = false
    @State private var buttonActionTriggered = false

    @Test("Settings Item Initialization")
    func testSettingsItemInitialization() throws {
        let toggle = SettingsToggleItem(title: "Toggle", isOn: $toggleValue)
        let link = SettingsLinkItem(title: "Link", destination: Text("Destination"))
        let externalLink = SettingsExternalLinkItem(title: "External", url: URL(string: "https://example.com")!)
        let button = SettingsButtonItem(title: "Button") { buttonActionTriggered = true }
        
        #expect(toggle.title == "Toggle")
        #expect(link.title == "Link")
        #expect(externalLink.title == "External")
        #expect(button.title == "Button")
    }

    @Test("Settings Section Initialization")
    func testSettingsSectionInitialization() throws {
        let section = SettingsSection(title: "Test Section", footer: "Test Footer") {
            SettingsToggleItem(title: "Item 1", isOn: .constant(true))
            SettingsLinkItem(title: "Item 2", destination: EmptyView())
        }
        
        #expect(section.title == "Test Section")
        #expect(section.footer == "Test Footer")
        #expect(section.items.count == 2)
        #expect((section.items[0] as? SettingsToggleItem)?.title == "Item 1")
    }

    @Test("SettingsView Initialization")
    func testSettingsViewInitialization() throws {
        let view = SettingsView(navigationTitle: "My Settings") {
            SettingsSection(title: "Section 1") {
                SettingsToggleItem(title: "Toggle", isOn: $toggleValue)
            }
        }
        
        #expect(view.navigationTitle == "My Settings")
        #expect(view.sections.count == 1)
        #expect(view.sections[0].title == "Section 1")
    }

    // Note: Testing the actual UI rendering, interactions (toggles, button taps, navigation)
    // is best done with SwiftUI Previews or UI Tests.
    // Unit tests can verify the data model and structure setup.

    @Test("SettingsButtonItem Action")
    func testSettingsButtonItemAction() throws {
        buttonActionTriggered = false // Reset flag
        let button = SettingsButtonItem(title: "Action Button") {
            buttonActionTriggered = true
        }
        
        button.action()
        #expect(buttonActionTriggered == true)
    }
    
    // Test Type Erasure for Link Item
    @Test("SettingsLinkItem Type Erasure")
    func testLinkItemTypeErasure() throws {
        let specificLink = SettingsLinkItem(title: "Specific", destination: Text("Specific View"))
        let anyViewLink = SettingsLinkItem(title: "Any", destination: AnyView(Text("Any View")))
        
        // Use the convenience initializer
        let erasedLink = SettingsLinkItem(title: "Erased", destination: Text("Erased View"))
        
        #expect(specificLink is SettingsLinkItem<Text>)
        #expect(anyViewLink is SettingsLinkItem<AnyView>)
        #expect(erasedLink is SettingsLinkItem<AnyView>)
        #expect(erasedLink.title == "Erased")
    }
}

// MARK: - Settings Data Model Tests

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsDataModelTests {

    @Test("SettingsToggleItem Initialization") func testToggleItemInit() {
        let binding = State(initialValue: true)
        let item = SettingsToggleItem(
            title: "Toggle Test",
            iconName: "star",
            iconColor: .yellow,
            isOn: binding.projectedValue,
            description: "A test toggle"
        )

        #expect(item.title == "Toggle Test")
        #expect(item.iconName == "star")
        #expect(item.iconColor == .yellow)
        #expect(item.isOn == true)
        #expect(item.description == "A test toggle")
    }
    
    @Test("SettingsLinkItem Initialization") func testLinkItemInit() {
        let destinationView = Text("Destination")
        let item = SettingsLinkItem(
            title: "Link Test",
            iconName: "link",
            iconColor: .blue,
            destination: destinationView
        )
        
        #expect(item.title == "Link Test")
        #expect(item.iconName == "link")
        #expect(item.iconColor == .blue)
        // Cannot easily compare View types directly
    }
    
    @Test("SettingsExternalLinkItem Initialization") func testExternalLinkItemInit() {
        guard let url = URL(string: "https://example.com") else {
             Issue.record("Failed to create URL for test")
             return
        }
        let item = SettingsExternalLinkItem(
            title: "External Link",
            iconName: "safari",
            iconColor: .green,
            url: url
        )
        
        #expect(item.title == "External Link")
        #expect(item.iconName == "safari")
        #expect(item.iconColor == .green)
        #expect(item.url == url)
    }
    
    @Test("SettingsButtonItem Initialization") func testButtonItemInit() {
        var actionCalled = false
        let item = SettingsButtonItem(
            title: "Button Test",
            iconName: "hand.tap",
            iconColor: .orange,
            action: { actionCalled = true }
        )
        
        #expect(item.title == "Button Test")
        #expect(item.iconName == "hand.tap")
        #expect(item.iconColor == .orange)
        
        item.action()
        #expect(actionCalled == true)
    }
    
    @Test("SettingsSection Initialization") func testSectionInit() {
        let toggleBinding = State(initialValue: false)
        let section = SettingsSection(title: "Section Title", footer: "Section Footer") {
            SettingsToggleItem(title: "Item 1", isOn: toggleBinding.projectedValue)
            SettingsLinkItem(title: "Item 2", destination: Text("Dest"))
        }
        
        #expect(section.title == "Section Title")
        #expect(section.footer == "Section Footer")
        #expect(section.items.count == 2)
        #expect(section.items[0].title == "Item 1")
        #expect(section.items[1].title == "Item 2")
    }
}

// MARK: - Settings View Tests (Conceptual)

// NOTE: Testing SwiftUI Views in unit tests is challenging.
// It's often better to test the underlying data/logic or use UI tests.
// These tests might verify initialization but not rendering.

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct SettingsViewTests {

    @Test("SettingsView Initialization") func testViewInit() {
         let toggleBinding = State(initialValue: false)
         let view = SettingsView(navigationTitle: "Test Settings") {
             SettingsSection(title: "Section 1") {
                 SettingsToggleItem(title: "Toggle", isOn: toggleBinding.projectedValue)
             }
         }
         
         // Basic check that initialization doesn't crash
         #expect(view.navigationTitle == "Test Settings")
         #expect(!view.sections.isEmpty)
     }

    // TODO: Add tests for SettingsRow type checking logic if possible
    // TODO: Add UI Tests to verify rendering and interaction

} 