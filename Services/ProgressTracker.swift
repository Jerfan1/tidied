import Foundation

class ProgressTracker {
    static let shared = ProgressTracker()

    private let userDefaults = UserDefaults.standard
    private let lastSwipedIndexKey = "lastSwipedIndex"

    private init() {}

    var lastSwipedIndex: Int {
        get {
            userDefaults.integer(forKey: lastSwipedIndexKey)
        }
        set {
            userDefaults.set(newValue, forKey: lastSwipedIndexKey)
        }
    }

    func reset() {
        userDefaults.removeObject(forKey: lastSwipedIndexKey)
    }
}


