import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitManager.shared
    @State private var showPaywall = false
    private let stats = StatsService.shared
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    // Header
                    header
                        .padding(.top, Spacing.lg)
                    
                    // Main Stats
                    mainStatsCard
                    
                    // Streak Card
                    streakCard
                    
                    // Achievements
                    achievementsSection
                    
                    // Upgrade card (only show if not Pro)
                    if !store.isPro {
                        upgradeCard
                    }
                    
                    // Privacy section
                    privacySection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    private var upgradeCard: some View {
        Button(action: { showPaywall = true }) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.roseLight)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.rose)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock tidied")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Unlimited months • Support indie dev")
                        .font(.labelSmall)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.rose.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var header: some View {
        VStack(spacing: Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.sageLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.sage)
            }
            
            VStack(spacing: Spacing.xs) {
                Text("Your Stats")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Level \(calculateLevel())")
                    .font(.labelMedium)
                    .foregroundColor(.sage)
            }
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Privacy First")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                PrivacyRow(icon: "lock.shield.fill", title: "100% Private", description: "Your photos never leave your device. Zero data collection.")
                
                PrivacyRow(icon: "chevron.left.forwardslash.chevron.right", title: "Open Source", description: "Our code is public. See exactly what we do with your photos.")
                
                PrivacyRow(icon: "xmark.icloud.fill", title: "No Cloud", description: "No servers, no uploads, no AI training on your images.")
            }
            
            // Links
            HStack(spacing: Spacing.lg) {
                Button(action: openGitHub) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 12))
                        Text("Source")
                            .font(.labelMedium)
                    }
                    .foregroundColor(.sage)
                }
                
                Button(action: openSupport) {
                    HStack(spacing: 4) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 12))
                        Text("Support")
                            .font(.labelMedium)
                    }
                    .foregroundColor(.sage)
                }
            }
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com/Jerfan1/tidied") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupport() {
        if let url = URL(string: "mailto:support@jerfan.co.uk") {
            UIApplication.shared.open(url)
        }
    }
    
    private var mainStatsCard: some View {
        HStack(spacing: 0) {
            ProfileStatItem(
                value: "\(stats.totalReviewed)",
                label: "Reviewed",
                icon: "eye"
            )
            
            Rectangle()
                .fill(Color.divider)
                .frame(width: 1, height: 40)
            
            ProfileStatItem(
                value: "\(stats.totalDeleted)",
                label: "Deleted",
                icon: "trash"
            )
            
            Rectangle()
                .fill(Color.divider)
                .frame(width: 1, height: 40)
            
            ProfileStatItem(
                value: stats.storageFreedFormatted,
                label: "Freed",
                icon: "arrow.up"
            )
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    private var streakCard: some View {
        HStack(spacing: 0) {
            // Current Streak
            VStack(spacing: Spacing.sm) {
                Text("\(stats.currentStreak)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.clay)
                Text("day streak")
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.divider)
                .frame(width: 1, height: 40)
            
            // Best Streak
            VStack(spacing: Spacing.sm) {
                Text("\(stats.bestStreak)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.sage)
                Text("best streak")
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.divider)
                .frame(width: 1, height: 40)
            
            // Sessions
            VStack(spacing: Spacing.sm) {
                Text("\(stats.sessionsCompleted)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("sessions")
                    .font(.labelSmall)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Achievements")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(stats.unlockedAchievements().count)/\(Achievement.allCases.count)")
                    .font(.labelMedium)
                    .foregroundColor(.textTertiary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                ForEach(Achievement.allCases, id: \.self) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        isUnlocked: stats.unlockedAchievements().contains(achievement)
                    )
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    private func calculateLevel() -> Int {
        let points = stats.totalReviewed + (stats.totalDeleted * 2) + Int(stats.storageFreedMB / 10)
        return max(1, points / 50 + 1)
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.sage)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.labelSmall)
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.sageLight : Color.divider)
                    .frame(width: 44, height: 44)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isUnlocked ? .sage : .textTertiary)
            }
            
            Text(achievement.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isUnlocked ? .textSecondary : .textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.sage)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
