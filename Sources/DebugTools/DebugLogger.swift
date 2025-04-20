import Foundation
import OSLog // Use Apple's unified logging system

// Centralized Debug Logging System
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct DebugLogger {

    // Define different log levels/categories
    public enum LogLevel: String {
        case debug = "🐛 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "🔥 ERROR"
        case trace = "🔍 TRACE" // For detailed function tracing
    }

    // Configuration
    public static var enabledLogLevels: Set<LogLevel> = [.debug, .info, .warning, .error, .trace] // Default: all enabled
    public static var isTracingEnabled: Bool = true // Global toggle for function tracing

    // Create OSLog instances for different subsystems/categories
    // Use your app bundle identifier or a relevant subsystem name
    // Marked public to be accessible by other modules like CoreDataManager
    public static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourapp.corekit"

    // Make loggers internal so they can be used by convenience functions
    // but not directly exposed as public API of DebugLogger.
    static let generalLog = Logger(subsystem: subsystem, category: "General")
    static let onboardingLog = Logger(subsystem: subsystem, category: "Onboarding")
    static let networkLog = Logger(subsystem: subsystem, category: "Network")
    static let uiLog = Logger(subsystem: subsystem, category: "UI")
    static let coreDataLog = Logger(subsystem: subsystem, category: "CoreData")
    static let reviewLog = Logger(subsystem: subsystem, category: "Review")
    static let notificationLog = Logger(subsystem: subsystem, category: "Notification")
    static let revenueCatLog = Logger(subsystem: subsystem, category: "RevenueCat") // Add RevenueCat logger
    static let userProfileLog = Logger(subsystem: subsystem, category: "UserProfile") // Add UserProfile logger

    // MARK: - Logging Functions

    // Internal log function - takes the specific Logger instance
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    internal static func _log(_ message: String, level: LogLevel = .debug, category: Logger, file: String = #file, function: String = #function, line: Int = #line) {
        guard enabledLogLevels.contains(level) else { return }

        let fileName = (file as NSString).lastPathComponent
        // Use string interpolation directly with Logger
        let logMessage = "\(level.rawValue) [\(fileName):\(line) \(function)] \(message)"

        // Print to console only in DEBUG builds AND when not running for Previews
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print(logMessage)
        }
        #endif
        
        // The Logger methods handle the OSLogMessage creation implicitly
        switch level {
        case .debug:
            category.debug("\(logMessage, privacy: .public)")
        case .info:
            category.info("\(logMessage, privacy: .public)")
        case .warning:
            category.warning("\(logMessage, privacy: .public)")
        case .error:
            category.error("\(logMessage, privacy: .public)")
        case .trace:
            category.debug("\(logMessage, privacy: .public)") // Treat trace as debug
        }
    }
    
    // Public log function defaults to general category
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func log(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        _log(message, level: level, category: generalLog, file: file, function: function, line: line)
    }

    // Convenience logging functions for specific categories
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func onboarding(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        _log(message, level: level, category: onboardingLog, file: file, function: function, line: line)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func network(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        _log(message, level: level, category: networkLog, file: file, function: function, line: line)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func ui(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        _log(message, level: level, category: uiLog, file: file, function: function, line: line)
    }
    
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func coreData(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
         _log(message, level: level, category: coreDataLog, file: file, function: function, line: line)
    }
    
    // Add new convenience function for Review category
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func review(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
         _log(message, level: level, category: reviewLog, file: file, function: function, line: line)
    }

    // Add new convenience function for Notification category
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func notification(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
         _log(message, level: level, category: notificationLog, file: file, function: function, line: line)
    }

    // Add new convenience function for RevenueCat category
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func revenueCat(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
         _log(message, level: level, category: revenueCatLog, file: file, function: function, line: line)
    }

    // Add new convenience function for UserProfile category
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func userProfile(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
         _log(message, level: level, category: userProfileLog, file: file, function: function, line: line)
    }

    // MARK: - Function Tracing

    // Logs the entry into a function
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func traceEnter(function: String = #function, file: String = #file, line: Int = #line) {
        guard isTracingEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        let message = "Entering function"
        let logMessage = "\(LogLevel.trace.rawValue) [\(fileName):\(line) \(function)] \(message)"
        generalLog.debug("\(logMessage, privacy: .public)") // Use debug level for trace
    }

    // Logs the exit from a function
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func traceExit(function: String = #function, file: String = #file, line: Int = #line) {
        guard isTracingEnabled else { return }
        let fileName = (file as NSString).lastPathComponent
        let message = "Exiting function"
        let logMessage = "\(LogLevel.trace.rawValue) [\(fileName):\(line) \(function)] \(message)"
        generalLog.debug("\(logMessage, privacy: .public)") // Use debug level for trace
    }
    
    // Helper to trace function execution with entry and exit logs
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public static func trace<T>(function: String = #function, file: String = #file, line: Int = #line, _ block: () throws -> T) rethrows -> T {
        traceEnter(function: function, file: file, line: line)
        defer { traceExit(function: function, file: file, line: line) }
        return try block()
    }
}

/*
 // MARK: - Example Usage (DebugLogger)
 
 import CoreKit // Import the whole package
 // Or: import DebugTools // Import just the module
 
 // --- Basic Logging ---
 DebugLogger.log("This is a general debug message.")
 DebugLogger.log("User profile loaded.", level: .info)
 DebugLogger.log("Network request failed!", level: .error)
 
 // --- Using Convenience Functions ---
 DebugLogger.onboarding("Showing welcome step.")
 DebugLogger.review("Significant event threshold met.", level: .info)
 DebugLogger.notification("Notification permission granted.", level: .info)
 DebugLogger.revenueCat("Fetching offerings.", level: .debug)
 
 // --- Function Tracing ---
 func myImportantFunction() throws {
     // Automatically logs entry and exit
     try DebugLogger.trace {
         DebugLogger.log("Doing important work...")
         // ... function body ...
         if Bool.random() { throw MyError.someError }
     }
 }
 
 enum MyError: Error { case someError }
 
 // --- Configuration (Optional - Usually done once at app start) ---
 // Show only warnings and errors:
 // DebugLogger.enabledLogLevels = [.warning, .error]
 // Disable function tracing globally:
 // DebugLogger.isTracingEnabled = false
 
 */ 
