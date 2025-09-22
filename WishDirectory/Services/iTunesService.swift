//
//  iTunesService.swift
//  WishDirectory
//
//  Enhanced with Mac App Store Support
//

import Foundation
import Combine

// MARK: - iTunes Service Protocol

protocol iTunesServiceProtocol {
    func searchApps(term: String, platform: AppPlatform, country: String?, limit: Int) async throws -> [iTunesApp]
    func searchAllApps(term: String, country: String?, limit: Int) async throws -> [iTunesApp]
    func lookupApp(by id: String, country: String?) async throws -> iTunesApp
    func lookupMultipleApps(ids: [String], country: String?) async throws -> [iTunesApp]
    func getTopApps(platform: AppPlatform, category: String?, country: String?, limit: Int) async throws -> [iTunesApp]
}

// MARK: - iTunes Service Implementation

class iTunesService: iTunesServiceProtocol {
    
    // MARK: - Singleton
    static let shared = iTunesService()
    
    // MARK: - Properties
    private let baseURL = "https://itunes.apple.com"
    private let session: URLSession
    private let decoder: JSONDecoder
    private var cancellables = Set<AnyCancellable>()
    
    // Rate limiting properties
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 3.0 // 3 seconds between requests
    private let requestQueue = DispatchQueue(label: "com.wishdirectory.itunesservice", attributes: .concurrent)
    private let requestSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: - Initialization
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Methods
    
    func searchApps(term: String, platform: AppPlatform = .all, country: String? = nil, limit: Int = 50) async throws -> [iTunesApp] {
        let countryCode = country ?? UserSettings.shared.preferredRegion
        
        var allResults: [iTunesApp] = []
        
        // Search each entity separately for better results
        for entity in platform.entities {
            var components = URLComponents(string: "\(baseURL)/search")!
            components.queryItems = [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "country", value: countryCode),
                URLQueryItem(name: "entity", value: entity),
                URLQueryItem(name: "limit", value: String(min(limit, 200)))
            ]
            
            guard let url = components.url else {
                throw iTunesError.invalidURL
            }
            
            let response: iTunesSearchResponse = try await performRequest(url: url)
            allResults.append(contentsOf: response.results)
        }
        
        // Remove duplicates and limit results
        let uniqueResults = Array(Set(allResults)).prefix(limit)
        return Array(uniqueResults)
    }
    
    func searchAllApps(term: String, country: String? = nil, limit: Int = 50) async throws -> [iTunesApp] {
        return try await searchApps(term: term, platform: .all, country: country, limit: limit)
    }
    
    func lookupApp(by id: String, country: String? = nil) async throws -> iTunesApp {
        let countryCode = country ?? UserSettings.shared.preferredRegion
        
        var components = URLComponents(string: "\(baseURL)/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "country", value: countryCode)
        ]
        
        guard let url = components.url else {
            throw iTunesError.invalidURL
        }
        
        let response: iTunesLookupResponse = try await performRequest(url: url)
        
        guard let app = response.results.first else {
            throw iTunesError.appNotFound(id)
        }
        
        return app
    }
    
    func lookupMultipleApps(ids: [String], country: String? = nil) async throws -> [iTunesApp] {
        guard !ids.isEmpty else { return [] }
        
        let countryCode = country ?? UserSettings.shared.preferredRegion
        let idsString = ids.joined(separator: ",")
        
        var components = URLComponents(string: "\(baseURL)/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: idsString),
            URLQueryItem(name: "country", value: countryCode)
        ]
        
        guard let url = components.url else {
            throw iTunesError.invalidURL
        }
        
        let response: iTunesLookupResponse = try await performRequest(url: url)
        return response.results
    }
    
    func getTopApps(platform: AppPlatform = .all, category: String? = nil, country: String? = nil, limit: Int = 100) async throws -> [iTunesApp] {
        // Note: This would typically use RSS feeds for top charts
        // For now, we'll search for popular terms as a placeholder
        let searchTerm = category ?? "app"
        return try await searchApps(term: searchTerm, platform: platform, country: country, limit: limit)
    }
    
    // MARK: - Platform Detection
    
    func detectPlatform(for app: iTunesApp) -> AppPlatform {
        // Check supported devices for platform detection
        if let supportedDevices = app.supportedDevices {
            let hasIOSDevices = supportedDevices.contains { device in
                device.lowercased().contains("iphone") ||
                device.lowercased().contains("ipad") ||
                device.lowercased().contains("ipod")
            }
            
            let hasMacDevices = supportedDevices.contains { device in
                device.lowercased().contains("mac")
            }
            
            if hasIOSDevices && !hasMacDevices {
                return .ios
            } else if hasMacDevices && !hasIOSDevices {
                return .mac
            }
        }
        
        // Fallback: Check bundle ID patterns
        if let bundleId = app.bundleId {
            if bundleId.contains("mac") || bundleId.contains("osx") {
                return .mac
            }
        }
        
        // Check file size (Mac apps are typically larger)
        if let sizeString = app.fileSizeBytes,
           let sizeBytes = Int64(sizeString),
           sizeBytes > 500_000_000 { // 500MB threshold
            return .mac
        }
        
        // Default to iOS if uncertain
        return .ios
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        // Rate limiting
        try await enforceRateLimit()
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw iTunesError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    return decoded
                } catch {
                    print("Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Response data: \(jsonString.prefix(500))")
                    }
                    throw iTunesError.decodingError(error)
                }
            case 400:
                throw iTunesError.badRequest
            case 403:
                throw iTunesError.rateLimited
            case 404:
                throw iTunesError.notFound
            case 500...599:
                throw iTunesError.serverError(httpResponse.statusCode)
            default:
                throw iTunesError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch {
            if error is iTunesError {
                throw error
            }
            throw iTunesError.networkError(error)
        }
    }
    
    private func enforceRateLimit() async throws {
        requestSemaphore.wait()
        defer { requestSemaphore.signal() }
        
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < minRequestInterval {
                let waitTime = minRequestInterval - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        
        lastRequestTime = Date()
    }
}

// MARK: - Data Models

struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [iTunesApp]
}

struct iTunesLookupResponse: Codable {
    let resultCount: Int
    let results: [iTunesApp]
}

struct iTunesApp: Codable, Hashable {
    let trackId: Int
    let trackName: String
    let trackViewUrl: String
    let artistId: Int?
    let artistName: String
    let artistViewUrl: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
    let price: Double?
    let formattedPrice: String?
    let currency: String
    let bundleId: String?
    let version: String?
    let primaryGenreName: String?
    let primaryGenreId: Int?
    let genreIds: [String]?
    let genres: [String]?
    let releaseDate: String?
    let currentVersionReleaseDate: String?
    let description: String?
    let sellerName: String?
    let fileSizeBytes: String?
    let minimumOsVersion: String?
    let averageUserRating: Double?
    let averageUserRatingForCurrentVersion: Double?
    let userRatingCount: Int?
    let userRatingCountForCurrentVersion: Int?
    let contentAdvisoryRating: String?
    let languageCodesISO2A: [String]?
    let screenshotUrls: [String]?
    let ipadScreenshotUrls: [String]?
    let appletvScreenshotUrls: [String]?
    let supportedDevices: [String]?
    let features: [String]?
    let advisories: [String]?
    let isVppDeviceBasedLicensingEnabled: Bool?
    let releaseNotes: String?
    let sellerUrl: String?
    let trackContentRating: String?
    
    // Mac-specific properties
    let macOSVersion: String?
    let macOSRequired: String?
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(trackId)
    }
    
    static func == (lhs: iTunesApp, rhs: iTunesApp) -> Bool {
        return lhs.trackId == rhs.trackId
    }
}

// MARK: - iTunes Errors

enum iTunesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case appNotFound(String)
    case notFound
    case badRequest
    case rateLimited
    case serverError(Int)
    case unexpectedStatusCode(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid iTunes API URL"
        case .invalidResponse:
            return "Invalid response from iTunes API"
        case .decodingError(let error):
            return "Failed to decode iTunes response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .appNotFound(let id):
            return "App with ID \(id) not found"
        case .notFound:
            return "Resource not found"
        case .badRequest:
            return "Invalid request to iTunes API"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later"
        case .serverError(let code):
            return "iTunes server error (code: \(code))"
        case .unexpectedStatusCode(let code):
            return "Unexpected response code: \(code)"
        }
    }
}

// MARK: - Convenience Extensions

extension iTunesApp {
    /// Get the best available artwork URL
    var bestArtworkUrl: String? {
        return artworkUrl512 ?? artworkUrl100 ?? artworkUrl60
    }
    
    /// Check if the app is free
    var isFree: Bool {
        return price == nil || price == 0
    }
    
    /// Get formatted file size
    var formattedFileSize: String? {
        guard let sizeString = fileSizeBytes,
              let sizeBytes = Int64(sizeString) else { return nil }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: sizeBytes)
    }
    
    /// Get all screenshot URLs
    var allScreenshots: [String] {
        var screenshots: [String] = []
        if let urls = screenshotUrls {
            screenshots.append(contentsOf: urls)
        }
        if let urls = ipadScreenshotUrls {
            screenshots.append(contentsOf: urls)
        }
        return screenshots
    }
    
    /// Detect platform based on app properties
    var detectedPlatform: AppPlatform {
        return iTunesService.shared.detectPlatform(for: self)
    }
    
    /// Check if app is compatible with macOS
    var isMacCompatible: Bool {
        if let supportedDevices = supportedDevices {
            return supportedDevices.contains { device in
                device.lowercased().contains("mac")
            }
        }
        return detectedPlatform == .mac
    }
    
    /// Check if app is compatible with iOS
    var isIOSCompatible: Bool {
        if let supportedDevices = supportedDevices {
            return supportedDevices.contains { device in
                let lowercased = device.lowercased()
                return lowercased.contains("iphone") ||
                       lowercased.contains("ipad") ||
                       lowercased.contains("ipod")
            }
        }
        return detectedPlatform == .ios
    }
    
    /// Get minimum system requirement
    var minimumSystemRequirement: String? {
        if isMacCompatible {
            return macOSVersion ?? macOSRequired
        } else {
            return minimumOsVersion
        }
    }
    
    /// Get platform-specific store URL
    var platformStoreURL: String {
        if isMacCompatible && !isIOSCompatible {
            // Mac App Store URL
            return trackViewUrl.replacingOccurrences(of: "apps.apple.com", with: "apps.apple.com")
        } else {
            // iOS App Store URL
            return trackViewUrl
        }
    }
    
    /// Get appropriate icon size for platform
    var platformIconURL: String? {
        if isMacCompatible && !isIOSCompatible {
            // Mac apps often have higher resolution icons
            return artworkUrl512 ?? artworkUrl100 ?? artworkUrl60
        } else {
            // iOS apps
            return artworkUrl100 ?? artworkUrl512 ?? artworkUrl60
        }
    }
}

// MARK: - Platform Filtering Extensions

extension Array where Element == iTunesApp {
    /// Filter apps by platform
    func filtered(by platform: AppPlatform) -> [iTunesApp] {
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
    func groupedByPlatform() -> [AppPlatform: [iTunesApp]] {
        var grouped: [AppPlatform: [iTunesApp]] = [:]
        
        for app in self {
            let platform = app.detectedPlatform
            if grouped[platform] == nil {
                grouped[platform] = []
            }
            grouped[platform]?.append(app)
        }
        
        return grouped
    }
}

// MARK: - Search Filters

struct AppSearchFilters {
    var platform: AppPlatform = .all
    var priceRange: ClosedRange<Double> = 0...1000
    var minimumRating: Double = 0
    var categories: [String] = []
    var isFreeOnly: Bool = false
    var isPaidOnly: Bool = false
    
    func apply(to apps: [iTunesApp]) -> [iTunesApp] {
        return apps.filter { app in
            // Platform filter
            let platformMatch: Bool
            switch platform {
            case .ios:
                platformMatch = app.isIOSCompatible
            case .mac:
                platformMatch = app.isMacCompatible
            case .all:
                platformMatch = true
            }
            
            // Price filter
            let price = app.price ?? 0
            let priceMatch = priceRange.contains(price)
            
            // Rating filter
            let rating = app.averageUserRating ?? 0
            let ratingMatch = rating >= minimumRating
            
            // Category filter
            let categoryMatch = categories.isEmpty ||
                categories.contains(app.primaryGenreName ?? "")
            
            // Free/Paid filter
            let freeMatch: Bool
            if isFreeOnly {
                freeMatch = app.isFree
            } else if isPaidOnly {
                freeMatch = !app.isFree
            } else {
                freeMatch = true
            }
            
            return platformMatch && priceMatch && ratingMatch && categoryMatch && freeMatch
        }
    }
}
