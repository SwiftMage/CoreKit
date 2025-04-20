import CoreData
import Foundation
import DebugTools
import OSLog // Import OSLog

// Manages the Core Data stack (NSPersistentContainer)
// Add availability for Logger usage
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public class CoreDataManager {

    // MARK: - Properties

    /// The shared singleton instance.
    /// Consider if a singleton is truly needed or if injection is better.
    public static let shared = CoreDataManager()

    /// The persistent container for the Core Data stack.
    /// It needs the name of your *.xcdatamodeld file.
    public let persistentContainer: NSPersistentContainer

    /// The main managed object context associated with the main queue.
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// The name of the Core Data model file (without extension).
    /// This needs to be provided by the app integrating CoreKit.
    private static var modelName: String? = nil
    
    /// URL for the Core Data store.
    /// Defaults to Application Support directory.
    private static var storeURL: URL? = nil

    // MARK: - Initialization

    /// Private initializer for singleton pattern.
    private init(inMemory: Bool = false) {
        guard let modelName = Self.modelName else {
            // Use DebugLogger before fatalError if possible, though it might not log if subsystem is needed
            // DebugLogger.coreData("CoreDataManager Error: Model name not configured.", level: .error)
            fatalError("CoreDataManager Error: Model name not configured. Call CoreDataManager.configure(modelName:storeURL:) first.")
        }
        
        // --- Step 1: Load the ManagedObjectModel ---
        let managedObjectModel: NSManagedObjectModel = {
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
                 // Attempt to find in other bundles
                 let modelInBundle = Bundle.allBundles.lazy.compactMap { $0.url(forResource: modelName, withExtension: "momd") }.first
                 if let url = modelInBundle, let model = NSManagedObjectModel(contentsOf: url) {
                     DebugLogger.coreData("Loaded Core Data model '\(modelName)' from bundle: \(url.absoluteString)")
                     return model
                 } else {
                    fatalError("CoreDataManager Error: Unable to find Core Data model '\(modelName).momd' in any bundle.")
                 }
            }
            // Found in main bundle
            guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
                 fatalError("CoreDataManager Error: Unable to load Core Data model from URL: \(modelURL)")
            }
             DebugLogger.coreData("Loaded Core Data model '\(modelName)' from main bundle.")
            return model
        }()
        
        // --- Step 2: Initialize the NSPersistentContainer ---
        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        
        // --- Step 3: Determine and Configure the Store URL ---
        let finalStoreURL: URL
        if let configuredURL = Self.storeURL {
            finalStoreURL = configuredURL
        } else {
            let defaultDirectory = NSPersistentContainer.defaultDirectoryURL()
            finalStoreURL = defaultDirectory.appendingPathComponent("\(modelName).sqlite")
        }
        DebugLogger.coreData("Core Data Store URL: \(finalStoreURL.path)")

        if let description = persistentContainer.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
                description.type = NSInMemoryStoreType
                DebugLogger.coreData("Using in-memory Core Data store.")
            } else {
                 description.url = finalStoreURL // Set the actual store URL
                 description.setOption(NSNumber(value: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
                 description.setOption(NSNumber(value: true), forKey: NSInferMappingModelAutomaticallyOption)
                 DebugLogger.coreData("Set persistent store URL and migration options.")
            }
        } else {
            DebugLogger.coreData("Could not find persistent store description to configure.", level: .warning)
        }

        // --- Step 4: Load Persistent Stores ---
        // Now it's safe to load stores as persistentContainer is fully initialized
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Log detailed error information
                DebugLogger.coreData("Unresolved Core Data error: \(error), \(error.userInfo)", level: .error)
                // Consider more robust error handling for production apps
                // fatalError("Unresolved error \(error), \(error.userInfo)") 
            } else {
                DebugLogger.coreData("Persistent store loaded successfully: \(storeDescription.url?.path ?? "N/A")")
                // Configure context properties after loading
                self.viewContext.automaticallyMergesChangesFromParent = true
                self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
    }
    
    /// Shared instance specifically for in-memory storage (useful for previews or tests).
    public static let preview = CoreDataManager(inMemory: true)

    // MARK: - Configuration
    
    private static var hasConfigured = false
    
    /// Configures the Core Data Manager. Must be called once before accessing `shared`.
    /// - Parameters:
    ///   - modelName: The name of your `.xcdatamodeld` file (without the extension).
    ///   - storeURL: Optional. A specific URL to store the database file. If nil, uses the default Application Support directory.
    @MainActor // Ensure configuration happens on main actor if it triggers UI-related init
    public static func configure(modelName: String, storeURL: URL? = nil) {
         guard !hasConfigured else {
            DebugLogger.coreData("CoreDataManager already configured.", level: .warning)
            return
        }
        Self.modelName = modelName
        Self.storeURL = storeURL
        hasConfigured = true
        DebugLogger.coreData("CoreDataManager configured with model: \(modelName)")
        // Accessing shared here will trigger initialization if not already done
        _ = CoreDataManager.shared 
    }

    // MARK: - Core Data Saving support

    /// Saves changes in the main context if there are any.
    public func saveContext() {
        saveContext(viewContext)
    }
    
    /// Saves changes in the specified context if there are any.
    /// - Parameter context: The managed object context to save.
    public func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }

        context.performAndWait { // Use performAndWait for synchronous save, or perform for async
            do {
                try context.save()
                DebugLogger.coreData("Context saved successfully.")
            } catch {
                let nserror = error as NSError
                DebugLogger.coreData("Unresolved error saving context: \(nserror), \(nserror.userInfo)", level: .error)
                // Consider appropriate error handling for your app
                // For example, showing an alert to the user
            }
        }
    }

    // MARK: - Background Context

    /// Creates and returns a new background managed object context.
    /// Changes made in this context must be saved and merged back to the main context.
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy // Or choose another policy
        return context
    }
}

// Dedicated logger category structure removed, using DebugLogger.coreData directly. 