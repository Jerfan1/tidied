import SwiftUI

struct MonthSelectorView: View {
    @State private var months: [PhotoMonth] = []
    @State private var isLoading = true
    @State private var selectedMonth: PhotoMonth?
    @State private var showingProfile = false
    @State private var animateIn = false
    
    private let monthService = PhotoMonthService.shared
    private let stats = StatsService.shared
    
    // Grid layout - 2 columns (bigger cards, less overwhelming)
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.rose)
                    Spacer()
                } else {
                    // Month grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(months.enumerated()), id: \.element.id) { index, month in
                                MonthCard(month: month) {
                                    print("📱 Tapped: \(month.displayName) with \(month.assets.count) assets")
                                    selectedMonth = month
                                    print("📱 selectedMonth set to: \(month.displayName)")
                                }
                                .opacity(animateIn ? 1 : 0)
                                .scaleEffect(animateIn ? 1 : 0.95)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.015),
                                    value: animateIn
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
        }
        .onAppear {
            print("🟢🟢🟢 MONTH SELECTOR APPEARED 🟢🟢🟢")
            loadMonths()
        }
        .fullScreenCover(item: $selectedMonth) { month in
            MonthSwipeContainerView(month: month) {
                print("📱 MonthSwipeContainerView completed")
                loadMonths()
            }
            .onAppear {
                print("📱 MonthSwipeContainerView appeared for \(month.displayName)")
                print("📱 Assets count: \(month.assets.count)")
            }
        }
        .sheet(isPresented: $showingProfile) {
            NavigationStack { ProfileView() }
        }
    }
    
    private var header: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("tidied")
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10))
                        Text("private & open source")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.rose)
                }
                
                Spacer()
                
                Button(action: { showingProfile = true }) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.rose.opacity(0.6))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            
            // Simple progress indicator
            if !months.isEmpty && completedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.keepGreen)
                    Text("\(completedCount) done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    if stats.storageFreedMB > 0 {
                        Text("•")
                            .foregroundColor(.textTertiary)
                        Text(stats.storageFreedFormatted + " freed")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.rose)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.bottom, Spacing.sm)
    }
    
    private var completedCount: Int {
        months.filter { $0.isCompleted }.count
    }
    
    private var overallProgress: Double {
        guard !months.isEmpty else { return 0 }
        return Double(completedCount) / Double(months.count)
    }
    
    private func loadMonths() {
        Task {
            let fetchedMonths = monthService.fetchMonths()
            await MainActor.run {
                months = fetchedMonths
                isLoading = false
                withAnimation {
                    animateIn = true
                }
            }
        }
    }
}

// MARK: - Month Card (Clean with seasonal icons)
struct MonthCard: View {
    let month: PhotoMonth
    let onTap: () -> Void
    
    // Seasonal icon based on month
    private var seasonIcon: String {
        switch month.month {
        case 12, 1, 2: return "snowflake"      // Winter
        case 3, 4, 5: return "leaf.fill"        // Spring
        case 6, 7, 8: return "sun.max.fill"     // Summer
        case 9, 10, 11: return "leaf.fill"      // Autumn
        default: return "circle"
        }
    }
    
    private var seasonColor: Color {
        switch month.month {
        case 12, 1, 2: return Color(hex: "A8D5E5")  // Winter blue
        case 3, 4, 5: return Color(hex: "B8D4A8")   // Spring green
        case 6, 7, 8: return Color(hex: "F4D06F")   // Summer yellow
        case 9, 10, 11: return Color(hex: "D4A574") // Autumn orange
        default: return .rose
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Status circle with seasonal icon
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(month.isCompleted ? Color.keepGreen.opacity(0.3) : seasonColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 64, height: 64)
                    
                    // Progress arc (only if started but not complete)
                    if month.progress > 0 && !month.isCompleted {
                        Circle()
                            .trim(from: 0, to: month.progress)
                            .stroke(seasonColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // Center content
                    if month.isCompleted {
                        // Completed - filled green circle with check
                        Circle()
                            .fill(Color.keepGreen)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        // Seasonal icon
                        Image(systemName: seasonIcon)
                            .font(.system(size: 22))
                            .foregroundColor(seasonColor)
                    }
                }
                
                // Month name
                Text(month.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(month.isCompleted ? .keepGreen : .textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(month.isCompleted ? Color.keepGreen.opacity(0.08) : Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(
                        month.isCompleted ? Color.keepGreen.opacity(0.3) : Color.divider,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

// Custom button style for subtle press effect
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Container for month-specific swiping
struct MonthSwipeContainerView: View {
    let month: PhotoMonth
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingProfile = false
    
    var body: some View {
        MonthSwipeView(
            month: month,
            onDismiss: {
                onComplete()
                dismiss()
            },
            onProfile: { showingProfile = true }
        )
        .sheet(isPresented: $showingProfile) {
            NavigationStack { ProfileView() }
        }
    }
}

