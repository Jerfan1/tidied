import SwiftUI

struct PermissionRequestView: View {
    let onRequestAccess: () async -> Void
    let onOpenSettings: () -> Void
    let isDenied: Bool

    @State private var isRequesting = false
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: Spacing.xxl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.sageLight)
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: isDenied ? "lock.fill" : "photo.stack")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.sage)
                }
                .scaleEffect(animateIn ? 1 : 0.8)
                .opacity(animateIn ? 1 : 0)

                // Text content
                VStack(spacing: Spacing.md) {
                    Text(isDenied ? "Permission Needed" : "Access Your Photos")
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(isDenied ?
                        "Enable photo library access in Settings to clean up your camera roll." :
                        "Swipe through your photos. Keep what you love, delete the rest."
                    )
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Spacing.md)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 15)
                
                // Features list
                if !isDenied {
                    VStack(spacing: Spacing.md) {
                        FeatureRow(icon: "hand.draw", text: "Swipe right to keep, left to delete")
                        FeatureRow(icon: "checkmark.shield", text: "You approve all deletions")
                        FeatureRow(icon: "person.slash", text: "No account required")
                        
                        // Privacy row - highlighted
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.sage)
                                .frame(width: 36, height: 36)
                                .background(Color.sage.opacity(0.2))
                                .clipShape(Circle())
                            
                            Text("Only you see your photos")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.sage)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                }

                Spacer()

                // Action Button
                VStack(spacing: Spacing.md) {
                    Button(action: {
                        if isDenied {
                            onOpenSettings()
                        } else {
                            isRequesting = true
                            Task {
                                await onRequestAccess()
                                isRequesting = false
                            }
                        }
                    }) {
                        HStack(spacing: Spacing.sm) {
                            if isRequesting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isDenied ? "Open Settings" : "Get Started")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.sage)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .disabled(isRequesting)
                    .padding(.horizontal, Spacing.lg)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12))
                        Text("Your photos never leave your device")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.sage)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 25)

                Spacer()
                    .frame(height: Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.sage)
                .frame(width: 36, height: 36)
                .background(Color.sageLight)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}
