import Foundation

class BuddyMessenger {
    static let shared = BuddyMessenger()

    // Message callbacks per buddy ID
    private var listeners: [String: (String) -> Void] = [:]

    func register(buddyID: String, handler: @escaping (String) -> Void) {
        listeners[buddyID] = handler
    }

    func unregister(buddyID: String) {
        listeners.removeValue(forKey: buddyID)
    }

    func post(to buddyID: String, message: String) {
        print("Delivering to \(buddyID): \(message)")
        listeners[buddyID]?(message)
    }
}
