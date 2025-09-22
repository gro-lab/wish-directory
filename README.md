# Wish Directory iOS App - Atomic Sprint Implementation Plan

## Project Overview
Build a simple, privacy-focused iOS wishlist app for App Store apps with price tracking. Total timeline: **3 weeks, 6 sprints**.

---

## **SPRINT 1: Foundation & Data Layer** (Days 1-2)

### Sprint Goal
Establish core app structure and data models that can immediately store and retrieve wishlist apps.

### Files to Create/Modify

**WishDirectoryApp.swift**
Main app entry point that initializes SwiftUI lifecycle. Sets up basic app configuration and launches ContentView without complex dependency injection. Handles app state restoration and background-to-foreground transitions.

**ContentView.swift**
Primary navigation coordinator with TabView containing Wishlist and Settings tabs. Manages global app state and provides shared data context to child views. Implements basic tab switching with proper state preservation.

**Models/WishlistApp.swift**
Core data model representing a single app in the wishlist. Contains app ID, name, developer, icon URL, store URL, current price, original price, and date added. Implements Codable for UserDefaults persistence and computed properties for price drop calculations.

**Models/UserSettings.swift**
Simple settings model using @Published properties for notifications enabled, price drop threshold percentage, and last update timestamp. Automatically syncs changes to UserDefaults with Combine observers for real-time persistence.

**Extensions/UserDefaults+Keys.swift**
Type-safe UserDefaults access with string constants for all storage keys. Provides clean interface for savedApps array, notification preferences, price thresholds, and update timestamps to prevent key typos.

### Sprint Deliverable
Basic app shell that can launch, navigate between tabs, and has complete data models ready for CRUD operations. Users can see empty states but data persistence is implemented.

---

## **SPRINT 2: Core Service Layer** (Days 3-4)

### Sprint Goal
Implement iTunes API integration and core wishlist management that can add, remove, and update apps.

### Files to Create

**Services/WishlistService.swift**
Main service class managing CRUD operations for wishlist apps using UserDefaults persistence. Handles adding apps, removing apps, updating prices, and retrieving all apps with automatic data synchronization. Implements @MainActor for UI thread safety.

**Services/iTunesService.swift**
iTunes Search API integration service that fetches app metadata by app ID. Handles URL construction, JSON parsing, error management, and response validation. Implements async/await pattern for modern Swift concurrency.

**Extensions/URL+AppStore.swift**
Utility extensions for parsing App Store URLs to extract app IDs. Supports multiple URL formats including apps.apple.com, itunes.apple.com, and itms-apps schemes. Validates URL format and generates iTunes lookup URLs.

### Sprint Deliverable
Complete backend services that can fetch app data from iTunes API and persist to device storage. Ready for UI integration with full error handling.

---

## **SPRINT 3: Primary User Interface** (Days 5-7)

### Sprint Goal
Build main wishlist interface where users can view, add, and manage their saved apps.

### Files to Create

**Views/WishlistView.swift**
Primary app interface displaying user's saved apps in a list format. Implements search filtering, pull-to-refresh for price updates, swipe-to-delete functionality, and add button. Shows empty state when no apps are saved with helpful messaging.

**Views/AddAppView.swift**
Modal interface for manually adding apps via App Store URL input. Contains text field with validation, paste button, URL format checking, and loading states during app addition. Provides clear error messages for invalid URLs.

**Components/AppRowView.swift**
Reusable list item component displaying app icon, name, developer, and price information. Shows price drop indicators with color coding and percentage savings. Implements consistent styling and tap handling for navigation.

**Components/PriceView.swift**
Specialized component for displaying app prices with proper formatting. Shows current price, original price with strikethrough for discounts, and percentage savings with color coding. Handles free apps and price formatting.

**Components/LoadingView.swift**
Simple loading state component with activity indicator and customizable message text. Used throughout app during network operations, price updates, and data processing with consistent styling.

### Sprint Deliverable
Functional wishlist interface where users can manually add App Store URLs, view saved apps, and perform basic list management. Core user journey is complete.

---

## **SPRINT 4: App Details & Navigation** (Days 8-9)

### Sprint Goal
Complete the app browsing experience with detailed views and seamless navigation.

### Files to Create

**Views/AppDetailView.swift**
Detailed app information screen showing large icon, screenshots, description, price history, and action buttons. Displays current vs. original price with visual price drop indicators. Includes remove from wishlist and open in App Store functionality.

**Views/SettingsView.swift**
App preferences interface with notification toggles, price drop threshold slider, manual update checking, and app information. Shows statistics like total apps saved and current price drops. Includes privacy policy and support links.

### Sprint Deliverable
Complete navigation flow from wishlist to app details with full functionality. Users can view comprehensive app information and modify app preferences.

---

## **SPRINT 5: Price Tracking & Notifications** (Days 10-11)

### Sprint Goal
Implement price monitoring system with local notifications for price drops.

### Files to Create

**Services/NotificationService.swift**
Local notification service that requests permission, schedules price drop alerts, and manages notification content. Handles notification authorization status and provides fallback messaging when permissions denied.

### Files to Modify

**Services/WishlistService.swift** (Enhancement)
Add price update functionality that compares current prices with stored prices. Implements batch price checking for all wishlist apps and triggers notifications for significant price drops based on user threshold settings.

**Views/SettingsView.swift** (Enhancement)
Add notification permission request, price threshold configuration slider, and manual "Check Prices Now" functionality. Show last update timestamp and notification status with clear user controls.

### Sprint Deliverable
Complete price tracking system with local notifications. Users receive alerts when apps drop in price and can configure notification preferences.

---

## **SPRINT 6: Polish & App Store Preparation** (Days 12-15)

### Sprint Goal
Final polish, error handling, App Store assets, and submission preparation.

### Files to Create/Modify

**Resources/Assets.xcassets**
Complete app icon set with all required sizes, launch screen images, and accent colors. Includes proper icon design following Apple Human Interface Guidelines with consistent branding across all sizes.

**Resources/Localizable.strings**
All user-facing text strings for internationalization support. Includes error messages, button labels, empty state text, and notification content with proper localization keys for future language support.

**Info.plist** (Enhancement)
Complete app configuration with privacy descriptions, URL scheme handlers for App Store links, notification permissions, and proper app metadata. Includes all required usage descriptions for App Store review.

**WishDirectoryTests/WishDirectoryTests.swift**
Unit tests covering core functionality including WishlistService CRUD operations, iTunes API parsing, URL validation, and price comparison logic. Ensures data persistence and business logic reliability.

**WishDirectoryUITests/WishDirectoryUITests.swift**
UI tests covering critical user journeys including adding apps, removing apps, price updates, and settings modification. Validates complete user workflows work end-to-end.

### Files for Error Handling Enhancement

**All existing View files** (Error Handling)
Add comprehensive error handling with user-friendly error messages, retry mechanisms, offline state handling, and graceful degradation when services unavailable.

**All existing Service files** (Error Handling)
Implement proper error types, network timeout handling, malformed response handling, and recovery strategies for API failures.

### Sprint Deliverable
Production-ready app with complete error handling, comprehensive testing, App Store assets, and submission materials. Ready for TestFlight beta and App Store review.

---

## **Final Project Structure Summary**

```
WishDirectory/
├── WishDirectoryApp.swift                     # App lifecycle management
├── ContentView.swift                          # Tab navigation coordinator
├── Info.plist                                # App configuration & permissions
│
├── Models/
│   ├── WishlistApp.swift                     # Core app data structure
│   └── UserSettings.swift                    # App preferences model
│
├── Services/
│   ├── WishlistService.swift                 # CRUD operations & persistence
│   ├── iTunesService.swift                   # iTunes API integration
│   └── NotificationService.swift             # Price drop notifications
│
├── Views/
│   ├── WishlistView.swift                    # Main app list interface
│   ├── AppDetailView.swift                   # Detailed app information
│   ├── AddAppView.swift                      # Manual app addition
│   └── SettingsView.swift                    # App preferences
│
├── Components/
│   ├── AppRowView.swift                      # List item component
│   ├── PriceView.swift                       # Price display component
│   └── LoadingView.swift                     # Loading state indicator
│
├── Extensions/
│   ├── URL+AppStore.swift                    # URL parsing utilities
│   └── UserDefaults+Keys.swift               # Storage key constants
│
├── Resources/
│   ├── Assets.xcassets                       # Icons and images
│   └── Localizable.strings                   # Text localization
│
└── Tests/
    ├── WishDirectoryTests.swift              # Unit test coverage
    └── WishDirectoryUITests.swift            # UI test scenarios
```

**Total: 18 files across 6 focused sprints**

Each sprint delivers working functionality that users can interact with, following the "code changed means pixel moved" philosophy. The app grows incrementally from basic shell to production-ready wishlist manager.