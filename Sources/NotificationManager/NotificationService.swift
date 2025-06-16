import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CloudKit)
import CloudKit
#endif
import DebugTools
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CloudKit)
import CloudKit
#endif
// If using Firebase:
// import FirebaseMessaging

// Placeholder for managing push notifications (local & remote)
@available(iOS 10.0, macOS 10.14, tvOS 10.0, watchOS 3.0, *)
public class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = NotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }

    // MARK: - Permissions

    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // Registration for remote notifications should be triggered by the app
                    print("Notification permissions granted.")
                } else {
                    print("Notification permissions denied.")
                }
                completion(granted, error)
            }
        }
    }

    public func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Scheduling Local Notifications

    public func scheduleLocalNotification(identifier: String, title: String, body: String, timeInterval: TimeInterval, repeats: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled: \(identifier)")
            }
        }
    }

    public func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled pending notification: \(identifier)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification presentation while app is in foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Wrap macOS 11+ specific code
        if #available(macOS 11.0, *) { 
            DebugLogger.notification("Notification received in foreground: \(notification.request.identifier)", level: .debug)
            // Provide default presentation options - the app can override this delegate method if needed
            completionHandler([.banner, .sound, .badge])
        } else {
            // Fallback on earlier versions
            completionHandler([.sound, .badge])
        }
    }

    // Handle user tapping on notification
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        print("User tapped on notification: \(identifier)")

        // App should implement further handling via delegate or observation

        completionHandler()
    }
    
    // MARK: - Remote Notifications Helpers (Optional)
    
    #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
    // Only available on platforms with UIApplication
    
    /// Requests registration for remote notifications with APNS.
    /// Call this after obtaining user authorization.
    /// Requires the app to have the Push Notifications capability enabled.
    public func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            DebugLogger.notification("Attempting to register for remote notifications with APNS.", level: .info)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Handles successful registration for remote notifications.
    /// Call this from your `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` delegate method.
    /// - Parameter deviceToken: The device token data received from APNS.
    public func handleRemoteNotificationRegistration(didRegister deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        DebugLogger.notification("Successfully registered for remote notifications. Device Token: \(tokenString)", level: .info)
        // TODO: Send token to your server or handle as needed (e.g., for non-CloudKit providers)
    }
    
    /// Handles failed registration for remote notifications.
    /// Call this from your `application(_:didFailToRegisterForRemoteNotificationsWithError:)` delegate method.
    /// - Parameter error: The error received.
    public func handleRemoteNotificationRegistration(didFail error: Error) {
        DebugLogger.notification("Failed to register for remote notifications: \(error.localizedDescription)", level: .error)
    }
    
    /// Handles an incoming remote notification payload.
    /// Call this from your `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` delegate method.
    /// - Parameters:
    ///   - userInfo: The notification payload dictionary.
    ///   - fetchCompletionHandler: The completion handler to call when processing is done.
    public func handleRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DebugLogger.notification("Received remote notification payload: \(userInfo)", level: .debug)
        
        #if canImport(CloudKit)
        // Attempt to parse as a CloudKit notification
        if let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            DebugLogger.notification("Parsed as CloudKit notification. Type: \(ckNotification.notificationType.rawValue)", level: .info)
            if let queryNotification = ckNotification as? CKQueryNotification {
                DebugLogger.notification("CloudKit Query Notification Details: ID=\(queryNotification.notificationID?.description ?? "N/A"), Reason=\(queryNotification.queryNotificationReason.rawValue), RecordID=\(queryNotification.recordID?.recordName ?? "N/A")", level: .debug)
                // App should handle fetching data based on this notification
            }
            // Handle other CKNotification types (database, record zone) if needed
        } else {
             DebugLogger.notification("Payload is not a standard CloudKit notification.", level: .debug)
        }
        #else
        DebugLogger.notification("CloudKit framework not available for parsing CKNotification.", level: .info)
        #endif
        
        // App must perform actual data fetching and UI updates.
        // Call completion handler appropriately based on whether new data was fetched.
        // For now, we assume no data was fetched by this helper.
        fetchCompletionHandler(.noData)
    }
    
    #endif // canImport(UIKit)
}

// Removed UIKit import 

/*
 // MARK: - Example Usage (NotificationService)
 
 import CoreKit // Or import NotificationManager
 import UserNotifications // Still needed for UNAuthorizationStatus etc.
 
 // --- Typically called early in the app lifecycle (e.g., AppDelegate or on appear) ---
 func setupNotifications() {
     NotificationService.shared.checkAuthorizationStatus { status in
         if status == .notDetermined {
             NotificationService.shared.requestAuthorization { granted, error in
                 if granted {
                     print("Notifications Authorized!")
                     // Register for remote notifications if needed (UIApplication.shared.registerForRemoteNotifications())
                 } else if let error = error {
                      print("Notification authorization error: \(error.localizedDescription)")
                 } else {
                     print("Notifications Denied.")
                 }
             }
         } else if status == .authorized {
              print("Notifications already authorized.")
              // Register for remote notifications if needed
         } else {
              print("Notifications are denied or restricted.")
         }
     }
 }
 
 // --- Scheduling a local notification ---
 func scheduleReminder() {
     NotificationService.shared.scheduleLocalNotification(
         identifier: "dailyReminder",
         title: "Power Words Practice",
         body: "Time for your daily affirmation practice!",
         timeInterval: 60, // e.g., 60 seconds from now (use CalendarNotificationTrigger for specific times)
         repeats: false
     )
 }
 
 // --- Cancelling a notification ---
 func cancelReminder() {
     NotificationService.shared.cancelNotification(identifier: "dailyReminder")
 }
 
 // --- Handling Notification Delegate Callbacks ---
 // If you need custom foreground presentation or response handling beyond
 // what's default in NotificationService, you need to set your app's own
 // UNUserNotificationCenter delegate (e.g., in AppDelegate) AFTER CoreKit's
 // setup, or provide delegate methods within NotificationService if that suits your design.
 // Example in AppDelegate:
 // UNUserNotificationCenter.current().delegate = self // In didFinishLaunching...
 // Then implement the delegate methods in AppDelegate.
 
 */ 