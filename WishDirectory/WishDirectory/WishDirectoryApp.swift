//
//  WishDirectoryApp.swift
//  WishDirectory
//
//  Created by Radu-Ovidiu GavrilÄƒ on 22.09.2025.
//

import SwiftUI
import Combine

@main
struct WishDirectoryApp: App {
    // MARK: - App State
    @StateObject private var appState = AppState()
    @State private var hasRestoredState = false
    
    // MARK: - User Defaults
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("lastActiveTab") private var lastActiveTab = 0
    
    // MARK: - Scene Phase
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $lastActiveTab)
                .environmentObject(appState)
                .onAppear {
                    performInitialSetup()
                }
                .onChange(of: scenePhase) {
                    handleScenePhaseChange($0)
                }
        }
    }
    
    // MARK: - App Lifecycle Management
    
    private func performInitialSetup() {
        // First launch setup
        if !hasLaunchedBefore {
            setupDefaultSettings()
            hasLaunchedBefore = true
        }
        
        // Restore app state
        if !hasRestoredState {
            restoreAppState()
            hasRestoredState = true
        }
        
        // Configure appearance
        configureAppearance()
    }
    
    private func setupDefaultSettings() {
        // Set default user preferences if not already set
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "notificationsEnabled") == nil {
            defaults.set(true, forKey: "notificationsEnabled")
        }
        
        if defaults.object(forKey: "priceDropThreshold") == nil {
            defaults.set(10.0, forKey: "priceDropThreshold") // 10% default threshold
        }
        
        if defaults.object(forKey: "autoUpdatePrices") == nil {
            defaults.set(true, forKey: "autoUpdatePrices")
        }
    }
    
    private func restoreAppState() {
        // Restore saved apps from UserDefaults
        appState.loadSavedApps()
        
        // Restore user settings
        appState.loadUserSettings()
        
        // Set last update timestamp if needed
        if appState.lastUpdateTimestamp == nil {
            appState.lastUpdateTimestamp = Date()
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            handleAppBecameActive()
            
        case .inactive:
            // App is transitioning to background
            handleAppWillResignActive()
            
        case .background:
            // App entered background
            handleAppEnteredBackground()
            
        @unknown default:
            break
        }
    }
    
    private func handleAppBecameActive() {
        // Check if we should update prices when returning from background
        if shouldCheckPricesOnActivation() {
            appState.shouldRefreshPrices = true
        }
        
        // Update last active timestamp
        UserDefaults.standard.set(Date(), forKey: "lastActiveTimestamp")
    }
    
    private func handleAppWillResignActive() {
        // Save current app state
        appState.saveCurrentState()
        
        // Persist any pending changes
        appState.persistPendingChanges()
    }
    
    private func handleAppEnteredBackground() {
        // Final save before backgrounding
        appState.saveCurrentState()
        
        // Clean up temporary data if needed
        appState.cleanupTemporaryData()
    }
    
    private func shouldCheckPricesOnActivation() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: "lastPriceCheckTimestamp") as? Date else {
            return true
        }
        
        // Check if more than 24 hours have passed since last check
        let hoursSinceLastCheck = Date().timeIntervalSince(lastCheck) / 3600
        return hoursSinceLastCheck >= 24
    }
    
    private func configureAppearance() {
        // Set up global appearance customization
        
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - App State Management

class AppState: ObservableObject {
    // Published properties for UI updates
    @Published var savedApps: [String] = []
    @Published var shouldRefreshPrices = false
    @Published var lastUpdateTimestamp: Date?
    @Published var isLoading = false
    @Published var hasUnsavedChanges = false
    
    // UserDefaults keys
    private let savedAppsKey = "savedAppsData"
    private let userSettingsKey = "userSettings"
    private let lastUpdateKey = "lastUpdateTimestamp"
    
    // MARK: - Data Persistence
    
    func loadSavedApps() {
        if let data = UserDefaults.standard.data(forKey: savedAppsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.savedApps = decoded
        }
    }
    
    func saveCurrentState() {
        // Save apps
        if let encoded = try? JSONEncoder().encode(savedApps) {
            UserDefaults.standard.set(encoded, forKey: savedAppsKey)
        }
        
        // Save last update timestamp
        if let timestamp = lastUpdateTimestamp {
            UserDefaults.standard.set(timestamp, forKey: lastUpdateKey)
        }
        
        // Reset unsaved changes flag
        hasUnsavedChanges = false
    }
    
    func loadUserSettings() {
        // Load last update timestamp
        if let timestamp = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            lastUpdateTimestamp = timestamp
        }
    }
    
    func persistPendingChanges() {
        guard hasUnsavedChanges else { return }
        saveCurrentState()
    }
    
    func cleanupTemporaryData() {
        // Clean up any temporary data that shouldn't persist
        // This is a placeholder for future implementation
    }
    
    // MARK: - App Management
    
    func addApp(_ appId: String) {
        guard !savedApps.contains(appId) else { return }
        savedApps.append(appId)
        hasUnsavedChanges = true
    }
    
    func removeApp(_ appId: String) {
        savedApps.removeAll { $0 == appId }
        hasUnsavedChanges = true
    }
    
    func updateLastCheck() {
        lastUpdateTimestamp = Date()
        UserDefaults.standard.set(Date(), forKey: "lastPriceCheckTimestamp")
    }
}
