import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Manages parental gates throughout the app
public class ParentalGateManager: ObservableObject {
    public static let shared = ParentalGateManager()
    
    @Published public var showParentalGate = false
    @Published public var parentalGateType: ParentalGateType = .purchase
    
    // Store the completion handler for the parental gate
    private var onApprove: (() -> Void)?
    private var onCancel: (() -> Void)?
    
    // Queue system for pending parental gate requests
    private struct PendingGateRequest {
        let type: ParentalGateType
        let onApprove: () -> Void
        let onCancel: (() -> Void)?
    }
    
    // Queue of pending gate requests
    private var gateRequestQueue: [PendingGateRequest] = []
    private var isProcessingQueue = false
    
    // Different types of parental gates for different actions
    public enum ParentalGateType {
        case purchase
        case link
        case settings
        
        var title: String {
            switch self {
            case .purchase:
                return "Confirm Purchase"
            case .link:
                return "Open Link"
            case .settings:
                return "Parental Check"
            }
        }
        
        var message: String {
            switch self {
            case .purchase:
                return "This purchase requires parental approval. Please solve this simple math problem to confirm:"
            case .link:
                return "This will open a link outside the app. Please solve this simple math problem to continue:"
            case .settings:
                return "This section requires parental approval. Please solve this simple math problem to continue:"
            }
        }
    }
    
    // Math problems for parental gate
    struct MathProblem {
        let question: String
        let options: [Int]
        let correctAnswer: Int
    }
    
    // Array of math problems to randomize
    let mathProblems: [MathProblem] = [
        MathProblem(question: "What is 9 + 4?", options: [11, 13, 14, 15], correctAnswer: 13),
        MathProblem(question: "What is 7 + 8?", options: [13, 14, 15, 16], correctAnswer: 15),
        MathProblem(question: "What is 12 - 5?", options: [5, 6, 7, 8], correctAnswer: 7),
        MathProblem(question: "What is 6 × 2?", options: [10, 11, 12, 13], correctAnswer: 12),
        MathProblem(question: "What is 20 ÷ 4?", options: [4, 5, 6, 7], correctAnswer: 5),
        MathProblem(question: "What is 4 x 4?", options: [4, 19, 16, 8], correctAnswer: 16),
        MathProblem(question: "What is 10 + 3?", options: [13, 14, 17, 12], correctAnswer: 13),
        MathProblem(question: "What is 10 - 4?", options: [4, 6, 9, 3], correctAnswer: 6),
        MathProblem(question: "What is 12 ÷ 4?", options: [4, 9, 3, 8], correctAnswer: 3)
    ]
    
    // Current math problem, changes each time the gate is shown
    @Published var currentProblem: MathProblem
    
    public init() {
        // Set an initial problem
        currentProblem = mathProblems.first!
    }
    
    /// Present parental gate for purchase actions
    public func requireParentalApprovalForPurchase(onApprove: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        enqueueGateRequest(type: .purchase, onApprove: onApprove, onCancel: onCancel)
    }
    
    /// Present parental gate for external links
    public func requireParentalApprovalForLink(onApprove: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        enqueueGateRequest(type: .link, onApprove: onApprove, onCancel: onCancel)
    }
    
    /// Present parental gate for settings changes
    public func requireParentalApprovalForSettings(onApprove: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        enqueueGateRequest(type: .settings, onApprove: onApprove, onCancel: onCancel)
    }
    
    /// Add a new gate request to the queue
    private func enqueueGateRequest(type: ParentalGateType, onApprove: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        let request = PendingGateRequest(type: type, onApprove: onApprove, onCancel: onCancel)
        gateRequestQueue.append(request)
        
        // If not currently processing, start processing the queue
        if !isProcessingQueue {
            processNextGateRequest()
        } else {
            // TODO: Consider replacing Debug.info with a proper logging mechanism for the package
             print("Parental gate request for \(type) added to queue. Queue size: \(gateRequestQueue.count)")
            //Debug.info("Parental gate request for \(type) added to queue. Queue size: \(gateRequestQueue.count)", module: "ParentalGate")
        }
    }
    
    /// Process the next gate request in the queue
    private func processNextGateRequest() {
        // Mark as processing to prevent multiple concurrent processing attempts
        isProcessingQueue = true
        
        // Check if there are any requests in the queue
        guard !gateRequestQueue.isEmpty else {
            isProcessingQueue = false
            return
        }
        
        // Get the next request (but don't remove it yet)
        let nextRequest = gateRequestQueue[0]
        
        // Show the parental gate for this request
        showGate(type: nextRequest.type, onApprove: nextRequest.onApprove, onCancel: nextRequest.onCancel)
    }
    
    /// Private method to show the gate with appropriate configuration
    private func showGate(type: ParentalGateType, onApprove: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        // Select a random math problem
        if let problem = mathProblems.randomElement() {
            currentProblem = problem
        }
        
        // Store callbacks wrapped to handle queue processing
        self.onApprove = { [weak self] in
            guard let self = self else { return }
            
            // Execute the original onApprove handler
            onApprove()
            
            // Remove this request from the queue
            if !self.gateRequestQueue.isEmpty {
                self.gateRequestQueue.removeFirst()
            }
            
            // Process the next request if available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.gateRequestQueue.isEmpty {
                    self.processNextGateRequest()
                } else {
                    self.isProcessingQueue = false
                }
            }
        }
        
        self.onCancel = { [weak self] in
            guard let self = self else { return }
            
            // Execute the original onCancel handler if provided
            onCancel?()
            
            // Remove this request from the queue
            if !self.gateRequestQueue.isEmpty {
                self.gateRequestQueue.removeFirst()
            }
            
            // Process the next request if available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !self.gateRequestQueue.isEmpty {
                    self.processNextGateRequest()
                } else {
                    self.isProcessingQueue = false
                }
            }
        }
        
        // Set the type and show the gate
        parentalGateType = type
        showParentalGate = true
        
         print("Presenting parental gate for \(type). Queue size: \(gateRequestQueue.count)")
        //Debug.info("Presenting parental gate for \(type). Queue size: \(gateRequestQueue.count)", module: "ParentalGate")
    }
    
    /// Handle user answering the parental gate
    func handleAnswer(_ answer: Int) {
        if answer == currentProblem.correctAnswer {
            //Debug.info("Parental gate: Correct answer provided", module: "ParentalGate")
             print("Parental gate: Correct answer provided")
            showParentalGate = false
            
            // Call the success handler
            onApprove?()
        } else {
            //Debug.info("Parental gate: Incorrect answer provided", module: "ParentalGate")
             print("Parental gate: Incorrect answer provided")
            showParentalGate = false
            
            // Call the cancel handler if provided
            onCancel?()
        }
    }
    
    /// Cancel the parental gate
    func cancel() {
        //Debug.info("Parental gate cancelled by user", module: "ParentalGate")
         print("Parental gate cancelled by user")
        showParentalGate = false
        
        // Call the cancel handler if provided
        onCancel?()
    }
}

// MARK: - Parental Gate View

/// Reusable parental gate view to be presented as a sheet
public struct ParentalGateView: View {
    @ObservedObject private var parentalGateManager = ParentalGateManager.shared
    
    public init() {}

    public var body: some View {
        VStack(spacing: 25) {
            // Title
            Text(parentalGateManager.parentalGateType.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
            
            // Message
            Text(parentalGateManager.parentalGateType.message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Math problem
            VStack(spacing: 15) {
                Text(parentalGateManager.currentProblem.question)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                // Answer buttons - 2x2 grid layout
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(parentalGateManager.currentProblem.options, id: \.self) { answer in
                        Button {
                            parentalGateManager.handleAnswer(answer)
                        } label: {
                            Text("\(answer)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(width: 80, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(.primary) // Use primary color for text
                        }
                    }
                }
            }
            .padding()
            
            // Adaptive background - avoid AnyShapeStyle, use conditional view composition
            if #available(iOS 15, macOS 12, *) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                    .overlay(
                        EmptyView()
                    )
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .overlay(
                        EmptyView()
                    )
            }
            
            // Cancel button
            Button("Cancel") {
                parentalGateManager.cancel()
            }
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundColor(.red)
            .padding(.top, 10)
        }
        .padding()
        // Add a background color or material to the entire VStack for better presentation
        .background(
            Group {
                if #available(macOS 12.0, iOS 15.0, *) {
                    #if canImport(UIKit)
                    Color(UIColor.systemGroupedBackground)
                    #else
                    Color.gray.opacity(0.1)
                    #endif
                } else {
                    Color.white
                }
            }
        )
        .cornerRadius(20)
        .shadow(radius: 5)
        .padding(20) // Add padding around the sheet content
    }
}

// MARK: - Parental Gate Link

/// A link view that presents a parental gate before performing its action.
public struct ParentalGateLink<Label: View>: View {
    @ObservedObject private var parentalGateManager = ParentalGateManager.shared
    private let destination: URL
    private let label: Label
    
    /// Creates a ParentalGateLink that presents a parental gate before opening a URL.
    ///
    /// - Parameters:
    ///   - destination: The URL to open after parental gate approval.
    ///   - label: The view to display as the link's label.
    public init(destination: URL, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }
    
    public var body: some View {
        Button {
            parentalGateManager.requireParentalApprovalForLink {
                #if canImport(UIKit)
                UIApplication.shared.open(destination)
                #endif
            }
        } label: {
            label
        }
        // Ensure the sheet modifier is attached to a relevant parent view
        // The ParentalGateManager's `showParentalGate` property controls presentation
        // This is typically attached higher up in the view hierarchy where the manager is initialized.
    }
}

// Convenience initializer for String labels
extension ParentalGateLink where Label == Text {
    /// Creates a ParentalGateLink with a String label.
    ///
    /// - Parameters:
    ///   - titleKey: The localized string key for the link's label.
    ///   - destination: The URL to open after parental gate approval.
    public init(_ titleKey: LocalizedStringKey, destination: URL) {
        self.init(destination: destination) { Text(titleKey) }
    }

    /// Creates a ParentalGateLink with a String label.
    ///
    /// - Parameters:
    ///   - title: The string for the link's label.
    ///   - destination: The URL to open after parental gate approval.
    public init<S: StringProtocol>(_ title: S, destination: URL) {
        self.init(destination: destination) { Text(title) }
    }
}
    
