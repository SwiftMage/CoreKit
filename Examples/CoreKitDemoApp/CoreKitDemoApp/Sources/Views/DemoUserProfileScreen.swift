import SwiftUI
//import CoreKit
import DebugTools // Only needed if adding logging here
import UserProfile

/// A screen demonstrating the CoreKit UserProfile module.
@available(iOS 15.0, macOS 12.0, *) // Match ContentView availability
struct DemoUserProfileScreen: View {
    
    // State for User Profile Demo
    @StateObject private var profileManager = UserProfileManager()
    @State private var newNameInput: String = ""
    
    var body: some View {
        Form { // Use Form for settings-like layout
            if let user = profileManager.currentUser {
                Section("Current Profile") {
                    // Display Profile Info using HStack for broader compatibility
                    HStack {
                        Text("ID:").bold()
                        Spacer()
                        Text(user.id)
                    }
                    HStack {
                        Text("Name:").bold()
                        Spacer()
                        Text(user.name ?? "-")
                    }
                     HStack {
                        Text("Email:").bold()
                        Spacer()
                        Text(user.email ?? "-")
                    }
                     HStack {
                        Text("Created:").bold()
                        Spacer()
                        Text(user.creationDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let lastLogin = user.lastLoginDate {
                         HStack {
                            Text("Last Login:").bold()
                            Spacer()
                            Text(lastLogin.formatted(.relative(presentation: .named)))
                        }
                    }
                }
                
                Section("Update Profile") {
                    // Update Name Field
                    HStack {
                        TextField("New Name", text: $newNameInput)
                            .textFieldStyle(.roundedBorder)
                        Button("Update") {
                            if !newNameInput.isEmpty {
                                profileManager.updateUserProfile(name: newNameInput)
                                newNameInput = "" // Clear field
                            }
                        }.buttonStyle(.bordered)
                         .disabled(newNameInput.isEmpty)
                    }
                    
                    // Update Last Login Button
                    Button("Update Last Login Date") {
                         profileManager.updateUserProfile(lastLoginDate: Date())
                    }
                }
                
                Section("Actions") {
                    // Clear Profile Button
                    Button("Clear Profile (Logout)", role: .destructive) {
                        profileManager.clearCurrentUser()
                    }
                }
                
            } else {
                 Section("No Profile") {
                    Text("No current user profile loaded.")
                    Button("Create Default Profile") {
                         let defaultProfile = UserProfile(name: "Demo User", email: "demo@example.com")
                         profileManager.setCurrentUser(defaultProfile)
                    }
                 }
            }
        }
        .navigationTitle("User Profile Demo")
    }
}

#Preview {
     if #available(iOS 15.0, macOS 12.0, *) {
         NavigationView { // Add NavigationView for preview context
            DemoUserProfileScreen()
         }
     } else {
         Text("Preview requires iOS 15+ or macOS 12+")
     }
} 
