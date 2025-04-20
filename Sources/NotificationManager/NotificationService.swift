import Foundation
import UserNotifications
import DebugTools
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
    
    // MARK: - Remote Notifications (Placeholder - App Specific)
    /*
    These methods typically belong in the AppDelegate or equivalent app lifecycle manager,
    as they handle app-level events related to push registration.
    CoreKit can provide helpers, but shouldn't directly handle these callbacks.
    
    // Example helper if CoreKit managed token formatting:
    public func formatDeviceToken(_ deviceToken: Data) -> String {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Formatted Device Token: \(token)")
        return token
    }
    */
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