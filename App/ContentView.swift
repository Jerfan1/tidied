import SwiftUI

struct ContentView: View {
    @State private var permissionStatus: PhotoLibraryService.PermissionStatus = .notDetermined
    @State private var isCheckingPermission = true
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
    @State private var showTutorial = false
    @State private var showReturningUser = false

    private let photoService = PhotoLibraryService.shared
    private let monthService = PhotoMonthService.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if isCheckingPermission {
                ProgressView()
                    .tint(.rose)
            } else {
                switch permissionStatus {
                case .authorized, .limited:
                    if !hasSeenTutorial && showTutorial {
                        // Step 1: Show tutorial first
                        WelcomeTutorialView(onContinue: {
                            UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
                            hasSeenTutorial = true
                            showTutorial = false
                            // Now show returning user screen
                            if !hasCompletedOnboarding {
                                showReturningUser = true
                            }
                        })
                    } else if !hasCompletedOnboarding && showReturningUser {
                        // Step 2: Ask if they used similar app before
                        ReturningUserView(
                            onStartFresh: {
                                completeOnboarding(startYear: nil, startMonth: nil)
                            },
                            onStartFrom: { year, month in
                                completeOnboarding(startYear: year, startMonth: month)
                            }
                        )
                    } else {
                        // Step 3: Main app
                        MonthSelectorView()
                    }
                case .notDetermined, .denied:
                    PermissionRequestView(
                        onRequestAccess: requestAccess,
                        onOpenSettings: openSettings,
                        isDenied: permissionStatus == .denied
                    )
                }
            }
        }
        .onAppear {
            print("🔴🔴🔴 APP LAUNCHED - CONSOLE WORKING 🔴🔴🔴")
            checkPermission()
        }
    }

    private func checkPermission() {
        permissionStatus = photoService.checkCurrentStatus()
        isCheckingPermission = false
        
        // Show onboarding flow if first time and permission granted
        if (permissionStatus == .authorized || permissionStatus == .limited) {
            if !hasSeenTutorial {
                showTutorial = true
            } else if !hasCompletedOnboarding {
                showReturningUser = true
            }
        }
    }

    private func requestAccess() async {
        permissionStatus = await photoService.requestAccess()
        
        // After granting permission, show onboarding
        if (permissionStatus == .authorized || permissionStatus == .limited) {
            if !hasSeenTutorial {
                showTutorial = true
            } else if !hasCompletedOnboarding {
                showReturningUser = true
            }
        }
    }
    
    private func completeOnboarding(startYear: Int?, startMonth: Int?) {
        if let year = startYear {
            // Mark all months before this year/month as completed
            monthService.markMonthsCompletedBefore(year: year, month: startMonth ?? 1)
        }
        
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
        showReturningUser = false
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
