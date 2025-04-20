import SwiftUI
import Onboarding

/// A view that manages and displays a sequence of onboarding steps.
@available(iOS 14.0, macOS 11.0, *) // Ensure compatibility with steps
struct OnboardingContainerView: View { // Revert: Remove generic parameter
    /// The sequence of onboarding steps to display.
    let steps: [any OnboardingStep] // Revert: Use existential type
    
    /// State variable to track the currently displayed step index.
    @State private var currentStepIndex = 0
    
    /// Callback action to perform when the final step's button is tapped.
    var onFinish: () -> Void
    
    var body: some View {
        VStack {
            // TabView to display onboarding steps with page-style interaction
            TabView(selection: $currentStepIndex) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    // Use AnyView for type erasure
                    AnyView(step.body)
                        .tag(index) // Tag each view for selection binding
                        .padding(.bottom, 60) // Add padding to avoid overlap with buttons
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic)) // Use page-style swiping
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Navigation buttons
            HStack {
                // Previous Button
                Button("Previous") {
                    withAnimation {
                        currentStepIndex -= 1
                    }
                }
                .disabled(currentStepIndex == 0) // Disable if on the first step
                .padding()

                Spacer() // Push buttons to edges

                // Next / Finish Button
                Button(currentStepIndex == steps.count - 1 ? "Finish" : "Next") {
                    if currentStepIndex == steps.count - 1 {
                        onFinish() // Call the finish action on the last step
                    } else {
                        withAnimation {
                            currentStepIndex += 1 // Go to the next step
                        }
                    }
                }
                .padding()
            }
            .padding(.horizontal) // Add horizontal padding to the button row
            .padding(.bottom) // Add bottom padding
        }
    }

    // Remove the nested StepView again, not needed with AnyView
}

// MARK: - Previews
@available(iOS 14.0, macOS 11.0, *)
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        // Initialize with mixed steps - should work now
        OnboardingContainerView(steps: [DemoStep1(), DemoStep2(), DemoStep3()], onFinish: {
            print("Onboarding Finished!") // Simple action for preview
        })
    }
} 
