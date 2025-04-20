import SwiftUI

// --- Data Model for Settings Items ---

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol SettingsItem: Identifiable {
    var id: UUID { get }
    var title: String { get }
    var iconName: String? { get }
    var iconColor: Color? { get }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SettingsToggleItem: SettingsItem {
    public let id = UUID()
    public var title: String
    public var iconName: String? = nil
    public var iconColor: Color? = .accentColor
    @Binding public var isOn: Bool
    public var description: String? = nil
    
    // Make initializer public
    public init(title: String, iconName: String? = nil, iconColor: Color? = .accentColor, isOn: Binding<Bool>, description: String? = nil) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self._isOn = isOn
        self.description = description
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SettingsLinkItem<Destination: View>: SettingsItem {
    public let id = UUID()
    public var title: String
    public var iconName: String? = nil
    public var iconColor: Color? = .accentColor
    public var destination: Destination
    
    // Make initializer public
    public init(title: String, iconName: String? = nil, iconColor: Color? = .accentColor, destination: Destination) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.destination = destination
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SettingsExternalLinkItem: SettingsItem {
    public let id = UUID()
    public var title: String
    public var iconName: String? = nil
    public var iconColor: Color? = .accentColor
    public var url: URL
    
    // Make initializer public
    public init(title: String, iconName: String? = nil, iconColor: Color? = .accentColor, url: URL) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.url = url
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SettingsButtonItem: SettingsItem {
    public let id = UUID()
    public var title: String
    public var iconName: String? = nil
    public var iconColor: Color? = .accentColor
    public var action: () -> Void
    
    // Make initializer public
    public init(title: String, iconName: String? = nil, iconColor: Color? = .accentColor, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.action = action
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct SettingsSection {
    public let id = UUID()
    public var title: String? = nil
    public var items: [any SettingsItem]
    public var footer: String? = nil
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public init(title: String? = nil, footer: String? = nil, @SettingsItemsBuilder items: () -> [any SettingsItem]) {
        self.title = title
        self.items = items()
        self.footer = footer
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@resultBuilder
public struct SettingsItemsBuilder {
    public static func buildBlock(_ components: any SettingsItem...) -> [any SettingsItem] {
        components
    }
    
    // Add buildOptional to support `if` conditions without `else`
    public static func buildOptional(_ component: (any SettingsItem)?) -> [any SettingsItem] {
        return component.map { [$0] } ?? []
    }
    
    // Optionally add buildEither for `if/else` (if needed later)
    // public static func buildEither(first component: [any SettingsItem]) -> [any SettingsItem] {
    //     return component
    // }
    // public static func buildEither(second component: [any SettingsItem]) -> [any SettingsItem] {
    //     return component
    // }
}

// --- Settings View ---

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct SettingsView: View {
    let sections: [SettingsSection]
    let navigationTitle: String

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init(navigationTitle: String = "Settings", @SettingsSectionsBuilder sections: () -> [SettingsSection]) {
        self.navigationTitle = navigationTitle
        self.sections = sections()
    }

    public var body: some View {
        NavigationView {
            Form {
                ForEach(sections, id: \.id) { section in
                    Section(header: section.title.map { Text($0) }, footer: section.footer.map { Text($0) }) {
                        ForEach(section.items, id: \.id) { item in
                            SettingsRow(item: item)
                        }
                    }
                }
            }
            // Apply list style conditionally for iOS/watchOS/tvOS
            #if os(iOS) || os(watchOS) || os(tvOS)
            .listStyle(.insetGrouped) // Use modern style only where available
            #endif
            .navigationTitle(navigationTitle)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        // Applying navigationViewStyle for better iPad compatibility if needed
        // .navigationViewStyle(.stack) 
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@resultBuilder
public struct SettingsSectionsBuilder {
    public static func buildBlock(_ components: SettingsSection...) -> [SettingsSection] {
        components
    }
}

// --- Helper Views ---

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsRow: View {
    let item: any SettingsItem

    var body: some View {
        // Type checking pattern matching requires newer Swift
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
             Group {
                if let toggleItem = item as? SettingsToggleItem {
                    SettingsToggleRow(item: toggleItem)
                } else if let linkItem = item as? SettingsLinkItem<AnyView> {
                    SettingsLinkRow(item: linkItem)
                } else if let externalLinkItem = item as? SettingsExternalLinkItem {
                    SettingsExternalLinkRow(item: externalLinkItem)
                } else if let buttonItem = item as? SettingsButtonItem {
                    SettingsButtonRow(item: buttonItem)
                } else {
                    Text("Unknown Setting: \(item.title)")
                }
            }
        } else {
             // Fallback for older OS (might need different implementation)
             Text("Setting: \(item.title)")
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsToggleRow: View {
    // Use the bound item directly
    @Binding var itemIsOn: Bool
    let label: SettingsLabel
    
    // Custom initializer to extract binding and label info
    init(item: SettingsToggleItem) {
         self._itemIsOn = item.$isOn // Pass the binding
         self.label = SettingsLabel(title: item.title, iconName: item.iconName, iconColor: item.iconColor)
    }

    var body: some View {
        Toggle(isOn: $itemIsOn) {
            label
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsLinkRow<Destination: View>: View {
    let item: SettingsLinkItem<Destination>

    var body: some View {
        NavigationLink(destination: item.destination) {
            SettingsLabel(title: item.title, iconName: item.iconName, iconColor: item.iconColor)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct SettingsExternalLinkRow: View {
    let item: SettingsExternalLinkItem

    var body: some View {
        Link(destination: item.url) {
            SettingsLabel(title: item.title, iconName: item.iconName, iconColor: item.iconColor)
                .foregroundColor(.primary) // Ensure text color is appropriate for link
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsButtonRow: View {
    let item: SettingsButtonItem

    var body: some View {
        Button(action: item.action) {
            SettingsLabel(title: item.title, iconName: item.iconName, iconColor: item.iconColor)
                .foregroundColor(item.iconColor ?? .accentColor) // Use icon color or accent for button text
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
struct SettingsLabel: View {
    let title: String
    let iconName: String?
    let iconColor: Color?

    var body: some View {
        HStack {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .foregroundColor(iconColor ?? .accentColor)
                    .frame(width: 28, alignment: .center)
            }
            Text(title)
            Spacer() // Push text to the left
        }
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension SettingsLinkItem where Destination == AnyView {
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    init<V: View>(title: String, iconName: String? = nil, iconColor: Color? = .accentColor, destination: V) {
        self.init(title: title, iconName: iconName, iconColor: iconColor, destination: AnyView(destination))
    }
}

/*
 // MARK: - Example Usage (SettingsView)
 
 import SwiftUI
 import CoreKit // Or import Settings
 
 struct AppSettingsView: View {
     // Example state variables for your app's settings
     @AppStorage("username") private var username: String = ""
     @State private var enableFeatureX = true
     @State private var showingResetAlert = false
     
     // Assume you have an instance of OnboardingManager if needed
     // @EnvironmentObject var onboardingManager: OnboardingManager // If passed via environment
     @StateObject var onboardingManager = OnboardingManager() // Or create if owned here
 
     var body: some View {
         // Use CoreKit's SettingsView, providing sections and items
         SettingsView(navigationTitle: "App Settings") {
             // Section 1: Account
             SettingsSection(title: "Account") {
                  // If you need complex views like TextField, they might need
                  // custom SettingsItem types or be placed directly in the Form
                  // For simplicity here, using standard items:
                  SettingsLinkItem(title: "Edit Profile", iconName: "person.fill", destination: EditProfileView())
             }
             
             // Section 2: Features
             SettingsSection(title: "Features") {
                 SettingsToggleItem(title: "Enable Feature X", iconName: "star.fill", isOn: $enableFeatureX)
                 // Add other feature toggles...
             }
 
             // Section 3: Data Management
              SettingsSection(title: "Data") {
                  SettingsButtonItem(title: "Reset Onboarding", iconName: "arrow.counterclockwise.circle", iconColor: .orange) {
                      showingResetAlert = true
                  }
                  // Add other buttons like "Clear Cache", "Export Data" etc.
              }
              
              // Section 4: About & Support
              SettingsSection(title: "About") {
                  SettingsExternalLinkItem(title: "Privacy Policy", iconName: "lock.shield.fill", url: URL(string: "https://yoursite.com/privacy")!)
                  SettingsExternalLinkItem(title: "Terms of Service", iconName: "doc.text.fill", url: URL(string: "https://yoursite.com/terms")!)
                  SettingsLinkItem(title: "About This App", iconName: "info.circle.fill", destination: AboutAppView())
              }
         }
         .alert("Reset Onboarding?", isPresented: $showingResetAlert) {
             Button("Reset", role: .destructive) {
                 Task { @MainActor in // Ensure UI updates on main thread
                     onboardingManager.resetOnboardingState()
                 }
             }
             Button("Cancel", role: .cancel) {}
         } message: {
             Text("This action cannot be undone.")
         }
     }
 }
 
 // Placeholder destination views
 struct EditProfileView: View { var body: some View { Text("Edit Profile Screen") } }
 struct AboutAppView: View { var body: some View { Text("About App Screen") } }
 
 #Preview {
     AppSettingsView()
 }
 */ 