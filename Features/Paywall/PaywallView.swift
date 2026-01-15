import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitManager.shared
    
    // Read directly from UserDefaults to avoid SwiftUI timing issues
    private var completedMonthName: String? {
        UserDefaults.standard.string(forKey: "tidied_last_completed_month")
    }
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Color.divider)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    
                    // Header
                    VStack(spacing: Spacing.md) {
                        // Only show checkmark icon when they completed a month
                        if let monthName = completedMonthName, !monthName.isEmpty {
                            ZStack {
                                Circle()
                                    .fill(Color.keepGreen.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.keepGreen)
                            }
                        }
                        
                        // Personalized message if they just completed a month
                        if let monthName = completedMonthName, !monthName.isEmpty {
                            Text("You cleaned \(monthName). Nice.")
                                .font(.titleMedium)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock tidied to keep going.")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                        } else {
                            Text("Unlock tidied")
                                .font(.titleLarge)
                                .foregroundColor(.textPrimary)
                            
                            Text("Clean your entire camera roll")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.top, Spacing.lg)
                    
                    // Features
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        PaywallFeatureRow(icon: "infinity", text: "Unlimited months")
                        PaywallFeatureRow(icon: "lock.shield.fill", text: "Support privacy-first apps")
                        PaywallFeatureRow(icon: "heart.fill", text: "Fund open source development")
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.lg)
                    
                    // Products
                    if store.isLoading {
                        ProgressView()
                            .tint(.rose)
                            .padding()
                    } else {
                        VStack(spacing: Spacing.sm) {
                            ForEach(store.products, id: \.id) { product in
                                ProductCard(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    
                    // Purchase button
                    Button(action: purchase) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProduct != nil ? Color.rose : Color.rose.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    
                    // Restore & Terms
                    VStack(spacing: Spacing.sm) {
                        Button(action: restore) {
                            Text("Restore Purchases")
                                .font(.labelMedium)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text("Cancel anytime • Secure payment via Apple")
                            .font(.labelSmall)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Pre-select lifetime as best value
            if let lifetime = store.products.first(where: { $0.id == "tidied.lifetime" }) {
                selectedProduct = lifetime
            } else {
                selectedProduct = store.products.first
            }
        }
    }
    
    private func purchase() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        Task {
            do {
                let success = try await store.purchase(product)
                if success {
                    dismiss()
                }
            } catch {
                errorMessage = "Purchase failed. Please try again."
                showError = true
            }
            isPurchasing = false
        }
    }
    
    private func restore() {
        Task {
            await store.restorePurchases()
            if store.isPro {
                dismiss()
            }
        }
    }
}

// MARK: - Components

struct PaywallFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.rose)
                .frame(width: 24)
            
            Text(text)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.emoji)
                        Text(product.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        if product.id == "tidied.lifetime" {
                            Text("BEST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.rose)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(product.subtitle)
                        .font(.labelSmall)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.rose : Color.divider, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.rose)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.rose : Color.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView()
}
