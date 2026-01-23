import SwiftUI

struct ReturningUserView: View {
    let onStartFresh: () -> Void
    let onStartFrom: (Int, Int) -> Void  // year, month
    
    @State private var animateIn = false
    @State private var showDatePicker = false  // Yes/No gate
    @State private var selectedYear: Int?
    @State private var selectedMonth: Int?
    @State private var showMonthPicker = false
    
    // Generate years from 2010 to current year
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((2010...currentYear).reversed())
    }
    
    private let months = [
        (1, "Jan"), (2, "Feb"), (3, "Mar"), (4, "Apr"),
        (5, "May"), (6, "Jun"), (7, "Jul"), (8, "Aug"),
        (9, "Sep"), (10, "Oct"), (11, "Nov"), (12, "Dec")
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if !showDatePicker {
                // Step 1: Yes/No question
                yesNoQuestion
            } else {
                // Step 2: Date picker (only if they said Yes)
                datePickerView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Yes/No Question (First screen)
    
    private var yesNoQuestion: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.roseLight)
                    .frame(width: 90, height: 90)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.rose)
            }
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            
            // Question
            VStack(spacing: Spacing.sm) {
                Text("One quick question")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Have you cleaned your camera roll with another app before?")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            .opacity(animateIn ? 1 : 0)
            
            Spacer()
            
            // Yes/No buttons
            VStack(spacing: Spacing.md) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDatePicker = true
                    }
                }) {
                    Text("Yes, skip what I've done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.rose)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.roseLight)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)
                
                Button(action: onStartFresh) {
                    Text("No, start fresh")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rose)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)
            }
            .opacity(animateIn ? 1 : 0)
            
            Spacer().frame(height: Spacing.xxl)
        }
    }
    
    // MARK: - Date Picker (Second screen, only if Yes)
    
    private var datePickerView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.roseLight)
                    .frame(width: 90, height: 90)
                
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.rose)
            }
            
            // Title
            VStack(spacing: Spacing.sm) {
                Text("Where did you get up to?")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("We'll skip everything before this date.")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            if !showMonthPicker {
                // Year selector
                yearSelector
            } else {
                // Month selector (after year is picked)
                monthSelector
            }
            
            Spacer()
            
            // Actions
            actionButtons
            
            Spacer().frame(height: Spacing.lg)
        }
    }
    
    private var yearSelector: some View {
        VStack(spacing: Spacing.md) {
            Text("Select year:")
                .font(.labelMedium)
                .foregroundColor(.textTertiary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableYears, id: \.self) { year in
                        Button(action: { selectedYear = year }) {
                            Text(String(year))
                                .font(.system(size: 15, weight: selectedYear == year ? .bold : .medium))
                                .foregroundColor(selectedYear == year ? .white : .textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedYear == year ? Color.rose : Color.roseLight)
                                )
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
    
    private var monthSelector: some View {
        VStack(spacing: Spacing.md) {
            if let year = selectedYear {
                Text("Which month in \(String(year))?")
                    .font(.labelMedium)
                    .foregroundColor(.textTertiary)
            }
            
            // Month grid (3x4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(months, id: \.0) { month, name in
                    Button(action: { selectedMonth = month }) {
                        Text(name)
                            .font(.system(size: 14, weight: selectedMonth == month ? .bold : .medium))
                            .foregroundColor(selectedMonth == month ? .white : .textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedMonth == month ? Color.rose : Color.roseLight)
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            if let year = selectedYear {
                if !showMonthPicker {
                    // Show options after year selected
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMonthPicker = true
                        }
                    }) {
                        Text("Pick a specific month")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.rose)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    Button(action: { onStartFrom(year, 1) }) {
                        Text("Start of \(String(year))")
                            .font(.labelLarge)
                            .foregroundColor(.rose)
                            .padding(.vertical, 12)
                    }
                } else if let month = selectedMonth {
                    // Month selected - confirm
                    let monthName = months.first { $0.0 == month }?.1 ?? ""
                    Button(action: { onStartFrom(year, month) }) {
                        Text("Start from \(monthName) \(String(year))")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.rose)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
            
            // Back button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if showMonthPicker {
                        showMonthPicker = false
                        selectedMonth = nil
                    } else {
                        showDatePicker = false
                        selectedYear = nil
                    }
                }
            }) {
                Text("Back")
                    .font(.labelLarge)
                    .foregroundColor(.textSecondary)
                    .padding(.vertical, 12)
            }
        }
    }
}

