import SwiftUI
import Onboarding

/// A simple onboarding step for the demo app.
@available(iOS 14.0, macOS 11.0, *) // Match OnboardingView availability
struct DemoStep1: OnboardingStep {
    var id = "demoStep1"
    var title: String = "Welcome!"
    var description: String = "This is the first step of the DemoApp onboarding flow."
    var imageName: String? = "figure.wave"
    
    var body: some View {
        VStack(spacing: 20) {
            if let imageName = imageName {
                Image(systemName: imageName)
                    .resizable().scaledToFit()
                    .frame(height: 100).foregroundColor(.blue)
            }
            Text(title).font(.largeTitle).bold()
            Text(description).multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// Another simple onboarding step for the demo app.
@available(iOS 14.0, macOS 11.0, *) // Match OnboardingView availability
struct DemoStep2: OnboardingStep {
    var id = "demoStep2"
    var title: String = "Features"
    var description: String = "This app demonstrates CoreKit features like Debugging, Settings, and more."
    var imageName: String? = "star.fill"
    
    var body: some View {
        VStack(spacing: 20) {
            if let imageName = imageName {
                Image(systemName: imageName)
                    .resizable().scaledToFit()
                    .frame(height: 100).foregroundColor(.yellow)
            }
            Text(title).font(.largeTitle).bold()
            Text(description).multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// Final simple onboarding step for the demo app.
@available(iOS 14.0, macOS 11.0, *) // Match OnboardingView availability
struct DemoStep3: OnboardingStep {
    var id = "demoStep3"
    var title: String = "Ready?"
    var description: String = "Tap Finish to explore the CoreKit Demo App!"
    var imageName: String? = "hand.thumbsup.fill"
    
    var body: some View {
        VStack(spacing: 20) {
            if let imageName = imageName {
                Image(systemName: imageName)
                    .resizable().scaledToFit()
                    .frame(height: 100).foregroundColor(.green)
            }
            Text(title).font(.largeTitle).bold()
            Text(description).multilineTextAlignment(.center)
        }
        .padding()
    }
} 
