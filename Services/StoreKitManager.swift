import StoreKit
import SwiftUI
import Combine

/// Manages all in-app purchases using StoreKit 2
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Product IDs - must match App Store Connect exactly
    private let productIDs = [
        "tidied.monthly",
        "tidied.yearly", 
        "tidied.lifetime"
    ]
    
    // Published state
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    // Persistence key
    private let purchasedKey = "tidied_purchased"
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        // Load cached purchase state
        loadPurchaseState()
        
        // Fetch products
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Public API
    
    /// Check if user has any valid purchase (subscription or lifetime)
    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    /// Restore purchases
    func restorePurchases() async {
        await updatePurchasedProducts()
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction")
            }
        }
        
        await MainActor.run {
            self.purchasedProductIDs = purchased
            self.savePurchaseState()
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Local Persistence (backup)
    
    private func savePurchaseState() {
        UserDefaults.standard.set(isPro, forKey: purchasedKey)
    }
    
    private func loadPurchaseState() {
        // This is just a cache - actual state comes from StoreKit
        let cached = UserDefaults.standard.bool(forKey: purchasedKey)
        if cached {
            // Will be validated against StoreKit on next check
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}

// MARK: - Product Helpers

extension Product {
    var emoji: String {
        switch self.id {
        case "tidied.monthly": return "📅"
        case "tidied.yearly": return "📆"
        case "tidied.lifetime": return "♾️"
        default: return "✨"
        }
    }
    
    var displayName: String {
        switch self.id {
        case "tidied.monthly": return "Monthly"
        case "tidied.yearly": return "Yearly"
        case "tidied.lifetime": return "Lifetime"
        default: return self.displayName
        }
    }
    
    var subtitle: String {
        switch self.id {
        case "tidied.monthly": return "1 month, auto-renews"
        case "tidied.yearly": return "1 year, auto-renews"
        case "tidied.lifetime": return "One-time purchase"
        default: return ""
        }
    }
}
