import SwiftUI

// Protocol for individual onboarding steps
// Ensure it conforms to View and Identifiable
@available(iOS 14.0, macOS 10.15, tvOS 14.0, watchOS 7.0, *) // Adjust macOS version for View
public protocol OnboardingStep: View, Identifiable {
    // Identifiable requires an id. If steps naturally have one, ensure it's declared.
    // If not, add 'var id: UUID { get }' or similar.
    // Assuming steps will provide their own String ID based on previous code:
    var id: String { get }

    var title: String { get }
    var description: String { get }
    var imageName: String? { get }
    
    // Add any other common properties or methods needed by steps
    // Example: var actionButtonTitle: String? { get }
}

// Example Concrete Step (conforms to OnboardingStep, which now includes View)
// ... existing example step or remove if not needed ... 