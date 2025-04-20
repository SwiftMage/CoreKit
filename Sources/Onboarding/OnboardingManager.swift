import Foundation
import SwiftUI
import Combine
import DebugTools


// Define a protocol for an onboarding step
//@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
//public protocol OnboardingStep: View, Identifiable {
//    var id: String { get }
//    // Add any common properties or methods needed for steps
//}

// Example concrete step (replace with actual step views later)
//@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
//public struct WelcomeStepView: OnboardingStep {
//    public var id: String = "welcome"
//    
//    public var title: String = "Welcome to Power Words!"
//    public var description: String = "Discover the power of positive affirmations."
//    public var imageName: String? = "figure.wave" // Example SF Symbol
//
//    public var body: some View {
//        VStack(spacing: 20) {
//            if let imageName = imageName {
//                Image(systemName: imageName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 100)
//                    .foregroundColor(.accentColor)
//            }
//            Text(title).font(.largeTitle).fontWeight(.bold)
//            Text(description).font(.body).multilineTextAlignment(.center)
//        }
//        .padding()
//    }
//}

// Example concrete step 2
//@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
//public struct FeatureStepView: OnboardingStep {
//    public var id: String = "features"
//    
//    public var title: String = "Key Features"
//    public var description: String = "Learn how to create, manage, and use your power words effectively."
//    public var imageName: String? = "wand.and.stars"
//
//    public var body: some View {
//        VStack(spacing: 20) {
//             if let imageName = imageName {
//                Image(systemName: imageName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: 100)
//                    .foregroundColor(.purple)
//            }
//            Text(title).font(.largeTitle).fontWeight(.bold)
//            Text(description).font(.body).multilineTextAlignment(.center)
//        }
//        .padding()
//    }
//}

// Main controller for the onboarding flow
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public class OnboardingManager: ObservableObject {
    
    @Published public var currentStepIndex: Int = 0
    @Published public private(set) var isOnboardingComplete: Bool = false
    
    // This should be configurable by the app integrating the package.
    // Initialize with an empty array; steps should be injected or configured.
    
    public var steps: [any OnboardingStep] = []
    
    private let onboardingCompleteKey = "onboardingComplete"
    private var cancellables = Set<AnyCancellable>()

    public init(steps: [any OnboardingStep]? = nil) {
        DebugLogger.onboarding("Initializing OnboardingManager.")
        if let providedSteps = steps, !providedSteps.isEmpty {
            self.steps = providedSteps
            DebugLogger.onboarding("Using provided onboarding steps. Count: \(providedSteps.count)")
        }
        loadState()
        
        // Example of observing changes (optional)
        $currentStepIndex
            .sink { index in
                DebugLogger.onboarding("Current step index changed to: \(index)")
                // Could add logic here if needed when step changes
            }
            .store(in: &cancellables)

        $isOnboardingComplete
            .sink { completed in
                // For just logging, self isn't required here.
                if completed {
                    DebugLogger.onboarding("Onboarding complete state change detected. User Defaults: \(UserDefaults.standard.bool(forKey: self.onboardingCompleteKey))", level: .info)
                } else {
                    DebugLogger.onboarding("Onboarding reset detected.", level: .debug)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - State Management

    private func loadState() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: onboardingCompleteKey)
        DebugLogger.onboarding("Loaded state - isOnboardingComplete: \(self.isOnboardingComplete)")
        // Reset to step 0 if onboarding isn't complete, otherwise stay at 0 (or last step?)
        if !self.isOnboardingComplete {
            self.currentStepIndex = 0 
        } else {
            // If already complete, perhaps jump to end? Or stay at 0? Depends on desired UX.
            self.currentStepIndex = 0 // Or steps.count - 1, or keep saved index?
        }
    }

    private func saveState() {
        UserDefaults.standard.set(isOnboardingComplete, forKey: onboardingCompleteKey)
        DebugLogger.onboarding("Saved state - isOnboardingComplete: \(self.isOnboardingComplete)")
        // Could also save currentStepIndex if needed to resume mid-flow
    }

    // MARK: - Navigation

    public var isFirstStep: Bool {
        currentStepIndex == 0
    }

    public var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    @MainActor
    public func nextStep() {
        DebugLogger.onboarding("Next step requested. Current: \(currentStepIndex)")
        if !isLastStep {
            currentStepIndex += 1
        } else {
            completeOnboarding()
        }
    }

    @MainActor
    public func previousStep() {
        DebugLogger.onboarding("Previous step requested. Current: \(currentStepIndex)")
        if !isFirstStep {
            currentStepIndex -= 1
        }
    }

    @MainActor
    public func completeOnboarding() {
        DebugLogger.onboarding("Completing onboarding.")
        isOnboardingComplete = true
        saveState()
        // Potentially reset index after completion if the view will be dismissed
        // currentStepIndex = 0 
    }
    
    @MainActor
    public func skipOnboarding() {
         DebugLogger.onboarding("Skipping onboarding.")
         completeOnboarding() // Treat skip as completion
    }
    
    // MARK: - Reset (for debugging/testing)
    
    @MainActor
    public func resetOnboardingState() {
        DebugLogger.onboarding("Resetting onboarding state.")
        isOnboardingComplete = false
        currentStepIndex = 0
        saveState()
    }
}

// --- Placeholder View (Will be refined in OnboardingView.swift) ---
/*
public struct OnboardingContainerView: View {
    @StateObject var manager: OnboardingManager
    var onComplete: () -> Void

    public init(manager: OnboardingManager = OnboardingManager(), onComplete: @escaping () -> Void) {
        _manager = StateObject(wrappedValue: manager)
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack {
            if manager.steps.indices.contains(manager.currentStepIndex) {
                // Display the current step view
                AnyView(manager.steps[manager.currentStepIndex])
                    .transition(.slide) // Add transition
                    .id(manager.currentStepIndex) // Ensure view updates
            } else {
                Text("Invalid onboarding step.") // Error state
            }
            
            Spacer()
            
            // Navigation Controls
            HStack {
                if !manager.isFirstStep {
                    Button("Previous") { manager.previousStep() }
                }
                Spacer()
                Button(manager.isLastStep ? "Finish" : "Next") { manager.nextStep() }
            }
            .padding()
        }
        .animation(.default, value: manager.currentStepIndex)
        .onChange(of: manager.isOnboardingComplete) { _, completed in
            if completed {
                onComplete()
            }
        }
    }
}
*/ 
