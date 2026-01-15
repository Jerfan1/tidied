import SwiftUI

// MARK: - Fire Mode Indicator
// Shows when user is swiping fast

struct FireIndicator: View {
    let isActive: Bool
    
    var body: some View {
        if isActive {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("on fire")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Milestone Toast
// Clean popup when hitting milestones

struct MilestoneToast: View {
    let milestone: MilestoneType
    
    var body: some View {
        VStack(spacing: 4) {
            Text(milestone.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Live Storage Counter
// Shows real-time storage freed during session

struct LiveStorageCounter: View {
    let megabytesFreed: Double
    
    private var formattedStorage: String {
        if megabytesFreed >= 1000 {
            return String(format: "%.1f GB", megabytesFreed / 1000)
        } else if megabytesFreed >= 1 {
            return String(format: "%.0f MB", megabytesFreed)
        } else {
            return "0 MB"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up")
                .font(.system(size: 10, weight: .semibold))
            Text(formattedStorage)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundColor(.keepGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.keepGreen.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Daily Goal Progress
// Clean progress indicator for daily goal

struct DailyGoalBar: View {
    let progress: Double // 0-1
    let remaining: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textTertiary)
                Spacer()
                Text("\(remaining) left")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.divider)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progress >= 1 ? Color.keepGreen : Color.rose)
                        .frame(width: geo.size.width * min(progress, 1), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Speed Indicator
// Shows swipes per minute

struct SpeedIndicator: View {
    let swipesPerMinute: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(swipesPerMinute)")
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
            Text("/min")
                .font(.system(size: 10))
        }
        .foregroundColor(.textSecondary)
    }
}

// MARK: - "One More" Prompt
// Suggests continuing after completing a month

struct OneMorePrompt: View {
    let nextMonthName: String
    let onContinue: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Keep going?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("\(nextMonthName) is next")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 12) {
                Button(action: onDone) {
                    Text("I'm done")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.divider)
                        .clipShape(Capsule())
                }
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.rose)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
        )
    }
}

// MARK: - Streak Warning
// Shows when streak is at risk

struct StreakWarning: View {
    let currentStreak: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentStreak) day streak")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("clean today to keep it")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

