import SwiftUI

// MARK: - App Icon Preview
// Run this preview and screenshot to create the app icon

struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("App Icon Options")
                .font(.title2.bold())
            
            HStack(spacing: 30) {
                VStack {
                    AppIconOption1()
                        .frame(width: 200, height: 200)
                    Text("Clean T")
                        .font(.caption)
                }
                
                VStack {
                    AppIconOption2()
                        .frame(width: 200, height: 200)
                    Text("Stacked Cards")
                        .font(.caption)
                }
                
                VStack {
                    AppIconOption3()
                        .frame(width: 200, height: 200)
                    Text("Checkmark")
                        .font(.caption)
                }
            }
            
            HStack(spacing: 30) {
                VStack {
                    AppIconOption4()
                        .frame(width: 200, height: 200)
                    Text("Swipe Motion")
                        .font(.caption)
                }
                
                VStack {
                    AppIconOption5()
                        .frame(width: 200, height: 200)
                    Text("Photo Frame")
                        .font(.caption)
                }
                
                VStack {
                    AppIconOption6()
                        .frame(width: 200, height: 200)
                    Text("Minimal")
                        .font(.caption)
                }
            }
        }
        .padding(40)
        .background(Color.white)
    }
}

// MARK: - Option 1: Clean "T" (for Tidy)
struct AppIconOption1: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "D4A5A5"), Color(hex: "B8878B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Elegant T
            Text("t")
                .font(.system(size: 120, weight: .light, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Option 2: Stacked Cards
struct AppIconOption2: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "EDD9D9"), Color(hex: "D4A5A5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Back card (keep - green tint)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 80, height: 100)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 4, y: 4)
                .rotationEffect(.degrees(12))
                .offset(x: 20, y: -5)
            
            // Front card (being swiped)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 80, height: 100)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .rotationEffect(.degrees(-8))
                .offset(x: -15, y: 5)
            
            // Small checkmark on front card
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "7EAB8E"))
                .offset(x: -15, y: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Option 3: Simple Checkmark
struct AppIconOption3: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "D4A5A5"), Color(hex: "C29090")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Checkmark circle
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 100, height: 100)
            
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Option 4: Swipe Motion
struct AppIconOption4: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "D4A5A5"), Color(hex: "B8878B")],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Motion lines
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3 - Double(i) * 0.08))
                    .frame(width: 50 - CGFloat(i * 10), height: 4)
                    .offset(x: CGFloat(-30 + i * 15), y: CGFloat(i * 12 - 12))
            }
            
            // Card
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 70, height: 90)
                .shadow(color: Color.black.opacity(0.15), radius: 8)
                .rotationEffect(.degrees(-15))
                .offset(x: 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Option 5: Photo Frame
struct AppIconOption5: View {
    var body: some View {
        ZStack {
            // Background
            Color(hex: "D4A5A5")
            
            // Photo frame
            ZStack {
                // Frame
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 90, height: 110)
                
                // "Photo" placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "EDD9D9"))
                    .frame(width: 70, height: 80)
                    .offset(y: -5)
                
                // Checkmark badge
                Circle()
                    .fill(Color(hex: "7EAB8E"))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 35, y: -45)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - Option 6: Minimal Abstract
struct AppIconOption6: View {
    var body: some View {
        ZStack {
            // Background
            Color(hex: "FBF8F8")
            
            // Abstract shapes
            Circle()
                .fill(Color(hex: "D4A5A5"))
                .frame(width: 100, height: 100)
                .offset(x: -20, y: 20)
            
            Circle()
                .fill(Color(hex: "EDD9D9"))
                .frame(width: 80, height: 80)
                .offset(x: 30, y: -30)
            
            // Small accent
            Circle()
                .fill(Color(hex: "7EAB8E"))
                .frame(width: 30, height: 30)
                .offset(x: 40, y: 30)
        }
        .clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// MARK: - 1024x1024 Export View
// Use this for the actual icon export
struct AppIconExport: View {
    var body: some View {
        AppIconOption2() // Change this to whichever option you prefer
            .frame(width: 1024, height: 1024)
    }
}

#Preview("Icon Options") {
    AppIconPreview()
}

#Preview("Export Size") {
    AppIconExport()
        .previewLayout(.fixed(width: 1024, height: 1024))
}

