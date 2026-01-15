import SwiftUI

struct HomeView: View {
    @State private var showingSwipeView = false
    @State private var showingProfile = false
    @State private var animateIn = false
    
    private let stats = StatsService.shared
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar - minimal
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("tidy")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 8))
                            Text("private & open source")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.sage)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                
                Spacer()
                
                // Main content - elegant and minimal
                VStack(spacing: Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.sageLight)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "photo.stack")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(.sageDark)
                    }
                    .scaleEffect(animateIn ? 1 : 0.9)
                    .opacity(animateIn ? 1 : 0)
                    
                    VStack(spacing: Spacing.sm) {
                        Text("Clean your")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                        Text("camera roll")
                            .font(.titleLarge)
                            .foregroundColor(.sage)
                    }
                    .opacity(animateIn ? 1 : 0)
                    
                    Text("Swipe left to delete, right to keep.")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .opacity(animateIn ? 1 : 0)
                    
                    // Stats (if any)
                    if stats.totalReviewed > 0 {
                        HStack(spacing: Spacing.lg) {
                            StatItem(value: "\(stats.totalDeleted)", label: "deleted")
                            
                            Rectangle()
                                .fill(Color.divider)
                                .frame(width: 1, height: 30)
                            
                            StatItem(value: stats.storageFreedFormatted, label: "freed")
                            
                            if stats.currentStreak > 0 {
                                Rectangle()
                                    .fill(Color.divider)
                                    .frame(width: 1, height: 30)
                                
                                StatItem(value: "\(stats.currentStreak)", label: "day streak")
                            }
                        }
                        .padding(.top, Spacing.md)
                        .opacity(animateIn ? 1 : 0)
                    }
                }
                
                Spacer()
                
                // Start button - elegant
                VStack(spacing: Spacing.md) {
                    Button(action: { showingSwipeView = true }) {
                        Text("Start Swiping")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.sage)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)
                    .opacity(animateIn ? 1 : 0)
                    
                    Text("takes less than a minute")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
        .fullScreenCover(isPresented: $showingSwipeView) {
            SwipeContainerView()
        }
        .sheet(isPresented: $showingProfile) {
            NavigationStack { ProfileView() }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.labelSmall)
                .foregroundColor(.textTertiary)
        }
    }
}

struct SwipeContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingProfile = false
    
    var body: some View {
        SwipeView(onDismiss: { dismiss() }, onProfile: { showingProfile = true })
            .sheet(isPresented: $showingProfile) {
                NavigationStack { ProfileView() }
            }
    }
}
