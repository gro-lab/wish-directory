//
//  URL+AppStore.swift
//  WishDirectory
//
//  Enhanced with Mac App Store Support
//

import Foundation

// MARK: - URL Extension for App Store

extension URL {
    
    /// Extract app ID from various App Store URL formats (iOS and Mac)
    func extractAppStoreId() -> Int? {
        // Handle different URL schemes and formats
        let urlString = self.absoluteString.lowercased()
        
        // Remove any URL parameters
        let cleanUrl = urlString.components(separatedBy: "?").first ?? urlString
        
        // iOS App Store patterns:
        // Pattern 1: apps.apple.com/[country]/app/[app-name]/id[number]
        // Pattern 2: apps.apple.com/app/id[number]
        // Pattern 3: itunes.apple.com/[country]/app/[app-name]/id[number]
        // Pattern 4: itunes.apple.com/app/id[number]
        // Pattern 5: apps.apple.com/app/[app-name]/id[number]
        // Pattern 6: itms-apps://itunes.apple.com/app/id[number]
        
        // Mac App Store patterns:
        // Pattern 7: apps.apple.com/[country]/app/[app-name]/id[number]?mt=12
        // Pattern 8: itunes.apple.com/[country]/app/[app-name]/id[number]?mt=12
        // Pattern 9: macappstore://itunes.apple.com/app/id[number]
        // Pattern 10: itms-apps://itunes.apple.com/app/id[number]?mt=12
        
        // Extract ID using regex pattern
        let pattern = #"id(\d+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let nsString = cleanUrl as NSString
            let matches = regex.matches(in: cleanUrl, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let idRange = match.range(at: 1)
                let idString = nsString.substring(with: idRange)
                return Int(idString)
            }
        }
        
        // Fallback: Try to parse from path components
        return extractAppIdFromPathComponents()
    }
    
    /// Extract app ID from path components
    private func extractAppIdFromPathComponents() -> Int? {
        for component in pathComponents {
            // Look for components starting with "id"
            if component.hasPrefix("id") {
                let idString = component.dropFirst(2) // Remove "id" prefix
                if let appId = Int(idString) {
                    return appId
                }
            }
            
            // Also check for pure numeric components after "app"
            if let appId = Int(component), appId > 0 {
                // Verify this looks like a valid app ID (typically 9-10 digits)
                let idString = String(appId)
                if idString.count >= 8 && idString.count <= 12 {
                    return appId
                }
            }
        }
        
        return nil
    }
    
    /// Check if URL is a valid App Store URL (iOS or Mac)
    var isAppStoreURL: Bool {
        let host = self.host?.lowercased() ?? ""
        let validHosts = [
            "apps.apple.com",
            "itunes.apple.com",
            "geo.itunes.apple.com",
            "beta.itunes.apple.com"
        ]
        
        // Check for direct hosts
        if validHosts.contains(host) {
            return true
        }
        
        // Check for iOS app schemes
        if self.scheme == "itms-apps" || self.scheme == "itms" {
            return true
        }
        
        // Check for Mac App Store scheme
        if self.scheme == "macappstore" {
            return true
        }
        
        // Check for appstore scheme
        if self.scheme == "appstore" {
            return true
        }
        
        return false
    }
    
    /// Detect if URL is for Mac App Store
    var isMacAppStoreURL: Bool {
        let urlString = self.absoluteString.lowercased()
        
        // Check for Mac App Store scheme
        if self.scheme == "macappstore" {
            return true
        }
        
        // Check for mt=12 parameter (Mac App Store indicator)
        if urlString.contains("mt=12") {
            return true
        }
        
        // Check for mac-specific paths
        if urlString.contains("/mac/") {
            return true
        }
        
        return false
    }
    
    /// Detect if URL is for iOS App Store
    var isIOSAppStoreURL: Bool {
        return isAppStoreURL && !isMacAppStoreURL
    }
    
    /// Detect platform from URL
    var detectedPlatform: AppPlatform {
        if isMacAppStoreURL {
            return .mac
        } else if isIOSAppStoreURL {
            return .ios
        } else {
            return .all
        }
    }
    
    /// Generate iTunes lookup URL from app ID
    static func iTunesLookupURL(for appId: Int, country: String = "US") -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: String(appId)),
            URLQueryItem(name: "country", value: country)
        ]
        return components?.url
    }
    
    /// Generate iOS App Store URL from app ID
    static func iOSAppStoreURL(for appId: Int, country: String = "US") -> URL? {
        return URL(string: "https://apps.apple.com/\(country.lowercased())/app/id\(appId)")
    }
    
    /// Generate Mac App Store URL from app ID
    static func macAppStoreURL(for appId: Int, country: String = "US") -> URL? {
        return URL(string: "https://apps.apple.com/\(country.lowercased())/app/id\(appId)?mt=12")
    }
    
    /// Generate platform-specific App Store URL
    static func appStoreURL(for appId: Int, platform: AppPlatform, country: String = "US") -> URL? {
        switch platform {
        case .ios:
            return iOSAppStoreURL(for: appId, country: country)
        case .mac:
            return macAppStoreURL(for: appId, country: country)
        case .all:
            return iOSAppStoreURL(for: appId, country: country) // Default to iOS
        }
    }
    
    /// Generate App Store deep link for opening in App Store app (iOS only)
    static func appStoreDeepLink(for appId: Int) -> URL? {
        return URL(string: "itms-apps://itunes.apple.com/app/id\(appId)")
    }
    
    /// Generate Mac App Store deep link
    static func macAppStoreDeepLink(for appId: Int) -> URL? {
        return URL(string: "macappstore://itunes.apple.com/app/id\(appId)")
    }
    
    /// Generate platform-specific deep link
    static func platformDeepLink(for appId: Int, platform: AppPlatform) -> URL? {
        switch platform {
        case .ios:
            return appStoreDeepLink(for: appId)
        case .mac:
            return macAppStoreDeepLink(for: appId)
        case .all:
            return appStoreDeepLink(for: appId) // Default to iOS
        }
    }
    
    /// Extract country code from App Store URL
    func extractCountryCode() -> String? {
        let components = pathComponents
        
        // Look for 2-letter country codes in path
        for component in components {
            if component.count == 2 && component.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil {
                return component.uppercased()
            }
        }
        
        // Check query parameters
        if let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                if item.name == "country" || item.name == "ct" {
                    return item.value?.uppercased()
                }
            }
        }
        
        return nil
    }
    
    /// Convert between iOS and Mac App Store URLs
    func convertToPlatform(_ platform: AppPlatform) -> URL? {
        guard let appId = extractAppStoreId() else { return nil }
        let country = extractCountryCode() ?? "US"
        
        return URL.appStoreURL(for: appId, platform: platform, country: country)
    }
}

// MARK: - String Extension for URL Validation

extension String {
    
    /// Check if string is a valid App Store URL (iOS or Mac)
    var isValidAppStoreURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isAppStoreURL
    }
    
    /// Check if string is a valid Mac App Store URL
    var isValidMacAppStoreURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isMacAppStoreURL
    }
    
    /// Check if string is a valid iOS App Store URL
    var isValidIOSAppStoreURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.isIOSAppStoreURL
    }
    
    /// Extract app ID from App Store URL string
    func extractAppStoreId() -> Int? {
        guard let url = URL(string: self) else { return nil }
        return url.extractAppStoreId()
    }
    
    /// Detect platform from URL string
    var detectedPlatform: AppPlatform {
        guard let url = URL(string: self) else { return .all }
        return url.detectedPlatform
    }
    
    /// Clean and validate App Store URL
    func cleanAppStoreURL() -> String? {
        var urlString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle common user input mistakes
        
        // Remove common prefixes users might add
        let prefixesToRemove = ["www.", "http://", "https://"]
        for prefix in prefixesToRemove {
            if urlString.lowercased().hasPrefix(prefix) && !urlString.hasPrefix("https://") {
                urlString = String(urlString.dropFirst(prefix.count))
            }
        }
        
        // Add https:// if no scheme is present
        if !urlString.contains("://") {
            urlString = "https://" + urlString
        }
        
        // Validate the URL
        guard let url = URL(string: urlString), url.isAppStoreURL else {
            return nil
        }
        
        return url.absoluteString
    }
    
    /// Create iOS App Store search URL
    static func iOSAppStoreSearchURL(for term: String, country: String = "US") -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        let cleanTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        components?.queryItems = [
            URLQueryItem(name: "term", value: cleanTerm),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        return components?.url
    }
    
    /// Create Mac App Store search URL
    static func macAppStoreSearchURL(for term: String, country: String = "US") -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        let cleanTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        components?.queryItems = [
            URLQueryItem(name: "term", value: cleanTerm),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "entity", value: "macSoftware"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        return components?.url
    }
    
    /// Create platform-specific search URL
    static func appStoreSearchURL(for term: String, platform: AppPlatform, country: String = "US") -> URL? {
        switch platform {
        case .ios:
            return iOSAppStoreSearchURL(for: term, country: country)
        case .mac:
            return macAppStoreSearchURL(for: term, country: country)
        case .all:
            return iOSAppStoreSearchURL(for: term, country: country) // Default to iOS search
        }
    }
}

// MARK: - URL Scheme Handlers

extension URL {
    
    /// Handle App Store URL schemes for deep linking
    static func handleAppStoreScheme(_ url: URL) -> Bool {
        if url.scheme == "wishdirectory" {
            // Handle custom URL scheme for the app
            if url.host == "add" {
                // Handle add app action
                if let appIdString = url.pathComponents.last,
                   let appId = Int(appIdString) {
                    // Trigger add app with ID
                    NotificationCenter.default.post(
                        name: .addAppFromDeepLink,
                        object: nil,
                        userInfo: [
                            "appId": appId,
                            "platform": url.detectedPlatform.rawValue
                        ]
                    )
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let addAppFromDeepLink = Notification.Name("com.wishdirectory.addAppFromDeepLink")
}

// MARK: - App Store Region Codes

struct AppStoreRegions {
    static let availableRegions: [String: String] = [
        "US": "United States",
        "GB": "United Kingdom",
        "CA": "Canada",
        "AU": "Australia",
        "DE": "Germany",
        "FR": "France",
        "IT": "Italy",
        "ES": "Spain",
        "NL": "Netherlands",
        "SE": "Sweden",
        "NO": "Norway",
        "DK": "Denmark",
        "FI": "Finland",
        "CH": "Switzerland",
        "AT": "Austria",
        "BE": "Belgium",
        "IE": "Ireland",
        "PT": "Portugal",
        "GR": "Greece",
        "PL": "Poland",
        "CZ": "Czech Republic",
        "HU": "Hungary",
        "RO": "Romania",
        "BG": "Bulgaria",
        "HR": "Croatia",
        "SI": "Slovenia",
        "SK": "Slovakia",
        "EE": "Estonia",
        "LV": "Latvia",
        "LT": "Lithuania",
        "LU": "Luxembourg",
        "MT": "Malta",
        "CY": "Cyprus",
        "JP": "Japan",
        "CN": "China",
        "KR": "South Korea",
        "IN": "India",
        "SG": "Singapore",
        "HK": "Hong Kong",
        "TW": "Taiwan",
        "TH": "Thailand",
        "MY": "Malaysia",
        "ID": "Indonesia",
        "PH": "Philippines",
        "VN": "Vietnam",
        "RU": "Russia",
        "TR": "Turkey",
        "IL": "Israel",
        "SA": "Saudi Arabia",
        "AE": "United Arab Emirates",
        "ZA": "South Africa",
        "EG": "Egypt",
        "NG": "Nigeria",
        "KE": "Kenya",
        "BR": "Brazil",
        "MX": "Mexico",
        "AR": "Argentina",
        "CL": "Chile",
        "CO": "Colombia",
        "PE": "Peru"
    ]
    
    static func regionName(for code: String) -> String {
        return availableRegions[code.uppercased()] ?? code
    }
    
    static func isValidRegion(_ code: String) -> Bool {
        return availableRegions[code.uppercased()] != nil
    }
}

// MARK: - URL Validation Helpers

extension URL {
    
    /// Validate and extract app information from URL
    func validateAppStoreURL() -> (isValid: Bool, appId: Int?, platform: AppPlatform, country: String?, error: String?) {
        guard self.isAppStoreURL else {
            return (false, nil, .all, nil, "Not a valid App Store URL")
        }
        
        guard let appId = self.extractAppStoreId() else {
            return (false, nil, .all, nil, "Could not extract app ID from URL")
        }
        
        let platform = self.detectedPlatform
        let country = self.extractCountryCode() ?? UserSettings.shared.preferredRegion
        
        return (true, appId, platform, country, nil)
    }
}

// MARK: - Platform-Specific URL Helpers

extension WishlistApp {
    /// Get the appropriate App Store URL for this app's platform
    var platformSpecificStoreURL: String {
        guard let url = URL(string: storeURL) else { return storeURL }
        
        // If we know the platform, ensure URL matches
        if let detectedPlatform = try? self.detectedPlatform {
            if let convertedURL = url.convertToPlatform(detectedPlatform) {
                return convertedURL.absoluteString
            }
        }
        
        return storeURL
    }
    
    /// Get deep link URL for opening in appropriate store app
    var storeDeepLinkURL: String? {
        guard let url = URL(string: storeURL),
              let appId = url.extractAppStoreId() else { return nil }
        
        let platform = url.detectedPlatform
        return URL.platformDeepLink(for: appId, platform: platform)?.absoluteString
    }
}
