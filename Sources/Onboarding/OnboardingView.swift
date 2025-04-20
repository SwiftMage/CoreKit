import SwiftUI
import DebugTools
#if canImport(UIKit)
import UIKit // Import UIKit for UIColor
#endif

/// A container view that orchestrates the display of onboarding steps 
/// managed by an `OnboardingManager`.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct OnboardingView: View {
    
    /// The manager controlling the onboarding flow state.
    /// Change to @ObservedObject as the manager can be passed in externally
    @ObservedObject var manager: OnboardingManager
    
    /// An action to perform when onboarding is completed or skipped.
    var onComplete: () -> Void
    
    /// A flag to allow skipping the onboarding process.
    let allowSkip: Bool

    // Moved computed properties inside the struct
    private var animationStyle: Animation {
        .spring()
    }
    
    private var transitionStyle: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        .combined(with: .opacity)
    }

    /// Initializes the OnboardingView.
    ///
    /// - Parameters:
    ///   - manager: An instance of `OnboardingManager` to control the flow. A default instance is created if none is provided.
    ///   - allowSkip: If true, a "Skip" button will be displayed. Defaults to `true`.
    ///   - onComplete: A closure to execute when the onboarding flow finishes (either completed or skipped).
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public init(manager: OnboardingManager = OnboardingManager(), allowSkip: Bool = true, onComplete: @escaping () -> Void) {
        self.manager = manager
        self.allowSkip = allowSkip
        self.onComplete = onComplete
        DebugLogger.onboarding("OnboardingView initialized. Allow skip: \(allowSkip)")
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public var body: some View {
        VStack(spacing: 0) {
            // Optional Skip Button
            if allowSkip {
                HStack {
                    Spacer()
                    Button("Skip") {
                        DebugLogger.onboarding("Skip button tapped.")
                        manager.skipOnboarding()
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
            }
            
            // Step Content Area
            ZStack {
                Color.clear 
                if manager.steps.indices.contains(manager.currentStepIndex) {
                    let currentStepView = manager.steps[manager.currentStepIndex] 
                    AnyView(currentStepView)
                        .transition(transitionStyle)
                        .id("Step_\(manager.currentStepIndex)")
                        .padding()
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .padding(.bottom)
                        Text("Error: Invalid onboarding step index (\(manager.currentStepIndex)).")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            Divider()
            
            // Navigation Controls / Footer
            let footerContent = HStack {
                // Previous Button
                Button("Previous") {
                    DebugLogger.onboarding("Previous button tapped.")
                    manager.previousStep()
                }
                .opacity(manager.isFirstStep ? 0 : 1)
                .disabled(manager.isFirstStep)

                Spacer()
                
                // Page Indicator
                if manager.steps.count > 1 {
                    PageIndicator(currentPage: $manager.currentStepIndex, pageCount: manager.steps.count)
                }

                Spacer()
                
                // Next/Finish Button - Apply style directly
                let nextButton = Button(manager.isLastStep ? "Finish" : "Next") {
                    manager.nextStep()
                }
                
                // Apply button style conditionally directly to the button
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                     nextButton
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                } else {
                     nextButton
                        .buttonStyle(.bordered) // Fallback style
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                }
            }
            .padding() // Add padding to the HStack itself
            
            // Apply background conditionally directly to the HStack
            if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                footerContent
                    .background(.thinMaterial)
            } else {
                #if canImport(UIKit)
                footerContent
                    .background(Color(UIColor.systemBackground))
                #else
                // Fallback for non-UIKit platforms (e.g., macOS)
                footerContent
                    .background(Color.gray.opacity(0.2))
                #endif
            }
        }
        // Removing the outer diagnostic background
        // .background(Color.gray.opacity(0.1)) 
        .animation(animationStyle, value: manager.currentStepIndex)
        .onChange(of: manager.isOnboardingComplete) { completed in
            if completed {
                DebugLogger.onboarding("Onboarding complete state detected by view. Calling onComplete.")
                onComplete()
            }
        }
    }
}

// MARK: - Helper Views

/// Simple page indicator dots.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct PageIndicator: View {
    @Binding var currentPage: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
// Create some dummy steps for preview
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct PreviewStep1: OnboardingStep { 
    var id = "preview1"
    var title: String = "Preview Step 1"
    var description: String = "This is the first preview step."
    var imageName: String? = "figure.walk" 
    
    var body: some View { 
        VStack {
            Text(title).font(.title)
            Text(description)
            if let imageName = imageName { Image(systemName: imageName) }
        }
    }
}
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct PreviewStep2: OnboardingStep { 
    var id = "preview2"
    var title: String = "Preview Step 2"
    var description: String = "This is the second preview step, with a different icon."
    var imageName: String? = "figure.wave" 

    var body: some View { 
        VStack {
            Text(title).font(.title)
            Text(description)
            if let imageName = imageName { Image(systemName: imageName) }
        }
    }
}
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct PreviewStep3: OnboardingStep { 
    var id = "preview3"
    var title: String = "Preview Step 3"
    var description: String = "This is the final preview step."
    var imageName: String? = nil // No icon

    var body: some View { 
        VStack {
            Text(title).font(.title)
            Text(description)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
#Preview("Onboarding Flow") {
    let previewManager = OnboardingManager(steps: [PreviewStep1(), PreviewStep2(), PreviewStep3()])
    
    OnboardingView(manager: previewManager, allowSkip: true) {
        print("Preview onboarding finished!")
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
#Preview("Onboarding Already Completed") {
    let completedManager: OnboardingManager = { 
        let manager = OnboardingManager(steps: [PreviewStep1(), PreviewStep2(), PreviewStep3()])
        manager.completeOnboarding() 
        return manager
    }()
    
    OnboardingView(manager: completedManager, allowSkip: true) {
        print("Preview onboarding finished (already complete)!")
    }
}
#endif

/*
 // MARK: - Example Usage (Onboarding)
 
 import SwiftUI
 import CoreKit // Or import Onboarding
 
 // 1. Define your custom step views in your App Target
 struct MyAppWelcomeStep: OnboardingStep {
     var id = "myAppWelcome"
     var title = "Welcome to Power Words!"
     var description = "Let's get started with positive affirmations."
     var imageName: String? = "sparkles"
 
     var body: some View {
         VStack { /* Your custom layout */
             Text(title).font(.largeTitle)
             if let imageName = imageName { Image(systemName: imageName).font(.largeTitle).padding() }
             Text(description)
         }
     }
 }
 
 struct MyAppFeatureStep: OnboardingStep {
     var id = "myAppFeatures"
     var title = "Discover Features"
     var description = "Learn how to create and manage your words."
     var imageName: String? = "wand.and.stars"
 
     var body: some View {
         VStack { /* Your custom layout */
              Text(title).font(.largeTitle)
              if let imageName = imageName { Image(systemName: imageName).font(.largeTitle).padding() }
              Text(description)
         }
     }
 }
 
 // 2. In your App's View hierarchy (e.g., ContentView or App struct)
 
 struct MainAppView: View {
     @State private var showOnboarding = !OnboardingManager().isOnboardingComplete // Check initial state
     
     // Create the manager instance and provide *your* custom steps
     @StateObject private var onboardingManager = OnboardingManager(steps: [
         MyAppWelcomeStep(),
         MyAppFeatureStep()
         // Add other steps here
     ])
 
     var body: some View {
         YourMainAppContent()
             .fullScreenCover(isPresented: $showOnboarding) {
                 // Onboarding is complete (or skipped)
                 print("Onboarding finished, dismissing cover.")
             } content: {
                 OnboardingView(manager: onboardingManager, allowSkip: true) {
                     // This is the onComplete closure from OnboardingView
                     showOnboarding = false // Dismiss the view
                 }
             }
             // Or use .sheet instead of .fullScreenCover
     }
 }
 
 struct YourMainAppContent: View {
     var body: some View { Text("Main App Content") }
 }
 */