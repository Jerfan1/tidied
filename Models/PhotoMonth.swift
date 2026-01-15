import Foundation
import Photos

struct PhotoMonth: Identifiable, Hashable {
    let id: String
    let month: Int
    let year: Int
    var totalCount: Int
    var reviewedCount: Int
    var assets: [PHAsset]
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let monthName = formatter.monthSymbols[month - 1]
        let shortYear = String(year).suffix(2)
        return "\(monthName.capitalized) '\(shortYear)"
    }
    
    var fullDisplayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return displayName
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(reviewedCount) / Double(totalCount)
    }
    
    var isCompleted: Bool {
        totalCount > 0 && reviewedCount >= totalCount
    }
    
    var remainingCount: Int {
        max(0, totalCount - reviewedCount)
    }
    
    init(month: Int, year: Int, assets: [PHAsset] = []) {
        self.id = "\(year)-\(month)"
        self.month = month
        self.year = year
        self.totalCount = assets.count
        self.reviewedCount = 0
        self.assets = assets
    }
}

// Service to organize photos by month
class PhotoMonthService {
    static let shared = PhotoMonthService()
    private let photoService = PhotoLibraryService.shared
    
    private init() {}
    
    func fetchMonths() -> [PhotoMonth] {
        let fetchResult = photoService.fetchAllMedia()
        var monthsDict: [String: [PHAsset]] = [:]
        
        fetchResult.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            let calendar = Calendar.current
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            let key = "\(year)-\(month)"
            
            if monthsDict[key] == nil {
                monthsDict[key] = []
            }
            monthsDict[key]?.append(asset)
        }
        
        // Convert to PhotoMonth objects and sort oldest first
        var months: [PhotoMonth] = []
        for (key, assets) in monthsDict {
            let parts = key.split(separator: "-")
            if parts.count == 2,
               let year = Int(parts[0]),
               let month = Int(parts[1]) {
                var photoMonth = PhotoMonth(month: month, year: year, assets: assets)
                // Load saved progress
                photoMonth.reviewedCount = getReviewedCount(for: key)
                months.append(photoMonth)
            }
        }
        
        // Sort by date (oldest first)
        return months.sorted { 
            if $0.year != $1.year {
                return $0.year < $1.year
            }
            return $0.month < $1.month
        }
    }
    
    // MARK: - Progress Persistence
    
    private func getReviewedCount(for monthKey: String) -> Int {
        UserDefaults.standard.integer(forKey: "month_progress_\(monthKey)")
    }
    
    func saveProgress(for month: PhotoMonth) {
        UserDefaults.standard.set(month.reviewedCount, forKey: "month_progress_\(month.id)")
    }
    
    func markMonthCompleted(_ month: PhotoMonth) {
        UserDefaults.standard.set(month.totalCount, forKey: "month_progress_\(month.id)")
        // Clear the current position since it's done
        UserDefaults.standard.removeObject(forKey: "month_position_\(month.id)")
    }
    
    func getCompletedMonthsCount() -> Int {
        let months = fetchMonths()
        return months.filter { $0.isCompleted }.count
    }
    
    // MARK: - Position Tracking (for resuming halfway)
    
    func saveCurrentPosition(for month: PhotoMonth, index: Int) {
        // Save position for resuming
        UserDefaults.standard.set(index, forKey: "month_position_\(month.id)")
        // Also update progress so the ring on home screen updates
        UserDefaults.standard.set(index, forKey: "month_progress_\(month.id)")
    }
    
    func getSavedPosition(for month: PhotoMonth) -> Int {
        return UserDefaults.standard.integer(forKey: "month_position_\(month.id)")
    }
    
    // MARK: - Bulk Operations (for returning users)
    
    func markMonthsCompletedBefore(year: Int, month: Int = 1) {
        let allMonths = fetchMonths()
        for m in allMonths {
            // Mark complete if before the target year, OR same year but earlier month
            if m.year < year || (m.year == year && m.month < month) {
                markMonthCompleted(m)
            }
        }
    }
    
    // MARK: - Pending Actions Persistence
    
    func savePendingActions(_ actions: [SwipeAction], for month: PhotoMonth) {
        let savedActions = actions.map { SavedSwipeAction(from: $0) }
        if let data = try? JSONEncoder().encode(savedActions) {
            UserDefaults.standard.set(data, forKey: "month_actions_\(month.id)")
        }
    }
    
    func loadPendingActions(for month: PhotoMonth) -> [SwipeAction] {
        guard let data = UserDefaults.standard.data(forKey: "month_actions_\(month.id)"),
              let savedActions = try? JSONDecoder().decode([SavedSwipeAction].self, from: data) else {
            return []
        }
        return savedActions.compactMap { $0.toSwipeAction(assets: month.assets) }
    }
    
    func clearPendingActions(for month: PhotoMonth) {
        UserDefaults.standard.removeObject(forKey: "month_actions_\(month.id)")
    }
}

