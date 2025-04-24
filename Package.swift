// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CoreKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v11)
    ],
    products: [
        // Update product list to reflect renamed target
        .library(name: "CoreKit", targets: [ 
            "Onboarding",
            "ReviewManager", 
            "NotificationManager",
            "UserProfile",
            "Settings",
            "RevenueCatManager",
            "DebugTools",
            "ThemeManager", // Renamed from Utilities
            "ParentalGate" // <-- Added new target
        ])
    ],
    dependencies: [
        // Update RevenueCat dependency to match root project (>= 5.21.2)
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.21.2")
    ],
    targets: [
        // Update dependencies from "Utilities" to "ThemeManager"
        .target(name: "Onboarding", dependencies: ["ThemeManager", "DebugTools"], path: "Sources/Onboarding"),
        .target(name: "ReviewManager", dependencies: ["ThemeManager", "DebugTools"], path: "Sources/ReviewManager"), 
        .target(name: "NotificationManager", dependencies: ["ThemeManager", "DebugTools"], path: "Sources/NotificationManager"),
        .target(name: "UserProfile", dependencies: ["ThemeManager", "DebugTools"], path: "Sources/UserProfile"),
        .target(name: "Settings", dependencies: ["ThemeManager", "DebugTools"], path: "Sources/Settings"),
        .target(name: "RevenueCatManager", 
                dependencies: [
                    "ThemeManager", 
                    "DebugTools",
                    .product(name: "RevenueCat", package: "purchases-ios")
                ],
                path: "Sources/RevenueCatManager"),
        .target(name: "DebugTools", dependencies: ["ThemeManager"], path: "Sources/DebugTools"), 
        // Rename Utilities target to ThemeManager and update path
        .target(name: "ThemeManager", path: "Sources/ThemeManager"), 
        
        // --- NEW ParentalGate Target --- 
        .target(name: "ParentalGate", 
                dependencies: [], // SwiftUI/UIKit are implicit on iOS
                path: "Sources/ParentalGate"),
        // --- End ParentalGate Target --- 

        // Add other targets for future modules (Analytics, Localization, Networking, Permissions, UIComponents, AppVersion)

//        // --- Demo Application Target ---
//        .executableTarget(
//            name: "DemoApp",
//            dependencies: [
//                // Update dependency from "Utilities" to "ThemeManager"
//                "Onboarding",
//                "ReviewManager", 
//                "NotificationManager",
//                "UserProfile",
//                "Settings",
//                "RevenueCatManager",
//                "DebugTools",
//                "ThemeManager" 
//            ],
//            path: "Examples/DemoApp/Sources", // Point to the DemoApp sources
//            resources: [
//                .copy("../Resources/Assets.xcassets") // Try path relative to target source dir
//            ]
//        ),

        // --- Test Targets ---
        // Update test targets
        .testTarget(name: "OnboardingTests", dependencies: ["Onboarding"]),
        .testTarget(name: "ReviewRequestTests", dependencies: ["ReviewManager"]), 
        .testTarget(name: "NotificationManagerTests", dependencies: ["NotificationManager"]),
        .testTarget(name: "UserProfileTests", dependencies: ["UserProfile"]),
        .testTarget(name: "SettingsTests", dependencies: ["Settings"]),
        .testTarget(name: "RevenueCatManagerTests", dependencies: ["RevenueCatManager"]),
        .testTarget(name: "DebugToolsTests", dependencies: ["DebugTools"]),
        // Rename UtilitiesTests to ThemeManagerTests and update dependency
        .testTarget(name: "ThemeManagerTests", dependencies: ["ThemeManager"], path: "Tests/ThemeManagerTests"), 
    ]
) 
