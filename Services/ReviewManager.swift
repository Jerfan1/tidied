import StoreKit
import UIKit

/// Manages App Store review prompts at optimal moments
/// 100% local - no data collected, no network calls
class ReviewManager {
    static let shared = ReviewManager()
    
    private let lastRequestKey = "review_lastRequestDate"
    private let installDateKey = "review_installDate"
    
    // Thresholds
    private let minDaysBetweenRequests = 90
    private let minDaysSinceInstall = 3
    private let minDeletedPhotos = 10
    
    private init() {
        // Record install date on first launch
        if UserDefaults.standard.object(forKey: installDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
        }
    }
    
    /// Call this after a successful deletion (win moment)
    func requestReviewIfAppropriate(deletedCount: Int) {
        // Check minimum deleted photos
        guard deletedCount >= minDeletedPhotos else { return }
        
        // Check days since install
        guard daysSinceInstall() >= minDaysSinceInstall else { return }
        
        // Check days since last request
        guard daysSinceLastRequest() >= minDaysBetweenRequests else { return }
        
        // All conditions met - request review
        requestReview()
    }
    
    private func requestReview() {
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            
            // Request review through Apple's API
            SKStoreReviewController.requestReview(in: windowScene)
            
            // Record the request date
            UserDefaults.standard.set(Date(), forKey: lastRequestKey)
        }
    }
    
    private func daysSinceInstall() -> Int {
        guard let installDate = UserDefaults.standard.object(forKey: installDateKey) as? Date else {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }
    
    private func daysSinceLastRequest() -> Int {
        guard let lastRequest = UserDefaults.standard.object(forKey: lastRequestKey) as? Date else {
            return Int.max // Never requested before
        }
        return Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
    }
}
