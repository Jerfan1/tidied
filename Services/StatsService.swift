import Foundation

class StatsService {
    static let shared = StatsService()
    
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let totalReviewed = "stats_totalReviewed"
        static let totalDeleted = "stats_totalDeleted"
        static let totalKept = "stats_totalKept"
        static let totalFavourited = "stats_totalFavourited"
        static let monthsCompleted = "stats_monthsCompleted"
        static let storageFreed = "stats_storageFreed"
        static let currentStreak = "stats_currentStreak"
        static let bestStreak = "stats_bestStreak"
        static let lastSessionDate = "stats_lastSessionDate"
        static let sessionsCompleted = "stats_sessionsCompleted"
    }
    
    private init() {}
    
    // MARK: - Stats Properties
    
    var totalReviewed: Int {
        get { userDefaults.integer(forKey: Keys.totalReviewed) }
        set { userDefaults.set(newValue, forKey: Keys.totalReviewed) }
    }
    
    var totalDeleted: Int {
        get { userDefaults.integer(forKey: Keys.totalDeleted) }
        set { userDefaults.set(newValue, forKey: Keys.totalDeleted) }
    }
    
    var totalKept: Int {
        get { userDefaults.integer(forKey: Keys.totalKept) }
        set { userDefaults.set(newValue, forKey: Keys.totalKept) }
    }
    
    var totalFavourited: Int {
        get { userDefaults.integer(forKey: Keys.totalFavourited) }
        set { userDefaults.set(newValue, forKey: Keys.totalFavourited) }
    }
    
    var monthsCompleted: Int {
        get { userDefaults.integer(forKey: Keys.monthsCompleted) }
        set { userDefaults.set(newValue, forKey: Keys.monthsCompleted) }
    }
    
    var storageFreedMB: Double {
        get { userDefaults.double(forKey: Keys.storageFreed) }
        set { userDefaults.set(newValue, forKey: Keys.storageFreed) }
    }
    
    var currentStreak: Int {
        get { userDefaults.integer(forKey: Keys.currentStreak) }
        set { userDefaults.set(newValue, forKey: Keys.currentStreak) }
    }
    
    var bestStreak: Int {
        get { userDefaults.integer(forKey: Keys.bestStreak) }
        set { userDefaults.set(newValue, forKey: Keys.bestStreak) }
    }
    
    var sessionsCompleted: Int {
        get { userDefaults.integer(forKey: Keys.sessionsCompleted) }
        set { userDefaults.set(newValue, forKey: Keys.sessionsCompleted) }
    }
    
    var lastSessionDate: Date? {
        get { userDefaults.object(forKey: Keys.lastSessionDate) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.lastSessionDate) }
    }
    
    // MARK: - Computed Stats
    
    var storageFreedFormatted: String {
        if storageFreedMB >= 1024 {
            return String(format: "%.1f GB", storageFreedMB / 1024)
        } else {
            return String(format: "%.0f MB", storageFreedMB)
        }
    }
    
    var deleteRatio: Double {
        guard totalReviewed > 0 else { return 0 }
        return Double(totalDeleted) / Double(totalReviewed) * 100
    }
    
    // MARK: - Actions
    
    func recordSwipe(kept: Bool) {
        totalReviewed += 1
        if kept {
            totalKept += 1
        } else {
            totalDeleted += 1
        }
    }
    
    func recordDeletion(count: Int, estimatedSizeMB: Double) {
        storageFreedMB += estimatedSizeMB
        updateStreak()
        sessionsCompleted += 1
    }
    
    func recordSession(deleted: Int, reviewed: Int, favourited: Int = 0) {
        totalReviewed += reviewed
        totalDeleted += deleted
        totalFavourited += favourited
        
        // Estimate ~3MB per photo
        let estimatedSize = Double(deleted) * 3.0
        storageFreedMB += estimatedSize
        
        updateStreak()
        sessionsCompleted += 1
    }
    
    func recordMonthCompleted() {
        monthsCompleted += 1
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = lastSessionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day - increase streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // Same day - don't change streak
        } else {
            currentStreak = 1
        }
        
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
        
        lastSessionDate = today
    }
    
    // MARK: - Achievements
    
    func unlockedAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Review milestones
        if totalReviewed >= 10 { achievements.append(.firstTen) }
        if totalReviewed >= 100 { achievements.append(.centurion) }
        if totalReviewed >= 500 { achievements.append(.halfK) }
        if totalReviewed >= 1000 { achievements.append(.thousandClub) }
        
        // Delete milestones
        if totalDeleted >= 50 { achievements.append(.cleanupCrew) }
        if totalDeleted >= 200 { achievements.append(.storageHero) }
        if totalDeleted >= 500 { achievements.append(.deleteMaster) }
        
        // Storage milestones
        if storageFreedMB >= 100 { achievements.append(.spaceSaver) }
        if storageFreedMB >= 1024 { achievements.append(.gigabyteFreedom) }
        
        // Streak milestones
        if bestStreak >= 3 { achievements.append(.onFire) }
        if bestStreak >= 7 { achievements.append(.weekWarrior) }
        
        // Favourite milestones
        if totalFavourited >= 25 { achievements.append(.favouriteFinder) }
        
        // Month milestones
        if monthsCompleted >= 1 { achievements.append(.monthOne) }
        if monthsCompleted >= 6 { achievements.append(.monthSix) }
        if monthsCompleted >= 12 { achievements.append(.monthTwelve) }
        
        return achievements
    }
}

enum Achievement: String, CaseIterable {
    case firstTen = "First Ten"
    case centurion = "Centurion"
    case halfK = "500 Club"
    case thousandClub = "1K Club"
    case cleanupCrew = "Cleanup Crew"
    case storageHero = "Storage Hero"
    case deleteMaster = "Delete Master"
    case spaceSaver = "Space Saver"
    case gigabyteFreedom = "GB Freedom"
    case onFire = "On Fire"
    case weekWarrior = "Week Warrior"
    case favouriteFinder = "Favourite Finder"
    case monthOne = "First Month"
    case monthSix = "Half Year"
    case monthTwelve = "Year Clean"
    
    var icon: String {
        switch self {
        case .firstTen: return "star"
        case .centurion: return "shield.fill"
        case .halfK: return "medal"
        case .thousandClub: return "crown"
        case .cleanupCrew: return "trash.fill"
        case .storageHero: return "externaldrive.fill"
        case .deleteMaster: return "flame.fill"
        case .spaceSaver: return "archivebox.fill"
        case .gigabyteFreedom: return "sparkles"
        case .onFire: return "flame"
        case .weekWarrior: return "calendar"
        case .favouriteFinder: return "heart.fill"
        case .monthOne: return "checkmark.circle"
        case .monthSix: return "6.circle.fill"
        case .monthTwelve: return "12.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .firstTen: return "Review 10 photos"
        case .centurion: return "Review 100 photos"
        case .halfK: return "Review 500 photos"
        case .thousandClub: return "Review 1,000 photos"
        case .cleanupCrew: return "Delete 50 photos"
        case .storageHero: return "Delete 200 photos"
        case .deleteMaster: return "Delete 500 photos"
        case .spaceSaver: return "Free 100 MB"
        case .gigabyteFreedom: return "Free 1 GB"
        case .onFire: return "3 day streak"
        case .weekWarrior: return "7 day streak"
        case .favouriteFinder: return "Favourite 25 photos"
        case .monthOne: return "Complete 1 month"
        case .monthSix: return "Complete 6 months"
        case .monthTwelve: return "Complete 12 months"
        }
    }
    
    var color: String {
        switch self {
        case .firstTen, .centurion: return "blue"
        case .halfK, .thousandClub: return "purple"
        case .cleanupCrew, .storageHero, .deleteMaster: return "red"
        case .spaceSaver, .gigabyteFreedom: return "green"
        case .onFire, .weekWarrior: return "orange"
        case .favouriteFinder: return "pink"
        case .monthOne, .monthSix, .monthTwelve: return "teal"
        }
    }
}


