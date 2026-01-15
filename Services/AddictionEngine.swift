import SwiftUI
import AVFoundation
import Combine

// MARK: - Addiction Engine
// Psychological triggers to make the app satisfying and habit-forming

class AddictionEngine: ObservableObject {
    static let shared = AddictionEngine()
    
    // MARK: - State
    @Published var isOnFire = false
    @Published var fireStreak = 0
    @Published var sessionDeleteCount = 0
    @Published var sessionStorageFreed: Double = 0 // MB
    @Published var showMilestone = false
    @Published var milestoneType: MilestoneType?
    @Published var encouragementMessage: String?
    
    // Speed tracking
    private var lastSwipeTime: Date?
    private var swipeTimes: [Date] = []
    private let fireThreshold: TimeInterval = 0.8 // Swipes faster than this = on fire
    private let fireStreakRequired = 3
    
    // Sound effects
    private var swipeSound: AVAudioPlayer?
    private var fireSound: AVAudioPlayer?
    private var milestoneSound: AVAudioPlayer?
    var soundEnabled = true
    
    private init() {
        setupSounds()
    }
    
    // MARK: - Swipe Tracking
    
    func recordSwipe(isDelete: Bool) {
        let now = Date()
        
        // Track speed
        if let last = lastSwipeTime {
            let interval = now.timeIntervalSince(last)
            swipeTimes.append(now)
            
            // Keep only recent swipes
            swipeTimes = swipeTimes.filter { now.timeIntervalSince($0) < 5 }
            
            // Check if on fire (fast swiping)
            if interval < fireThreshold {
                fireStreak += 1
                if fireStreak >= fireStreakRequired && !isOnFire {
                    triggerFireMode()
                }
            } else {
                fireStreak = max(0, fireStreak - 1)
                if fireStreak < fireStreakRequired {
                    isOnFire = false
                }
            }
        }
        lastSwipeTime = now
        
        // Track deletes
        if isDelete {
            sessionDeleteCount += 1
            sessionStorageFreed += estimatePhotoSize()
            
            // Check milestones
            checkMilestones()
        }
        
        // Play swipe sound
        if soundEnabled {
            playSwipeSound()
        }
    }
    
    // MARK: - Fire Mode 🔥
    
    private func triggerFireMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isOnFire = true
        }
        HapticManager.shared.notification(.success)
        
        if soundEnabled {
            playFireSound()
        }
    }
    
    // MARK: - Milestones
    
    private func checkMilestones() {
        let milestones = [10, 25, 50, 100, 200, 500, 1000]
        
        for milestone in milestones {
            if sessionDeleteCount == milestone {
                triggerMilestone(count: milestone)
                break
            }
        }
        
        // Storage milestones (MB)
        let storageMilestones: [Double] = [50, 100, 250, 500, 1000]
        for mb in storageMilestones {
            if sessionStorageFreed >= mb && sessionStorageFreed < mb + 5 {
                triggerStorageMilestone(mb: mb)
                break
            }
        }
    }
    
    private func triggerMilestone(count: Int) {
        milestoneType = .deleteCount(count)
        withAnimation {
            showMilestone = true
        }
        HapticManager.shared.notification(.success)
        
        if soundEnabled {
            playMilestoneSound()
        }
        
        // Auto-hide after 2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showMilestone = false
            }
        }
    }
    
    private func triggerStorageMilestone(mb: Double) {
        milestoneType = .storageSaved(mb)
        withAnimation {
            showMilestone = true
        }
        HapticManager.shared.notification(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                self.showMilestone = false
            }
        }
    }
    
    // No encouragement messages - keep it clean
    
    // MARK: - Session Management
    
    func startSession() {
        sessionDeleteCount = 0
        sessionStorageFreed = 0
        fireStreak = 0
        isOnFire = false
        lastSwipeTime = nil
        swipeTimes = []
    }
    
    func endSession() -> SessionSummary {
        let summary = SessionSummary(
            deletedCount: sessionDeleteCount,
            storageFreed: sessionStorageFreed,
            wasOnFire: fireStreak >= fireStreakRequired,
            maxFireStreak: fireStreak
        )
        return summary
    }
    
    // MARK: - Helpers
    
    private func estimatePhotoSize() -> Double {
        // Random between 2-5 MB per photo (realistic average)
        return Double.random(in: 2...5)
    }
    
    var swipesPerMinute: Int {
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        return swipeTimes.filter { $0 > oneMinuteAgo }.count
    }
    
    // MARK: - Sound Effects
    
    private func setupSounds() {
        // We'll use system sounds for now
        // In production, add custom sound files
    }
    
    private func playSwipeSound() {
        // Light tap feedback serves as audio cue
        // Add custom sounds here if desired
    }
    
    private func playFireSound() {
        // Could add a satisfying "whoosh" sound
    }
    
    private func playMilestoneSound() {
        // Could add a celebration sound
    }
}

// MARK: - Data Types

struct SessionSummary {
    let deletedCount: Int
    let storageFreed: Double
    let wasOnFire: Bool
    let maxFireStreak: Int
}

enum MilestoneType {
    case deleteCount(Int)
    case storageSaved(Double)
    
    var title: String {
        switch self {
        case .deleteCount(let count):
            return "\(count) deleted"
        case .storageSaved(let mb):
            if mb >= 1000 {
                return "\(Int(mb/1000)) GB freed"
            }
            return "\(Int(mb)) MB freed"
        }
    }
}

// MARK: - Daily Goals

class DailyGoalTracker: ObservableObject {
    static let shared = DailyGoalTracker()
    
    private let defaults = UserDefaults.standard
    
    var dailyGoal: Int = 50
    @Published var todayProgress: Int = 0
    
    private var lastResetDate: Date? {
        get { defaults.object(forKey: "dailyGoal_lastReset") as? Date }
        set { defaults.set(newValue, forKey: "dailyGoal_lastReset") }
    }
    
    private init() {
        checkAndResetIfNewDay()
        todayProgress = defaults.integer(forKey: "dailyGoal_progress")
    }
    
    var progressPercent: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayProgress) / Double(dailyGoal))
    }
    
    var isGoalComplete: Bool {
        todayProgress >= dailyGoal
    }
    
    var remainingToday: Int {
        max(0, dailyGoal - todayProgress)
    }
    
    func addProgress(_ count: Int) {
        checkAndResetIfNewDay()
        todayProgress += count
        defaults.set(todayProgress, forKey: "dailyGoal_progress")
    }
    
    private func checkAndResetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastReset = lastResetDate {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            if today > lastResetDay {
                // New day - reset progress
                todayProgress = 0
                defaults.set(0, forKey: "dailyGoal_progress")
                lastResetDate = today
            }
        } else {
            lastResetDate = today
        }
    }
}

