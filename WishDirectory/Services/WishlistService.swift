//
//  WishlistService.swift
//  WishDirectory
//
//  Enhanced for Sprint 5 - Price Tracking & Notifications
//

import Foundation
import Combine

// MARK: - Wishlist Service Protocol

protocol WishlistServiceProtocol {
    func addApp(_ app: WishlistApp) async throws
    func addAppFromURL(_ urlString: String) async throws -> WishlistApp
    func removeApp(withId id: Int) async throws
    func updateApp(_ app: WishlistApp) async throws
    func updatePriceForApp(withId id: Int) async throws -> WishlistApp?
    func updateAllPrices() async throws -> [(app: WishlistApp, oldPrice: Double, newPrice: Double)]
    func getApp(withId id: Int) -> WishlistApp?
    func getAllApps() -> [WishlistApp]
    func getAppsOnSale() -> [WishlistApp]
    func searchApps(query: String) -> [WishlistApp]
    func sortApps(by sortOrder: SortOrder) -> [WishlistApp]
    func clearAllApps() async throws
}

// MARK: - Wishlist Service Implementation

@MainActor
class WishlistService: ObservableObject, WishlistServiceProtocol {
    
    // MARK: - Singleton
    static let shared = WishlistService()
    
    // MARK: - Published Properties
    @Published private(set) var apps: [WishlistApp] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?
    @Published private(set) var priceDropsDetected: [(app: WishlistApp, savings: Double)] = []
    @Published private(set) var lastUpdateTimestamp: Date?
    @Published private(set) var updateProgress: Double = 0.0
    @Published private(set) var isUpdatingPrices = false
    
    // MARK: - Private Properties
    private let iTunesService = iTunesService.shared
    private let notificationService = NotificationService.shared
    private let userSettings = UserSettings.shared
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadApps()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Auto-save when apps array changes
        $apps
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveApps()
            }
            .store(in: &cancellables)
        
        // Monitor settings for auto-update
        userSettings.$autoUpdatePrices
            .combineLatest(userSettings.$updateFrequencyHours)
            .sink { [weak self] (autoUpdate, frequency) in
                if autoUpdate {
                    self?.scheduleAutomaticPriceUpdate(frequency: frequency)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Persistence
    
    private func loadApps() {
        apps = userDefaults.savedWishlistApps
        lastUpdateTimestamp = userDefaults.lastUpdateTimestamp
    }
    
    private func saveApps() {
        userDefaults.savedWishlistApps = apps
        userDefaults.lastUpdateTimestamp = lastUpdateTimestamp
        updateStatistics()
    }
    
    private func updateStatistics() {
        let totalSavings = apps.reduce(0) { $0 + $1.discountAmount }
        let priceDropCount = apps.filter { $0.isOnSale }.count
        
        userDefaults.totalAmountSaved = totalSavings
        userDefaults.totalPriceDropsDetected = priceDropCount
        
        userSettings.totalAmountSaved = totalSavings
        userSettings.totalPriceDropsDetected = priceDropCount
    }
    
    // MARK: - CRUD Operations
    
    func addApp(_ app: WishlistApp) async throws {
        guard !apps.contains(where: { $0.id == app.id }) else {
            throw WishlistError.appAlreadyExists(app.name)
        }
        
        var newApp = app
        newApp.lastChecked = Date()
        
        apps.append(newApp)
        saveApps()
        
        // Trigger initial price check for new app
        _ = try? await updatePriceForApp(withId: app.id)
    }
    
    func addAppFromURL(_ urlString: String) async throws -> WishlistApp {
        isLoading = true
        defer { isLoading = false }
        
        guard let appId = URL(string: urlString)?.extractAppStoreId() else {
            throw WishlistError.invalidURL(urlString)
        }
        
        if let existingApp = getApp(withId: appId) {
            throw WishlistError.appAlreadyExists(existingApp.name)
        }
        
        let appData = try await iTunesService.lookupApp(by: String(appId))
        
        let wishlistApp = WishlistApp(
            id: appData.trackId,
            name: appData.trackName,
            developer: appData.artistName,
            iconURL: appData.artworkUrl512 ?? appData.artworkUrl100 ?? "",
            storeURL: appData.trackViewUrl,
            currentPrice: appData.price ?? 0,
            originalPrice: appData.price ?? 0,
            currency: appData.currency,
            dateAdded: Date(),
            lastChecked: Date(),
            tags: [],
            category: appData.primaryGenreName,
            version: appData.version,
            sizeInBytes: Int64(appData.fileSizeBytes ?? "0") ?? 0,
            ageRating: appData.contentAdvisoryRating,
            averageRating: appData.averageUserRating,
            ratingCount: appData.userRatingCount,
            bundleId: appData.bundleId,
            releaseDate: ISO8601DateFormatter().date(from: appData.currentVersionReleaseDate ?? ""),
            formattedPrice: appData.formattedPrice
        )
        
        try await addApp(wishlistApp)
        return wishlistApp
    }
    
    func removeApp(withId id: Int) async throws {
        guard let index = apps.firstIndex(where: { $0.id == id }) else {
            throw WishlistError.appNotFound(id)
        }
        
        // Cancel any pending notifications for this app
        notificationService.cancelNotification(for: id)
        
        apps.remove(at: index)
        saveApps()
    }
    
    func updateApp(_ app: WishlistApp) async throws {
        guard let index = apps.firstIndex(where: { $0.id == app.id }) else {
            throw WishlistError.appNotFound(app.id)
        }
        
        apps[index] = app
        saveApps()
    }
    
    // MARK: - Enhanced Price Updates
    
    func updatePriceForApp(withId id: Int) async throws -> WishlistApp? {
        guard let index = apps.firstIndex(where: { $0.id == id }) else {
            throw WishlistError.appNotFound(id)
        }
        
        let appData = try await iTunesService.lookupApp(by: String(id))
        
        var updatedApp = apps[index]
        let oldPrice = updatedApp.currentPrice
        let newPrice = appData.price ?? 0
        
        // Update price and metadata
        if newPrice != oldPrice {
            updatedApp.updatePrice(newPrice, formattedPrice: appData.formattedPrice)
            
            // Check for significant price drop
            if newPrice < oldPrice {
                let discountPercentage = ((oldPrice - newPrice) / oldPrice) * 100
                
                if userSettings.meetsThreshold(discountPercentage: discountPercentage) {
                    // Record price drop
                    priceDropsDetected.append((app: updatedApp, savings: oldPrice - newPrice))
                    userSettings.recordPriceDrop(amount: oldPrice - newPrice)
                    
                    // Schedule notification if enabled
                    if userSettings.notificationsEnabled {
                        await notificationService.scheduleAppPriceDropNotification(
                            app: updatedApp,
                            oldPrice: oldPrice,
                            newPrice: newPrice
                        )
                    }
                }
            }
            
            apps[index] = updatedApp
            saveApps()
            
            return updatedApp
        }
        
        // Update last checked even if price didn't change
        updatedApp.lastChecked = Date()
        apps[index] = updatedApp
        saveApps()
        
        return nil
    }
    
    func updateAllPrices() async throws -> [(app: WishlistApp, oldPrice: Double, newPrice: Double)] {
        guard !isUpdatingPrices else {
            throw WishlistError.updateFailed("Price update already in progress")
        }
        
        isUpdatingPrices = true
        updateProgress = 0.0
        defer {
            isUpdatingPrices = false
            updateProgress = 0.0
        }
        
        var priceChanges: [(app: WishlistApp, oldPrice: Double, newPrice: Double)] = []
        var significantDrops: [(app: WishlistApp, oldPrice: Double, newPrice: Double)] = []
        
        let totalApps = apps.count
        guard totalApps > 0 else { return [] }
        
        for (index, app) in apps.enumerated() {
            do {
                // Update progress
                updateProgress = Double(index) / Double(totalApps)
                
                // Rate limiting: 3 seconds between requests (20 requests per minute)
                if index > 0 {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                }
                
                let appData = try await iTunesService.lookupApp(by: String(app.id))
                let oldPrice = app.currentPrice
                let newPrice = appData.price ?? 0
                
                if newPrice != oldPrice {
                    var updatedApp = app
                    updatedApp.updatePrice(newPrice, formattedPrice: appData.formattedPrice)
                    
                    // Update app in array
                    if let appIndex = apps.firstIndex(where: { $0.id == app.id }) {
                        apps[appIndex] = updatedApp
                    }
                    
                    priceChanges.append((app: updatedApp, oldPrice: oldPrice, newPrice: newPrice))
                    
                    // Check for significant price drop
                    if newPrice < oldPrice {
                        let discountPercentage = ((oldPrice - newPrice) / oldPrice) * 100
                        
                        if userSettings.meetsThreshold(discountPercentage: discountPercentage) {
                            significantDrops.append((app: updatedApp, oldPrice: oldPrice, newPrice: newPrice))
                            userSettings.recordPriceDrop(amount: oldPrice - newPrice)
                        }
                    }
                } else {
                    // Update last checked even if price didn't change
                    if let appIndex = apps.firstIndex(where: { $0.id == app.id }) {
                        apps[appIndex].lastChecked = Date()
                    }
                }
                
            } catch {
                print("Failed to update price for \(app.name): \(error)")
                lastError = error
                continue
            }
        }
        
        // Complete progress
        updateProgress = 1.0
        
        // Save all changes
        lastUpdateTimestamp = Date()
        userSettings.updateLastCheckTimestamp()
        saveApps()
        
        // Schedule batch notifications for significant drops
        if !significantDrops.isEmpty && userSettings.notificationsEnabled {
            await notificationService.scheduleBatchPriceDropNotifications(priceDrops: significantDrops)
        }
        
        // Update price drops detected array
        priceDropsDetected = significantDrops.map { (app: $0.app, savings: $0.oldPrice - $0.newPrice) }
        
        return priceChanges
    }
    
    // MARK: - Automatic Updates
    
    private func scheduleAutomaticPriceUpdate(frequency: Int) {
        // This would integrate with background tasks in a full implementation
        // For now, we check if an update is needed when the app becomes active
        guard userSettings.isUpdateNeeded() else { return }
        
        Task {
            _ = try? await updateAllPrices()
        }
    }
    
    func checkIfUpdateNeeded() async {
        guard userSettings.autoUpdatePrices && userSettings.isUpdateNeeded() else { return }
        
        _ = try? await updateAllPrices()
    }
    
    // MARK: - Query Operations
    
    func getApp(withId id: Int) -> WishlistApp? {
        return apps.first(where: { $0.id == id })
    }
    
    func getAllApps() -> [WishlistApp] {
        return apps
    }
    
    func getAppsOnSale() -> [WishlistApp] {
        return apps.filter { $0.isOnSale }
    }
    
    func searchApps(query: String) -> [WishlistApp] {
        let lowercasedQuery = query.lowercased()
        
        guard !lowercasedQuery.isEmpty else { return apps }
        
        return apps.filter { app in
            app.name.lowercased().contains(lowercasedQuery) ||
            app.developer.lowercased().contains(lowercasedQuery) ||
            app.category?.lowercased().contains(lowercasedQuery) == true ||
            app.tags.contains { $0.lowercased().contains(lowercasedQuery) } ||
            app.notes?.lowercased().contains(lowercasedQuery) == true
        }
    }
    
    func sortApps(by sortOrder: SortOrder) -> [WishlistApp] {
        switch sortOrder {
        case .discountPercentage:
            return apps.sorted { $0.discountPercentage > $1.discountPercentage }
        case .priceLowToHigh:
            return apps.sorted { $0.currentPrice < $1.currentPrice }
        case .priceHighToLow:
            return apps.sorted { $0.currentPrice > $1.currentPrice }
        case .alphabetical:
            return apps.sorted { $0.name < $1.name }
        case .dateAdded:
            return apps.sorted { $0.dateAdded > $1.dateAdded }
        case .developer:
            return apps.sorted { $0.developer < $1.developer }
        }
    }
    
    func clearAllApps() async throws {
        // Cancel all notifications
        notificationService.cancelAllNotifications()
        
        apps.removeAll()
        priceDropsDetected.removeAll()
        lastUpdateTimestamp = nil
        saveApps()
        userDefaults.clearWishlistData()
    }
    
    // MARK: - Helper Methods
    
    func appsNeedingUpdate() -> [WishlistApp] {
        return apps.filter { $0.needsPriceUpdate }
    }
    
    func totalSavings() -> Double {
        return apps.reduce(0) { $0 + $1.discountAmount }
    }
    
    func averageDiscount() -> Double {
        let discountedApps = apps.filter { $0.isOnSale }
        guard !discountedApps.isEmpty else { return 0 }
        
        let totalDiscount = discountedApps.reduce(0) { $0 + $1.discountPercentage }
        return totalDiscount / Double(discountedApps.count)
    }
    
    func exportApps() -> Data? {
        return try? encoder.encode(apps)
    }
    
    func importApps(from data: Data) throws {
        let importedApps = try decoder.decode([WishlistApp].self, from: data)
        
        for app in importedApps {
            if !apps.contains(where: { $0.id == app.id }) {
                apps.append(app)
            }
        }
        
        saveApps()
    }
    
    // MARK: - Price Drop Analysis
    
    func getRecentPriceDrops(within timeInterval: TimeInterval = 86400) -> [WishlistApp] {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        
        return apps.filter { app in
            app.priceHistory.contains { pricePoint in
                pricePoint.date >= cutoffDate &&
                pricePoint.price < app.originalPrice
            }
        }
    }
    
    func getPriceDropStatistics() -> (totalDrops: Int, totalSavings: Double, averageDiscount: Double) {
        let appsOnSale = getAppsOnSale()
        let totalDrops = appsOnSale.count
        let totalSavings = appsOnSale.reduce(0) { $0 + $1.discountAmount }
        let averageDiscount = totalDrops > 0 ? appsOnSale.reduce(0) { $0 + $1.discountPercentage } / Double(totalDrops) : 0
        
        return (totalDrops, totalSavings, averageDiscount)
    }
    
    // MARK: - Notification Integration
    
    func clearPriceDropNotifications() {
        priceDropsDetected.removeAll()
        
        // Clear delivered notifications
        for app in apps {
            notificationService.removeDeliveredNotifications(for: app.id)
        }
    }
    
    func requestNotificationPermissionIfNeeded() async -> Bool {
        let status = await notificationService.getAuthorizationStatus()
        
        if status == .notDetermined {
            return await notificationService.requestPermission()
        }
        
        return status == .authorized
    }
}

// MARK: - Wishlist Errors

enum WishlistError: LocalizedError {
    case appAlreadyExists(String)
    case appNotFound(Int)
    case invalidURL(String)
    case saveFailed
    case loadFailed
    case updateFailed(String)
    case notificationPermissionDenied
    case updateInProgress
    
    var errorDescription: String? {
        switch self {
        case .appAlreadyExists(let name):
            return "\(name) is already in your wishlist"
        case .appNotFound(let id):
            return "App with ID \(id) not found in wishlist"
        case .invalidURL(let url):
            return "Invalid App Store URL: \(url)"
        case .saveFailed:
            return "Failed to save wishlist data"
        case .loadFailed:
            return "Failed to load wishlist data"
        case .updateFailed(let reason):
            return "Failed to update: \(reason)"
        case .notificationPermissionDenied:
            return "Notification permission denied. Enable in Settings to receive price alerts."
        case .updateInProgress:
            return "Price update already in progress"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let wishlistUpdated = Notification.Name("com.wishdirectory.wishlistUpdated")
    static let priceDropDetected = Notification.Name("com.wishdirectory.priceDropDetected")
    static let wishlistCleared = Notification.Name("com.wishdirectory.wishlistCleared")
    static let priceUpdateStarted = Notification.Name("com.wishdirectory.priceUpdateStarted")
    static let priceUpdateCompleted = Notification.Name("com.wishdirectory.priceUpdateCompleted")
}
