//
//  WishlistApp.swift
//  WishDirectory
//
//  Enhanced with Mac App Store Support
//

import Foundation

// MARK: - Main Data Model

struct WishlistApp: Identifiable, Codable, Equatable {
    // MARK: - Core Properties
    
    /// Unique identifier (iTunes trackId)
    let id: Int
    
    /// App name from App Store
    var name: String
    
    /// Developer/Publisher name
    var developer: String
    
    /// URL to app icon (usually 100x100 or 512x512)
    var iconURL: String
    
    /// Direct App Store URL for the app
    var storeURL: String
    
    /// Current price in user's currency
    var currentPrice: Double
    
    /// Original price when first added to wishlist
    let originalPrice: Double
    
    /// Price currency code (USD, EUR, etc.)
    var currency: String
    
    /// Date when app was added to wishlist
    let dateAdded: Date
    
    /// Last time price was checked
    var lastChecked: Date
    
    /// User's personal notes about the app
    var notes: String?
    
    /// Custom user tags for organization
    var tags: [String]
    
    // MARK: - Platform Properties
    
    /// Detected platform (iOS, Mac, or universal)
    var platform: AppPlatform
    
    /// Supported devices (iPhone, iPad, Mac, etc.)
    var supportedDevices: [String]
    
    /// Minimum system requirements
    var minimumSystemVersion: String?
    
    // MARK: - Additional Metadata
    
    /// App Store category
    var category: String?
    
    /// Current version number
    var version: String?
    
    /// Size in bytes
    var sizeInBytes: Int64?
    
    /// Age rating (4+, 9+, 12+, 17+)
    var ageRating: String?
    
    /// Average user rating (0-5)
    var averageRating: Double?
    
    /// Total number of ratings
    var ratingCount: Int?
    
    /// Bundle identifier
    var bundleId: String?
    
    /// Release date of current version
    var releaseDate: Date?
    
    /// Formatted price for the current locale
    var formattedPrice: String?
    
    /// Historical prices for tracking
    var priceHistory: [PricePoint]
    
    /// Screenshots URLs
    var screenshots: [String]
    
    /// App description
    var description: String
    
    // MARK: - Computed Properties
    
    /// Calculate if the app is currently on sale
    var isOnSale: Bool {
        return currentPrice < originalPrice && currentPrice >= 0
    }
    
    /// Calculate the discount amount
    var discountAmount: Double {
        guard isOnSale else { return 0 }
        return originalPrice - currentPrice
    }
    
    /// Calculate the discount percentage
    var discountPercentage: Double {
        guard originalPrice > 0 && isOnSale else { return 0 }
        return ((originalPrice - currentPrice) / originalPrice) * 100
    }
    
    /// Check if the app is free
    var isFree: Bool {
        return currentPrice == 0
    }
    
    /// Check if the app was free when added
    var wasOriginallyFree: Bool {
        return originalPrice == 0
    }
    
    /// Check if this is a significant price drop (>= threshold)
    func isSignificantDrop(threshold: Double) -> Bool {
        return discountPercentage >= threshold
    }
    
    /// Get formatted discount percentage string
    var formattedDiscountPercentage: String {
        guard isOnSale else { return "" }
        return "-\(Int(discountPercentage))%"
    }
    
    /// Get time since last price check
    var timeSinceLastCheck: TimeInterval {
        return Date().timeIntervalSince(lastChecked)
    }
    
    /// Check if price data is stale (> 24 hours)
    var needsPriceUpdate: Bool {
        return timeSinceLastCheck > 86400 // 24 hours in seconds
    }
    
    /// Get a display-friendly size string
    var formattedSize: String? {
        guard let sizeInBytes = sizeInBytes else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: sizeInBytes)
    }
    
    /// Get best available icon URL (prefer larger size)
    var bestIconURL: String {
        // Replace 100x100 with 512x512 for better quality
        return iconURL.replacingOccurrences(of: "100x100", with: "512x512")
    }
    
    // MARK: - Platform-Specific Properties
    
    /// Check if app is compatible with iOS devices
    var isIOSCompatible: Bool {
        return platform == .ios || platform == .all || supportedDevices.contains { device in
            let lowercased = device.lowercased()
            return lowercased.contains("iphone") ||
                   lowercased.contains("ipad") ||
                   lowercased.contains("ipod")
        }
    }
    
    /// Check if app is compatible with Mac
    var isMacCompatible: Bool {
        return platform == .mac || platform == .all || supportedDevices.contains { device in
            device.lowercased().contains("mac")
        }
    }
    
    /// Get platform-specific display name
    var platformDisplayName: String {
        switch platform {
        case .ios:
            if isIOSCompatible && isMacCompatible {
                return "Universal"
            } else {
                return "iOS"
            }
        case .mac:
            return "macOS"
        case .all:
            return "Universal"
        }
    }
    
    /// Get platform-specific icon for UI
    var platformIcon: String {
        switch platform {
        case .ios:
            return "iphone"
        case .mac:
            return "desktopcomputer"
        case .all:
            return "apps.iphone.badge.plus"
        }
    }
    
    /// Get appropriate store URL for the platform
    var platformStoreURL: String {
        guard let url = URL(string: storeURL) else { return storeURL }
        
        if let convertedURL = url.convertToPlatform(platform) {
            return convertedURL.absoluteString
        }
        
        return storeURL
    }
    
    /// Get appropriate deep link URL
    var platformDeepLinkURL: String? {
        guard let url = URL(string: storeURL),
              let appId = url.extractAppStoreId() else { return nil }
        
        return URL.platformDeepLink(for: appId, platform: platform)?.absoluteString
    }
    
    /// Get minimum system requirement display text
    var minimumSystemDisplayText: String? {
        guard let version = minimumSystemVersion else { return nil }
        
        switch platform {
        case .ios:
            return "iOS \(version)+"
        case .mac:
            return "macOS \(version)+"
        case .all:
            return "iOS/macOS \(version)+"
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: Int,
        name: String,
        developer: String,
        iconURL: String,
        storeURL: String,
        currentPrice: Double,
        originalPrice: Double? = nil,
        currency: String = "USD",
        platform: AppPlatform = .ios,
        supportedDevices: [String] = [],
        minimumSystemVersion: String? = nil,
        dateAdded: Date? = nil,
        lastChecked: Date? = nil,
        notes: String? = nil,
        tags: [String] = [],
        category: String? = nil,
        version: String? = nil,
        sizeInBytes: Int64? = nil,
        ageRating: String? = nil,
        averageRating: Double? = nil,
        ratingCount: Int? = nil,
        bundleId: String? = nil,
        releaseDate: Date? = nil,
        formattedPrice: String? = nil,
        priceHistory: [PricePoint]? = nil,
        screenshots: [String] = [],
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.developer = developer
        self.iconURL = iconURL
        self.storeURL = storeURL
        self.currentPrice = currentPrice
        self.originalPrice = originalPrice ?? currentPrice
        self.currency = currency
        self.platform = platform
        self.supportedDevices = supportedDevices
        self.minimumSystemVersion = minimumSystemVersion
        self.dateAdded = dateAdded ?? Date()
        self.lastChecked = lastChecked ?? Date()
        self.notes = notes
        self.tags = tags
        self.category = category
        self.version = version
        self.sizeInBytes = sizeInBytes
        self.ageRating = ageRating
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.bundleId = bundleId
        self.releaseDate = releaseDate
        self.formattedPrice = formattedPrice
        self.screenshots = screenshots
        self.description = description
        
        // Initialize price history with current price if not provided
        if let history = priceHistory {
            self.priceHistory = history
        } else {
            self.priceHistory = [PricePoint(price: currentPrice, date: Date(), formattedPrice: formattedPrice)]
        }
    }
    
    // MARK: - Convenience Initializer from iTunes API
    
    init(from iTunesApp: iTunesApp) {
        self.init(
            id: iTunesApp.trackId,
            name: iTunesApp.trackName,
            developer: iTunesApp.artistName,
            iconURL: iTunesApp.platformIconURL ?? "",
            storeURL: iTunesApp.platformStoreURL,
            currentPrice: iTunesApp.price ?? 0,
            originalPrice: iTunesApp.price ?? 0,
            currency: iTunesApp.currency,
            platform: iTunesApp.detectedPlatform,
            supportedDevices: iTunesApp.supportedDevices ?? [],
            minimumSystemVersion: iTunesApp.minimumSystemRequirement,
            category: iTunesApp.primaryGenreName,
            version: iTunesApp.version,
            sizeInBytes: Int64(iTunesApp.fileSizeBytes ?? "0") ?? 0,
            ageRating: iTunesApp.contentAdvisoryRating,
            averageRating: iTunesApp.averageUserRating,
            ratingCount: iTunesApp.userRatingCount,
            bundleId: iTunesApp.bundleId,
            releaseDate: ISO8601DateFormatter().date(from: iTunesApp.currentVersionReleaseDate ?? ""),
            formattedPrice: iTunesApp.formattedPrice,
            screenshots: iTunesApp.allScreenshots,
            description: iTunesApp.description ?? ""
        )
    }
    
    // MARK: - Methods
    
    /// Update the current price and add to history
    mutating func updatePrice(_ newPrice: Double, formattedPrice: String? = nil) {
        // Only add to history if price actually changed
        if newPrice != currentPrice {
            currentPrice = newPrice
            self.formattedPrice = formattedPrice
            
            let pricePoint = PricePoint(
                price: newPrice,
                date: Date(),
                formattedPrice: formattedPrice
            )
            priceHistory.append(pricePoint)
            
            // Limit history to last 30 price points
            if priceHistory.count > 30 {
                priceHistory.removeFirst(priceHistory.count - 30)
            }
        }
        
        lastChecked = Date()
    }
    
    /// Add a tag to the app
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
        }
    }
    
    /// Remove a tag from the app
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    /// Update notes for the app
    mutating func updateNotes(_ newNotes: String?) {
        notes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        if notes?.isEmpty == true {
            notes = nil
        }
    }
    
    /// Get lowest historical price
    func lowestPrice() -> Double? {
        return priceHistory.min(by: { $0.price < $1.price })?.price
    }
    
    /// Get highest historical price
    func highestPrice() -> Double? {
        return priceHistory.max(by: { $0.price < $1.price })?.price
    }
    
    /// Check if app has ever been free
    func hasBeenFree() -> Bool {
        return priceHistory.contains { $0.price == 0 }
    }
    
    /// Update platform based on supported devices or URL
    mutating func updatePlatform() {
        if let url = URL(string: storeURL) {
            self.platform = url.detectedPlatform
        } else {
            // Detect from supported devices
            let hasIOS = supportedDevices.contains { device in
                let lowercased = device.lowercased()
                return lowercased.contains("iphone") ||
                       lowercased.contains("ipad") ||
                       lowercased.contains("ipod")
            }
            
            let hasMac = supportedDevices.contains { device in
                device.lowercased().contains("mac")
            }
            
            if hasIOS && hasMac {
                self.platform = .all
            } else if hasMac {
                self.platform = .mac
            } else {
                self.platform = .ios
            }
        }
    }
}

// MARK: - Price History Point

struct PricePoint: Codable, Equatable {
    let price: Double
    let date: Date
    let formattedPrice: String?
    
    init(price: Double, date: Date, formattedPrice: String? = nil) {
        self.price = price
        self.date = date
        self.formattedPrice = formattedPrice
    }
}

// MARK: - Comparable Extension

extension WishlistApp: Comparable {
    static func < (lhs: WishlistApp, rhs: WishlistApp) -> Bool {
        // Sort by discount percentage by default
        if lhs.discountPercentage != rhs.discountPercentage {
            return lhs.discountPercentage > rhs.discountPercentage
        }
        // Then by name
        return lhs.name < rhs.name
    }
}

// MARK: - Platform Filtering Extensions

extension Array where Element == WishlistApp {
    /// Filter apps by platform
    func filtered(by platform: AppPlatform) -> [WishlistApp] {
        switch platform {
        case .ios:
            return filter { $0.isIOSCompatible }
        case .mac:
            return filter { $0.isMacCompatible }
        case .all:
            return self
        }
    }
    
    /// Group apps by platform
    func groupedByPlatform() -> [AppPlatform: [WishlistApp]] {
        var grouped: [AppPlatform: [WishlistApp]] = [:]
        
        for app in self {
            let platform = app.platform
            if grouped[platform] == nil {
                grouped[platform] = []
            }
            grouped[platform]?.append(app)
        }
        
        return grouped
    }
    
    /// Get platform statistics
    func platformStatistics() -> (ios: Int, mac: Int, universal: Int) {
        var ios = 0, mac = 0, universal = 0
        
        for app in self {
            if app.isIOSCompatible && app.isMacCompatible {
                universal += 1
            } else if app.isMacCompatible {
                mac += 1
            } else {
                ios += 1
            }
        }
        
        return (ios, mac, universal)
    }
}

// MARK: - Mock Data for Testing

#if DEBUG
extension WishlistApp {
    static var mockApp: WishlistApp {
        WishlistApp(
            id: 1234567890,
            name: "Example iOS App",
            developer: "Example Developer",
            iconURL: "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/example.jpg",
            storeURL: "https://apps.apple.com/us/app/example-app/id1234567890",
            currentPrice: 2.99,
            originalPrice: 4.99,
            currency: "USD",
            platform: .ios,
            supportedDevices: ["iPhone", "iPad"],
            minimumSystemVersion: "15.0",
            dateAdded: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            lastChecked: Date(),
            notes: "Great productivity app",
            tags: ["Productivity", "Favorite"],
            category: "Productivity",
            version: "2.1.0",
            sizeInBytes: 45_678_901,
            ageRating: "4+",
            averageRating: 4.5,
            ratingCount: 1234,
            bundleId: "com.example.app",
            releaseDate: Date().addingTimeInterval(-86400 * 30),
            formattedPrice: "$2.99",
            screenshots: [
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/screenshot1.png",
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/screenshot2.png"
            ],
            description: "This is an example iOS app for productivity and task management."
        )
    }
    
    static var mockMacApp: WishlistApp {
        WishlistApp(
            id: 987654321,
            name: "Example Mac App",
            developer: "Mac Developer",
            iconURL: "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/mac-example.jpg",
            storeURL: "https://apps.apple.com/us/app/mac-example-app/id987654321?mt=12",
            currentPrice: 19.99,
            originalPrice: 29.99,
            currency: "USD",
            platform: .mac,
            supportedDevices: ["Mac"],
            minimumSystemVersion: "12.0",
            category: "Developer Tools",
            version: "3.0.0",
            sizeInBytes: 250_000_000,
            averageRating: 4.8,
            ratingCount: 567,
            bundleId: "com.example.macapp",
            screenshots: [
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/mac-screenshot1.png"
            ],
            description: "Professional development tool for macOS with advanced features."
        )
    }
    
    static var mockUniversalApp: WishlistApp {
        WishlistApp(
            id: 555666777,
            name: "Universal App",
            developer: "Universal Developer",
            iconURL: "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/universal.jpg",
            storeURL: "https://apps.apple.com/us/app/universal-app/id555666777",
            currentPrice: 0.99,
            originalPrice: 9.99,
            currency: "USD",
            platform: .all,
            supportedDevices: ["iPhone", "iPad", "Mac"],
            minimumSystemVersion: "15.0",
            category: "Photo & Video",
            version: "4.1.2",
            averageRating: 4.9,
            ratingCount: 8901,
            screenshots: [
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/universal1.png",
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/universal2.png",
                "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/universal3.png"
            ],
            description: "A powerful universal app that works seamlessly across iPhone, iPad, and Mac.",
            priceHistory: [
                PricePoint(price: 9.99, date: Date().addingTimeInterval(-86400 * 30)),
                PricePoint(price: 7.99, date: Date().addingTimeInterval(-86400 * 15)),
                PricePoint(price: 4.99, date: Date().addingTimeInterval(-86400 * 7)),
                PricePoint(price: 0.99, date: Date())
            ]
        )
    }
}
#endif
