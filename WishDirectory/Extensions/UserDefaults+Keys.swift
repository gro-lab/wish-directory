//
//  UserDefaults+Keys.swift
//  WishDirectory
//
//  Created by Radu-Ovidiu Gavrilă on 22.09.2025.
//

import Foundation

// MARK: - UserDefaults Extension

extension UserDefaults {
    
    // MARK: - Keys Namespace
    
    enum Keys {
        // MARK: App Data
        static let savedApps = "com.wishdirectory.savedApps"
        static let savedAppsData = "com.wishdirectory.savedAppsData"
        static let collections = "com.wishdirectory.collections"
        static let priceHistory = "com.wishdirectory.priceHistory"
        static let appMetadata = "com.wishdirectory.appMetadata"
        
        // MARK: User Preferences
        static let notificationsEnabled = "com.wishdirectory.notificationsEnabled"
        static let priceDropThreshold = "com.wishdirectory.priceDropThreshold"
        static let autoUpdatePrices = "com.wishdirectory.autoUpdatePrices"
        static let updateFrequencyHours = "com.wishdirectory.updateFrequencyHours"
        static let showBadgeOnPriceDrops = "com.wishdirectory.showBadgeOnPriceDrops"
        static let hapticFeedbackEnabled = "com.wishdirectory.hapticFeedbackEnabled"
        
        // MARK: Display Settings
        static let sortOrder = "com.wishdirectory.sortOrder"
        static let filterOnSaleOnly = "com.wishdirectory.filterOnSaleOnly"
        static let hideFreeApps = "com.wishdirectory.hideFreeApps"
        static let compactView = "com.wishdirectory.compactView"
        static let showDeveloperName = "com.wishdirectory.showDeveloperName"
        
        // MARK: Regional Settings
        static let preferredCurrency = "com.wishdirectory.preferredCurrency"
        static let preferredRegion = "com.wishdirectory.preferredRegion"
        static let preferredLanguage = "com.wishdirectory.preferredLanguage"
        
        // MARK: Timestamps
        static let lastUpdateTimestamp = "com.wishdirectory.lastUpdateTimestamp"
        static let lastPriceCheckTimestamp = "com.wishdirectory.lastPriceCheckTimestamp"
        static let lastActiveTimestamp = "com.wishdirectory.lastActiveTimestamp"
        static let lastNotificationTimestamp = "com.wishdirectory.lastNotificationTimestamp"
        
        // MARK: Statistics
        static let totalPriceDropsDetected = "com.wishdirectory.totalPriceDropsDetected"
        static let totalAmountSaved = "com.wishdirectory.totalAmountSaved"
        static let appsAddedCount = "com.wishdirectory.appsAddedCount"
        static let appsRemovedCount = "com.wishdirectory.appsRemovedCount"
        
        // MARK: App State
        static let hasLaunchedBefore = "com.wishdirectory.hasLaunchedBefore"
        static let lastActiveTab = "com.wishdirectory.lastActiveTab"
        static let onboardingCompleted = "com.wishdirectory.onboardingCompleted"
        static let appVersion = "com.wishdirectory.appVersion"
        static let buildNumber = "com.wishdirectory.buildNumber"
        
        // MARK: Privacy & Analytics
        static let analyticsEnabled = "com.wishdirectory.analyticsEnabled"
        static let crashReportingEnabled = "com.wishdirectory.crashReportingEnabled"
        static let personalizedAdsEnabled = "com.wishdirectory.personalizedAdsEnabled"
        static let dataCollectionConsent = "com.wishdirectory.dataCollectionConsent"
        static let lastPrivacyPromptDate = "com.wishdirectory.lastPrivacyPromptDate"
        
        // MARK: Cache & Temporary Data
        static let iconCacheData = "com.wishdirectory.iconCacheData"
        static let searchHistory = "com.wishdirectory.searchHistory"
        static let recentlyViewedApps = "com.wishdirectory.recentlyViewedApps"
        static let temporaryAlerts = "com.wishdirectory.temporaryAlerts"
        
        // MARK: Feature Flags
        static let betaFeaturesEnabled = "com.wishdirectory.betaFeaturesEnabled"
        static let debugModeEnabled = "com.wishdirectory.debugModeEnabled"
        static let advancedFiltersEnabled = "com.wishdirectory.advancedFiltersEnabled"
    }
    
    // MARK: - Type-Safe Accessors
    
    // MARK: Wishlist Apps
    
    var savedWishlistApps: [WishlistApp] {
        get {
            guard let data = data(forKey: Keys.savedAppsData) else { return [] }
            return (try? JSONDecoder().decode([WishlistApp].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Keys.savedAppsData)
            }
        }
    }
    
    // MARK: Notification Settings
    
    var notificationsEnabled: Bool {
        get { bool(forKey: Keys.notificationsEnabled) }
        set { set(newValue, forKey: Keys.notificationsEnabled) }
    }
    
    var priceDropThreshold: Double {
        get { double(forKey: Keys.priceDropThreshold) }
        set { set(newValue, forKey: Keys.priceDropThreshold) }
    }
    
    // MARK: Update Settings
    
    var autoUpdatePrices: Bool {
        get { bool(forKey: Keys.autoUpdatePrices) }
        set { set(newValue, forKey: Keys.autoUpdatePrices) }
    }
    
    var updateFrequencyHours: Int {
        get { integer(forKey: Keys.updateFrequencyHours) }
        set { set(newValue, forKey: Keys.updateFrequencyHours) }
    }
    
    // MARK: Timestamps
    
    var lastUpdateTimestamp: Date? {
        get { object(forKey: Keys.lastUpdateTimestamp) as? Date }
        set {
            if let date = newValue {
                set(date, forKey: Keys.lastUpdateTimestamp)
            } else {
                removeObject(forKey: Keys.lastUpdateTimestamp)
            }
        }
    }
    
    var lastPriceCheckTimestamp: Date? {
        get { object(forKey: Keys.lastPriceCheckTimestamp) as? Date }
        set {
            if let date = newValue {
                set(date, forKey: Keys.lastPriceCheckTimestamp)
            } else {
                removeObject(forKey: Keys.lastPriceCheckTimestamp)
            }
        }
    }
    
    // MARK: Statistics
    
    var totalPriceDropsDetected: Int {
        get { integer(forKey: Keys.totalPriceDropsDetected) }
        set { set(newValue, forKey: Keys.totalPriceDropsDetected) }
    }
    
    var totalAmountSaved: Double {
        get { double(forKey: Keys.totalAmountSaved) }
        set { set(newValue, forKey: Keys.totalAmountSaved) }
    }
    
    // MARK: App State
    
    var hasLaunchedBefore: Bool {
        get { bool(forKey: Keys.hasLaunchedBefore) }
        set { set(newValue, forKey: Keys.hasLaunchedBefore) }
    }
    
    var lastActiveTab: Int {
        get { integer(forKey: Keys.lastActiveTab) }
        set { set(newValue, forKey: Keys.lastActiveTab) }
    }
    
    // MARK: Regional Settings
    
    var preferredCurrency: String {
        get { string(forKey: Keys.preferredCurrency) ?? Locale.current.currencyCode ?? "USD" }
        set { set(newValue, forKey: Keys.preferredCurrency) }
    }
    
    var preferredRegion: String {
        get { string(forKey: Keys.preferredRegion) ?? Locale.current.regionCode ?? "US" }
        set { set(newValue, forKey: Keys.preferredRegion) }
    }
    
    // MARK: - Convenience Methods
    
    /// Clear all wishlist data
    func clearWishlistData() {
        removeObject(forKey: Keys.savedApps)
        removeObject(forKey: Keys.savedAppsData)
        removeObject(forKey: Keys.collections)
        removeObject(forKey: Keys.priceHistory)
        removeObject(forKey: Keys.appMetadata)
    }
    
    /// Clear all user preferences
    func clearUserPreferences() {
        removeObject(forKey: Keys.notificationsEnabled)
        removeObject(forKey: Keys.priceDropThreshold)
        removeObject(forKey: Keys.autoUpdatePrices)
        removeObject(forKey: Keys.updateFrequencyHours)
        removeObject(forKey: Keys.showBadgeOnPriceDrops)
        removeObject(forKey: Keys.hapticFeedbackEnabled)
        removeObject(forKey: Keys.sortOrder)
        removeObject(forKey: Keys.filterOnSaleOnly)
        removeObject(forKey: Keys.hideFreeApps)
        removeObject(forKey: Keys.preferredCurrency)
        removeObject(forKey: Keys.preferredRegion)
    }
    
    /// Clear all cached data
    func clearCachedData() {
        removeObject(forKey: Keys.iconCacheData)
        removeObject(forKey: Keys.searchHistory)
        removeObject(forKey: Keys.recentlyViewedApps)
        removeObject(forKey: Keys.temporaryAlerts)
    }
    
    /// Reset all app data (factory reset)
    func resetAllData() {
        clearWishlistData()
        clearUserPreferences()
        clearCachedData()
        
        // Reset statistics
        removeObject(forKey: Keys.totalPriceDropsDetected)
        removeObject(forKey: Keys.totalAmountSaved)
        removeObject(forKey: Keys.appsAddedCount)
        removeObject(forKey: Keys.appsRemovedCount)
        
        // Reset timestamps
        removeObject(forKey: Keys.lastUpdateTimestamp)
        removeObject(forKey: Keys.lastPriceCheckTimestamp)
        removeObject(forKey: Keys.lastActiveTimestamp)
        removeObject(forKey: Keys.lastNotificationTimestamp)
        
        // Keep app state
        // Don't remove hasLaunchedBefore, onboardingCompleted
    }
    
    /// Check if this is a fresh install
    func isFreshInstall() -> Bool {
        return !hasLaunchedBefore
    }
    
    /// Record app launch
    func recordAppLaunch() {
        hasLaunchedBefore = true
        lastActiveTimestamp = Date()
        
        // Store current app version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            set(version, forKey: Keys.appVersion)
        }
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            set(build, forKey: Keys.buildNumber)
        }
    }
    
    /// Get formatted statistics summary
    func getStatisticsSummary() -> [String: Any] {
        return [
            "appsTracked": savedWishlistApps.count,
            "priceDropsDetected": totalPriceDropsDetected,
            "totalSaved": totalAmountSaved,
            "lastUpdate": lastUpdateTimestamp ?? "Never"
        ]
    }
}

// MARK: - UserDefaults Suite Extension

extension UserDefaults {
    /// Custom suite for app group (for future widget support)
    static let appGroup = UserDefaults(suiteName: "group.com.wishdirectory")
    
    /// Migrate data to app group
    func migrateToAppGroup() {
        guard let appGroup = UserDefaults.appGroup else { return }
        
        // Migrate essential data to app group
        if let appsData = data(forKey: Keys.savedAppsData) {
            appGroup.set(appsData, forKey: Keys.savedAppsData)
        }
        
        appGroup.set(bool(forKey: Keys.notificationsEnabled), forKey: Keys.notificationsEnabled)
        appGroup.set(double(forKey: Keys.priceDropThreshold), forKey: Keys.priceDropThreshold)
        
        if let timestamp = object(forKey: Keys.lastUpdateTimestamp) {
            appGroup.set(timestamp, forKey: Keys.lastUpdateTimestamp)
        }
    }
}

// MARK: - Codable Helper

extension UserDefaults {
    /// Save any Codable object
    func setCodable<T: Codable>(_ value: T?, forKey key: String) {
        guard let value = value else {
            removeObject(forKey: key)
            return
        }
        
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }
    
    /// Retrieve any Codable object
    func getCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
