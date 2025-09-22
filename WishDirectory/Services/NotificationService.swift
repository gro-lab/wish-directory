//
//  NotificationService.swift
//  WishDirectory
//
//  Created by Sprint 5 Implementation
//

import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service Protocol

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleAppPriceDropNotification(app: WishlistApp, oldPrice: Double, newPrice: Double) async
    func scheduleBatchPriceDropNotifications(priceDrops: [(app: WishlistApp, oldPrice: Double, newPrice: Double)]) async
    func cancelNotification(for appId: Int)
    func cancelAllNotifications()
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    func getPendingNotifications() async -> [UNNotificationRequest]
    func removeDeliveredNotifications(for appId: Int)
}

// MARK: - Notification Service Implementation

@MainActor
class NotificationService: ObservableObject, NotificationServiceProtocol {
    
    // MARK: - Singleton
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isPermissionGranted = false
    @Published private(set) var pendingNotificationsCount = 0
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userSettings = UserSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Notification Identifiers
    private enum NotificationIdentifier {
        static let priceDropPrefix = "price_drop_"
        static let batchPriceDrops = "batch_price_drops"
        static let dailySummary = "daily_summary"
        
        static func priceDropId(for appId: Int) -> String {
            return "\(priceDropPrefix)\(appId)"
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Monitor settings changes
        userSettings.$notificationsEnabled
            .sink { [weak self] enabled in
                if !enabled {
                    Task {
                        await self?.cancelAllNotifications()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor app becoming active to refresh status
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.updateAuthorizationStatus()
                    await self?.updatePendingNotificationsCount()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            
            await updateAuthorizationStatus()
            
            if granted {
                // Register notification categories
                await registerNotificationCategories()
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    private func updateAuthorizationStatus() async {
        let status = await getAuthorizationStatus()
        authorizationStatus = status
        isPermissionGranted = status == .authorized
    }
    
    // MARK: - Price Drop Notifications
    
    func scheduleAppPriceDropNotification(app: WishlistApp, oldPrice: Double, newPrice: Double) async {
        guard isPermissionGranted && userSettings.notificationsEnabled else { return }
        
        // Check if discount meets threshold
        let discountPercentage = ((oldPrice - newPrice) / oldPrice) * 100
        guard userSettings.meetsThreshold(discountPercentage: discountPercentage) else { return }
        
        let identifier = NotificationIdentifier.priceDropId(for: app.id)
        
        // Cancel any existing notification for this app
        cancelNotification(for: app.id)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Price Drop Alert!"
        
        if app.isFree {
            content.body = "\(app.name) is now FREE! Was \(formatPrice(oldPrice, currency: app.currency))"
        } else {
            let savings = oldPrice - newPrice
            content.body = "\(app.name) dropped to \(formatPrice(newPrice, currency: app.currency))! Save \(formatPrice(savings, currency: app.currency)) (\(Int(discountPercentage))% off)"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: await getBadgeCount() + 1)
        content.categoryIdentifier = "PRICE_DROP"
        
        // Add user info for handling tap
        content.userInfo = [
            "appId": app.id,
            "appName": app.name,
            "oldPrice": oldPrice,
            "newPrice": newPrice,
            "savings": oldPrice - newPrice,
            "discountPercentage": discountPercentage,
            "type": "price_drop"
        ]
        
        // Create request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await notificationCenter.add(request)
            await updatePendingNotificationsCount()
        } catch {
            print("Failed to schedule price drop notification: \(error)")
        }
    }
    
    func scheduleBatchPriceDropNotifications(priceDrops: [(app: WishlistApp, oldPrice: Double, newPrice: Double)]) async {
        guard isPermissionGranted && userSettings.notificationsEnabled else { return }
        guard !priceDrops.isEmpty else { return }
        
        if priceDrops.count == 1 {
            // Single app notification
            let drop = priceDrops[0]
            await scheduleAppPriceDropNotification(app: drop.app, oldPrice: drop.oldPrice, newPrice: drop.newPrice)
        } else {
            // Batch notification for multiple apps
            await scheduleBatchSummaryNotification(priceDrops: priceDrops)
        }
    }
    
    private func scheduleBatchSummaryNotification(priceDrops: [(app: WishlistApp, oldPrice: Double, newPrice: Double)]) async {
        let identifier = NotificationIdentifier.batchPriceDrops
        
        // Cancel existing batch notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Multiple Price Drops!"
        
        let totalSavings = priceDrops.reduce(0) { $0 + ($1.oldPrice - $1.newPrice) }
        let currency = priceDrops.first?.app.currency ?? "USD"
        
        content.body = "\(priceDrops.count) apps on sale! Total savings: \(formatPrice(totalSavings, currency: currency))"
        content.sound = .default
        content.badge = NSNumber(value: await getBadgeCount() + 1)
        content.categoryIdentifier = "BATCH_PRICE_DROP"
        
        // Add summary data
        content.userInfo = [
            "type": "batch_price_drop",
            "count": priceDrops.count,
            "totalSavings": totalSavings,
            "appIds": priceDrops.map { $0.app.id }
        ]
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
            await updatePendingNotificationsCount()
        } catch {
            print("Failed to schedule batch notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(for appId: Int) {
        let identifier = NotificationIdentifier.priceDropId(for: appId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        Task {
            await updatePendingNotificationsCount()
        }
    }
    
    func removeDeliveredNotifications(for appId: Int) {
        let identifier = NotificationIdentifier.priceDropId(for: appId)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    private func updatePendingNotificationsCount() async {
        let pending = await getPendingNotifications()
        pendingNotificationsCount = pending.count
    }
    
    // MARK: - Notification Categories
    
    private func registerNotificationCategories() async {
        let priceDropActions = [
            UNNotificationAction(
                identifier: "VIEW_APP",
                title: "View App",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "OPEN_STORE",
                title: "Open in App Store",
                options: [.foreground]
            )
        ]
        
        let batchActions = [
            UNNotificationAction(
                identifier: "VIEW_ALL",
                title: "View All",
                options: [.foreground]
            ),
            UNNotificationAction(
                identifier: "DISMISS",
                title: "Dismiss",
                options: []
            )
        ]
        
        let priceDropCategory = UNNotificationCategory(
            identifier: "PRICE_DROP",
            actions: priceDropActions,
            intentIdentifiers: [],
            options: []
        )
        
        let batchCategory = UNNotificationCategory(
            identifier: "BATCH_PRICE_DROP",
            actions: batchActions,
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([priceDropCategory, batchCategory])
    }
    
    // MARK: - Badge Management
    
    private func getBadgeCount() async -> Int {
        let delivered = await notificationCenter.deliveredNotifications()
        return delivered.count
    }
    
    func clearBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Utility Methods
    
    private func formatPrice(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price, specifier: "%.2f")"
    }
    
    // MARK: - Notification Handling Support
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "price_drop":
            if let appId = userInfo["appId"] as? Int {
                // Post notification to navigate to app detail
                NotificationCenter.default.post(
                    name: .navigateToAppDetail,
                    object: nil,
                    userInfo: ["appId": appId]
                )
            }
            
        case "batch_price_drop":
            // Navigate to wishlist filtered by apps on sale
            NotificationCenter.default.post(
                name: .navigateToWishlistSale,
                object: nil
            )
            
        default:
            break
        }
    }
    
    func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) {
        switch actionIdentifier {
        case "VIEW_APP":
            handleNotificationTap(userInfo: userInfo)
            
        case "OPEN_STORE":
            if let appId = userInfo["appId"] as? Int {
                let storeURL = "https://apps.apple.com/app/id\(appId)"
                if let url = URL(string: storeURL) {
                    UIApplication.shared.open(url)
                }
            }
            
        case "VIEW_ALL":
            NotificationCenter.default.post(
                name: .navigateToWishlistSale,
                object: nil
            )
            
        case "DISMISS":
            // Already handled by system
            break
            
        default:
            break
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let navigateToAppDetail = Notification.Name("com.wishdirectory.navigateToAppDetail")
    static let navigateToWishlistSale = Notification.Name("com.wishdirectory.navigateToWishlistSale")
    static let notificationPermissionChanged = Notification.Name("com.wishdirectory.notificationPermissionChanged")
}

// MARK: - Test Helper Methods

#if DEBUG
extension NotificationService {
    func scheduleTestNotification() async {
        guard isPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test price drop notification"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        try? await notificationCenter.add(request)
    }
    
    func getNotificationSettings() async -> UNNotificationSettings {
        return await notificationCenter.notificationSettings()
    }
}
