//
//  UserSettings.swift
//  WishDirectory
//
//  Created by Radu-Ovidiu Gavrilă on 22.09.2025.
//

import Foundation
import Combine

// MARK: - User Settings Model

class UserSettings: ObservableObject {
    // MARK: - Singleton Instance
    static let shared = UserSettings()
    
    // MARK: - Published Properties
    
    /// Enable/disable price drop notifications
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }
    
    /// Minimum percentage drop to trigger notification (0-100)
    @Published var priceDropThreshold: Double {
        didSet {
            UserDefaults.standard.set(priceDropThreshold, forKey: Keys.priceDropThreshold)
        }
    }
    
    /// Automatically check prices in background
    @Published var autoUpdatePrices: Bool {
        didSet {
            UserDefaults.standard.set(autoUpdatePrices, forKey: Keys.autoUpdatePrices)
        }
    }
    
    /// Last time prices were checked
    @Published var lastUpdateTimestamp: Date? {
        didSet {
            if let timestamp = lastUpdateTimestamp {
                UserDefaults.standard.set(timestamp, forKey: Keys.lastUpdateTimestamp)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastUpdateTimestamp)
            }
        }
    }
    
    /// Update frequency in hours (6, 12, 24)
    @Published var updateFrequencyHours: Int {
        didSet {
            UserDefaults.standard.set(updateFrequencyHours, forKey: Keys.updateFrequencyHours)
        }
    }
    
    /// Show badge on app icon for price drops
    @Published var showBadgeOnPriceDrops: Bool {
        didSet {
            UserDefaults.standard.set(showBadgeOnPriceDrops, forKey: Keys.showBadgeOnPriceDrops)
        }
    }
    
    /// Currency preference (auto-detect or manual)
    @Published var preferredCurrency: String {
        didSet {
            UserDefaults.standard.set(preferredCurrency, forKey: Keys.preferredCurrency)
        }
    }
    
    /// Country/region for App Store
    @Published var preferredRegion: String {
        didSet {
            UserDefaults.standard.set(preferredRegion, forKey: Keys.preferredRegion)
        }
    }
    
    /// Sort order for wishlist
    @Published var sortOrder: SortOrder {
        didSet {
            UserDefaults.standard.set(sortOrder.rawValue, forKey: Keys.sortOrder)
        }
    }
    
    /// Show only apps on sale
    @Published var filterOnSaleOnly: Bool {
        didSet {
            UserDefaults.standard.set(filterOnSaleOnly, forKey: Keys.filterOnSaleOnly)
        }
    }
    
    /// Hide free apps from wishlist
    @Published var hideFreeApps: Bool {
        didSet {
            UserDefaults.standard.set(hideFreeApps, forKey: Keys.hideFreeApps)
        }
    }
    
    /// Enable haptic feedback
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled)
        }
    }
    
    /// Analytics consent (GDPR compliance)
    @Published var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: Keys.analyticsEnabled)
        }
    }
    
    /// Total number of price drops detected
    @Published var totalPriceDropsDetected: Int {
        didSet {
            UserDefaults.standard.set(totalPriceDropsDetected, forKey: Keys.totalPriceDropsDetected)
        }
    }
    
    /// Total amount saved from price drops
    @Published var totalAmountSaved: Double {
        didSet {
            UserDefaults.standard.set(totalAmountSaved, forKey: Keys.totalAmountSaved)
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let priceDropThreshold = "priceDropThreshold"
        static let autoUpdatePrices = "autoUpdatePrices"
        static let lastUpdateTimestamp = "lastUpdateTimestamp"
        static let updateFrequencyHours = "updateFrequencyHours"
        static let showBadgeOnPriceDrops = "showBadgeOnPriceDrops"
        static let preferredCurrency = "preferredCurrency"
        static let preferredRegion = "preferredRegion"
        static let sortOrder = "sortOrder"
        static let filterOnSaleOnly = "filterOnSaleOnly"
        static let hideFreeApps = "hideFreeApps"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let analyticsEnabled = "analyticsEnabled"
        static let totalPriceDropsDetected = "totalPriceDropsDetected"
        static let totalAmountSaved = "totalAmountSaved"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved settings or use defaults
        self.notificationsEnabled = UserDefaults.standard.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
        self.priceDropThreshold = UserDefaults.standard.object(forKey: Keys.priceDropThreshold) as? Double ?? 10.0
        self.autoUpdatePrices = UserDefaults.standard.object(forKey: Keys.autoUpdatePrices) as? Bool ?? true
        self.lastUpdateTimestamp = UserDefaults.standard.object(forKey: Keys.lastUpdateTimestamp) as? Date
        self.updateFrequencyHours = UserDefaults.standard.object(forKey: Keys.updateFrequencyHours) as? Int ?? 24
        self.showBadgeOnPriceDrops = UserDefaults.standard.object(forKey: Keys.showBadgeOnPriceDrops) as? Bool ?? true
        self.preferredCurrency = UserDefaults.standard.string(forKey: Keys.preferredCurrency) ?? Locale.current.currencyCode ?? "USD"
        self.preferredRegion = UserDefaults.standard.string(forKey: Keys.preferredRegion) ?? Locale.current.regionCode ?? "US"
        
        let sortOrderRaw = UserDefaults.standard.string(forKey: Keys.sortOrder) ?? SortOrder.discountPercentage.rawValue
        self.sortOrder = SortOrder(rawValue: sortOrderRaw) ?? .discountPercentage
        
        self.filterOnSaleOnly = UserDefaults.standard.object(forKey: Keys.filterOnSaleOnly) as? Bool ?? false
        self.hideFreeApps = UserDefaults.standard.object(forKey: Keys.hideFreeApps) as? Bool ?? false
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) as? Bool ?? true
        self.analyticsEnabled = UserDefaults.standard.object(forKey: Keys.analyticsEnabled) as? Bool ?? false
        self.totalPriceDropsDetected = UserDefaults.standard.object(forKey: Keys.totalPriceDropsDetected) as? Int ?? 0
        self.totalAmountSaved = UserDefaults.standard.object(forKey: Keys.totalAmountSaved) as? Double ?? 0.0
        
        // Set up Combine observers for real-time sync
        setupObservers()
    }
    
    // MARK: - Methods
    
    private func setupObservers() {
        // Monitor significant settings changes for analytics
        $analyticsEnabled
            .dropFirst() // Skip initial value
            .sink { [weak self] enabled in
                if !enabled {
                    self?.clearAnalyticsData()
                }
            }
            .store(in: &cancellables)
        
        // Auto-update last timestamp when auto-update is triggered
        $autoUpdatePrices
            .combineLatest($updateFrequencyHours)
            .dropFirst()
            .sink { [weak self] (autoUpdate, frequency) in
                if autoUpdate {
                    self?.scheduleNextUpdate(hours: frequency)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        notificationsEnabled = true
        priceDropThreshold = 10.0
        autoUpdatePrices = true
        updateFrequencyHours = 24
        showBadgeOnPriceDrops = true
        preferredCurrency = Locale.current.currencyCode ?? "USD"
        preferredRegion = Locale.current.regionCode ?? "US"
        sortOrder = .discountPercentage
        filterOnSaleOnly = false
        hideFreeApps = false
        hapticFeedbackEnabled = true
        analyticsEnabled = false
        // Don't reset statistics
    }
    
    /// Record a new price drop
    func recordPriceDrop(amount: Double) {
        totalPriceDropsDetected += 1
        totalAmountSaved += amount
    }
    
    /// Check if update is needed based on frequency
    func isUpdateNeeded() -> Bool {
        guard let lastUpdate = lastUpdateTimestamp else { return true }
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
        return hoursSinceUpdate >= Double(updateFrequencyHours)
    }
    
    /// Update the last check timestamp
    func updateLastCheckTimestamp() {
        lastUpdateTimestamp = Date()
    }
    
    /// Clear analytics data when consent is revoked
    private func clearAnalyticsData() {
        // Clear any analytics-related data
        // This is a placeholder for future analytics implementation
    }
    
    /// Schedule next automatic update
    private func scheduleNextUpdate(hours: Int) {
        // This will be implemented with background tasks in Sprint 5
    }
    
    /// Get formatted currency for display
    func formattedCurrency() -> String {
        let locale = Locale(identifier: "en_\(preferredRegion)")
        return locale.currencySymbol ?? "$"
    }
    
    /// Check if a price drop meets the threshold
    func meetsThreshold(discountPercentage: Double) -> Bool {
        return discountPercentage >= priceDropThreshold
    }
}

// MARK: - Sort Order Enum

enum SortOrder: String, CaseIterable {
    case discountPercentage = "discount"
    case priceLowToHigh = "price_asc"
    case priceHighToLow = "price_desc"
    case alphabetical = "name"
    case dateAdded = "date_added"
    case developer = "developer"
    
    var displayName: String {
        switch self {
        case .discountPercentage:
            return "Discount %"
        case .priceLowToHigh:
            return "Price: Low to High"
        case .priceHighToLow:
            return "Price: High to Low"
        case .alphabetical:
            return "Name"
        case .dateAdded:
            return "Recently Added"
        case .developer:
            return "Developer"
        }
    }
    
    var icon: String {
        switch self {
        case .discountPercentage:
            return "percent"
        case .priceLowToHigh:
            return "arrow.up.circle"
        case .priceHighToLow:
            return "arrow.down.circle"
        case .alphabetical:
            return "textformat"
        case .dateAdded:
            return "calendar"
        case .developer:
            return "person.circle"
        }
    }
}

// MARK: - Notification Settings

extension UserSettings {
    /// Check if notifications are properly configured
    var areNotificationsConfigured: Bool {
        return notificationsEnabled && priceDropThreshold > 0
    }
    
    /// Get human-readable update frequency
    var updateFrequencyDescription: String {
        switch updateFrequencyHours {
        case 6:
            return "Every 6 hours"
        case 12:
            return "Twice daily"
        case 24:
            return "Once daily"
        default:
            return "Every \(updateFrequencyHours) hours"
        }
    }
    
    /// Get next update time
    var nextUpdateTime: Date? {
        guard let lastUpdate = lastUpdateTimestamp else { return nil }
        return lastUpdate.addingTimeInterval(TimeInterval(updateFrequencyHours * 3600))
    }
}

// MARK: - Statistics

extension UserSettings {
    /// Get formatted total savings
    var formattedTotalSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = preferredCurrency
        return formatter.string(from: NSNumber(value: totalAmountSaved)) ?? "$0.00"
    }
    
    /// Get average savings per drop
    var averageSavingsPerDrop: Double {
        guard totalPriceDropsDetected > 0 else { return 0 }
        return totalAmountSaved / Double(totalPriceDropsDetected)
    }
}
