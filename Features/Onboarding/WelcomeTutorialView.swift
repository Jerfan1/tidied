import SwiftUI

struct WelcomeTutorialView: View {
    let onContinue: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Privacy badge - prominent and reassuring
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                    Text("100% Private")
                        .font(.system(size: 14, weight: .semibold))
                    Text("•")
                        .font(.system(size: 12))
                    Text("Photos never leave your device")
                        .font(.system(size: 14))
                }
                .foregroundColor(.sage)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.sageLight)
                )
                .opacity(animateIn ? 1 : 0)
                
                // Title
                VStack(spacing: Spacing.sm) {
                    Text("How It Works")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text("Clean up your photos, month by month")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                
                Spacer().frame(height: Spacing.lg)
                
                // Swipe instruction
                VStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xl) {
                        // Left = Delete
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.rose)
                            Text("Delete")
                                .font(.labelMedium)
                                .foregroundColor(.rose)
                        }
                        
                        // Swipe visual
                        Image(systemName: "hand.draw")
                            .font(.system(size: 40))
                            .foregroundColor(.textTertiary)
                        
                        // Right = Keep
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.keepGreen)
                            Text("Keep")
                                .font(.labelMedium)
                                .foregroundColor(.keepGreen)
                        }
                    }
                    
                    Text("Swipe like Tinder")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                .padding(.vertical, Spacing.lg)
                .padding(.horizontal, Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                
                Spacer().frame(height: Spacing.lg)
                
                // Tile examples
                VStack(spacing: Spacing.md) {
                    Text("Your months")
                        .font(.labelMedium)
                        .foregroundColor(.textTertiary)
                    
                    HStack(spacing: Spacing.lg) {
                        // Incomplete tile
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "F4D06F").opacity(0.3), lineWidth: 3)
                                    .frame(width: 50, height: 50)
                                
                                // Partial progress
                                Circle()
                                    .trim(from: 0, to: 0.3)
                                    .stroke(Color(hex: "F4D06F"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(-90))
                                
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "F4D06F"))
                            }
                            
                            Text("JUL '24")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text("In progress")
                                .font(.system(size: 9))
                                .foregroundColor(.textTertiary)
                        }
                        
                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16))
                            .foregroundColor(.textTertiary)
                        
                        // Complete tile
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.keepGreen)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("JUN '24")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.keepGreen)
                            
                            Text("Done!")
                                .font(.system(size: 9))
                                .foregroundColor(.keepGreen)
                        }
                    }
                }
                .padding(.vertical, Spacing.lg)
                .padding(.horizontal, Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                )
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rose)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, Spacing.lg)
                .opacity(animateIn ? 1 : 0)
                
                Spacer().frame(height: Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
}


