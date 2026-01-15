import SwiftUI

struct DeletionSummaryView: View {
    let keptCount: Int
    let deleteCount: Int
    let onConfirmDelete: () async throws -> Void
    let onCancel: () -> Void

    @State private var isDeleting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var animateIn = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            if showSuccess {
                successView
                    .transition(.opacity.combined(with: .scale))
            } else {
                reviewView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }

    private var reviewView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.sageLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.sage)
            }
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)

            // Title
            VStack(spacing: Spacing.sm) {
                Text("success.")
                    .font(.titleLarge)
                    .foregroundColor(.sage)
                
                Text("all time, you've deleted")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
            }
            .opacity(animateIn ? 1 : 0)

            // Stats
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("\(deleteCount) images")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.deleteRed)
                    Text("to delete")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Text("\(keptCount) images")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.keepGreen)
                    Text("kept")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.vertical, Spacing.lg)
            .scaleEffect(animateIn ? 1 : 0.95)
            .opacity(animateIn ? 1 : 0)
            
            Text("that's a lot.")
                .font(.bodySmall)
                .foregroundColor(.textTertiary)

            Spacer()

            // Actions
            VStack(spacing: Spacing.md) {
                // Delete button
                if deleteCount > 0 {
                    Button(action: {
                        performDeletion()
                    }) {
                        HStack(spacing: Spacing.sm) {
                            if isDeleting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Confirm Delete")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.deleteRed)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .disabled(isDeleting)
                    .padding(.horizontal, Spacing.lg)
                }

                // Cancel button
                Button(action: onCancel) {
                    Text("Return Home")
                        .font(.labelLarge)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 14)
                }
                .disabled(isDeleting)
            }
            .opacity(animateIn ? 1 : 0)

            Spacer()
                .frame(height: Spacing.xxl)
        }
    }

    private var successView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(Color.sageLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.sage)
            }
            .scaleEffect(showSuccess ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccess)

            // Success message
            VStack(spacing: Spacing.md) {
                Text("all done.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)

                if deleteCount > 0 {
                    Text("\(deleteCount) item\(deleteCount == 1 ? "" : "s") removed")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                    
                    // Estimated space saved
                    Text("~\(deleteCount * 3) MB freed")
                        .font(.labelLarge)
                        .foregroundColor(.sage)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.sageLight)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
    }

    private func performDeletion() {
        isDeleting = true
        Task {
            do {
                try await onConfirmDelete()
                await MainActor.run {
                    isDeleting = false
                    showConfetti = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccess = true
                    }
                    HapticManager.shared.notification(.success)
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    showError = true
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
}

// Simple confetti effect with softer colors
struct ConfettiView: View {
    @State private var animate = false
    
    let colors: [Color] = [.sage, .sageLight, .blush, .clay, .keepGreen, .deleteRed]
    
    var body: some View {
        ZStack {
            ForEach(0..<40, id: \.self) { index in
                ConfettiPiece(color: colors[index % colors.count])
                    .offset(
                        x: CGFloat.random(in: -180...180),
                        y: animate ? 800 : -50
                    )
                    .animation(
                        .easeIn(duration: Double.random(in: 2...3.5))
                        .delay(Double.random(in: 0...0.4)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    @State private var rotation = Double.random(in: 0...360)
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation += 360
                }
            }
    }
}
