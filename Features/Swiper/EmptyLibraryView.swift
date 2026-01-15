import SwiftUI
import PhotosUI

struct EmptyLibraryView: View {
    let onOpenSettings: () -> Void
    let onSelectPhotos: () -> Void
    let onRetry: () -> Void
    let isLimitedAccess: Bool
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blush.opacity(0.5))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 38, weight: .light))
                        .foregroundColor(.clay)
                }
                .scaleEffect(animateIn ? 1 : 0.8)
                .opacity(animateIn ? 1 : 0)
                
                // Title
                VStack(spacing: Spacing.sm) {
                    Text("no photos found")
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                    
                    Text(isLimitedAccess ?
                        "Select more photos or grant full access to see your library." :
                        "Make sure you've granted photo library access."
                    )
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Spacing.xl)
                }
                .opacity(animateIn ? 1 : 0)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Spacing.md) {
                    if isLimitedAccess {
                        Button(action: onSelectPhotos) {
                            Text("Select Photos")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.sage)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    
                    Button(action: onOpenSettings) {
                        Text(isLimitedAccess ? "Grant Full Access" : "Open Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.divider)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .padding(.horizontal, Spacing.lg)
                    
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.labelLarge)
                            .foregroundColor(.textTertiary)
                            .padding(.vertical, 12)
                    }
                }
                .opacity(animateIn ? 1 : 0)
                
                Spacer()
                    .frame(height: Spacing.xxl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
}
