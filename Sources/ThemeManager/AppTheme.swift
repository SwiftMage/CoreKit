import SwiftUI
import Foundation // Needed for Bundle
// UIKit import is moved inside #if DEBUG below

// Helper to find the correct bundle for the package resources
private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var module: Bundle = {
        let bundleName = "CoreKit_Utilities" // Matches the target name in Package.swift potentially with _

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is built directly.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
            
            // Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/".)
             Bundle(for: BundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
             Bundle(for: BundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent(),

        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                // print("Found bundle at: \(bundle.bundlePath)")
                return bundle
            }
        }
        // Fallback attempt using Bundle(for:)
        // print("Fallback bundle: \(Bundle(for: BundleFinder.self))")
        // return Bundle(for: BundleFinder.self)
         print("Warning: Unable to find bundle named \(bundleName). Using Bundle(for: BundleFinder.self) as fallback.")
         return Bundle(for: BundleFinder.self)
         // fatalError("unable to find bundle named \(bundleName)")
    }()
}

// MARK: - App Colors

/// Provides centralized access to app colors defined in an Asset Catalog.
/// Ensure an Asset Catalog (e.g., "Media.xcassets") is included in the Utilities target.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AppColors {

    // MARK: - Primary Colors
    // Example: Define colors in your Assets.xcassets and reference by name
    // Ensure an Asset Catalog named e.g., "Media.xcassets" is part of the Utilities target.
    // Use .module bundle for Swift Packages.
    public static let primary = Color("PrimaryColor", bundle: Bundle.module)
    public static let secondary = Color("SecondaryColor", bundle: Bundle.module)
    
    // MARK: - Accent Colors
    public static let accent = Color.accentColor // Use SwiftUI's dynamic accent color
    public static let accentVariant = Color("AccentVariantColor", bundle: Bundle.module) // Assumes "AccentVariantColor" exists

    // MARK: - Background Colors
    public static let background = Color("BackgroundColor", bundle: Bundle.module) // Assumes "BackgroundColor" exists
    public static let surface = Color("SurfaceColor", bundle: Bundle.module) // Assumes "SurfaceColor" exists (for cards, sheets)

    // MARK: - Text Colors
    public static let textPrimary = Color("TextPrimaryColor", bundle: Bundle.module) // Assumes "TextPrimaryColor" exists
    public static let textSecondary = Color("TextSecondaryColor", bundle: Bundle.module) // Assumes "TextSecondaryColor" exists
    public static let textOnPrimary = Color("TextOnPrimary", bundle: Bundle.module) // Text color for on top of primary background
    public static let textOnAccent = Color.white // Example

    // MARK: - Semantic Colors
    public static let error = Color.red
    public static let success = Color.green
    public static let warning = Color.orange

    // Removed isDarkMode check - Use @Environment(\.colorScheme) == .dark in SwiftUI views instead.
}

// MARK: - Fonts

/// Provides centralized access to app fonts.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct AppFonts {
    
    // Example: Define custom fonts (ensure they are added to the project and Info.plist)
    // static let customFontName = "YourCustomFont-Regular"
    // static let customFontBoldName = "YourCustomFont-Bold"

    public static func regular(size: CGFloat) -> Font {
        // Use system font as default
        .system(size: size, weight: .regular)
        // Or load custom font:
        // Font.custom(customFontName, size: size)
    }

    public static func medium(size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    public static func semibold(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    public static func bold(size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
        // Or load custom font:
        // Font.custom(customFontBoldName, size: size)
    }
    
    // Define specific text styles if needed
    public static let title: Font = bold(size: 28)
    public static let headline: Font = semibold(size: 17)
    public static let body: Font = regular(size: 17)
    public static let caption: Font = regular(size: 12)
    public static let button: Font = medium(size: 18)
}

// Preview block removed to ensure compatibility with command-line swift build 