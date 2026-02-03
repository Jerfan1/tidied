import StoreKit
import UIKit

/// Manages App Store review prompts at optimal moments
/// 100% local - no data collected, no network calls
class ReviewManager {
    static let shared = ReviewManager()
    
    private let hasRequestedFirstMonthReviewKey = "review_hasRequestedFirstMonth"
    
    private init() {}
    
    /// Call this after first month completion - the ideal "win moment"
    /// Triggers before paywall (which is at 3 months) to maximize positive reviews
    func requestReviewOnFirstMonthCompletion(monthsCompleted: Int) {
        // Only trigger on first month completion
        guard monthsCompleted == 1 else { return }
        
        // Only request once for this trigger
        guard !UserDefaults.standard.bool(forKey: hasRequestedFirstMonthReviewKey) else { return }
        
        // Mark as requested (even if Apple doesn't show it)
        UserDefaults.standard.set(true, forKey: hasRequestedFirstMonthReviewKey)
        
        // Small delay to let the celebration moment land
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.requestReview()
        }
    }
    
    private func requestReview() {
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            
            // Request review through Apple's API
            // Apple throttles this automatically (max 3 per year per user)
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
