//
//  WishlistView.swift
//  WishDirectory
//
//  Created by Development Team on 23.09.2025.
//

import SwiftUI

// MARK: - Main Wishlist View

struct WishlistView: View {
    // MARK: - Services & State
    @StateObject private var wishlistService = WishlistService.shared
    @StateObject private var userSettings = UserSettings.shared
    
    // MARK: - Local State
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingSortOptions = false
    @State private var showingFilterOptions = false
    @State private var isRefreshing = false
    @State private var selectedApp: WishlistApp?
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedApps: [WishlistApp] {
        var apps = wishlistService.apps
        
        // Apply search filter
        if !searchText.isEmpty {
            apps = wishlistService.searchApps(query: searchText)
        }
        
        // Apply user filters
        if userSettings.filterOnSaleOnly {
            apps = apps.filter { $0.isOnSale }
        }
        
        if userSettings.hideFreeApps {
            apps = apps.filter { !$0.isFree }
        }
        
        // Apply sorting
        return sortApps(apps, by: userSettings.sortOrder)
    }
    
    private var appsNeedingUpdate: [WishlistApp] {
        return wishlistService.appsNeedingUpdate()
    }
    
    private var totalSavings: Double {
        return wishlistService.totalSavings()
    }
    
    // MARK: - Main Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if wishlistService.apps.isEmpty {
                    EmptyWishlistView(showingAddApp: $showingAddSheet)
                } else {
                    VStack(spacing: 0) {
                        // Stats Header (if on sale apps exist)
                        if !wishlistService.getAppsOnSale().isEmpty {
                            SavingsHeaderView(totalSavings: totalSavings, appsOnSale: wishlistService.getAppsOnSale().count)
                        }
                        
                        // Main Content
                        if filteredAndSortedApps.isEmpty && !searchText.isEmpty {
                            SearchEmptyStateView(searchText: searchText)
                        } else {
                            AppListView(
                                apps: filteredAndSortedApps,
                                isRefreshing: $isRefreshing,
                                selectedApp: $selectedApp,
                                onRefresh: refreshPrices,
                                onDelete: deleteApps
                            )
                        }
                    }
                }
                
                // Floating Add Button
                FloatingAddButton(showingAddApp: $showingAddSheet)
            }
            .navigationTitle("Wishlist")
            .searchable(text: $searchText, prompt: "Search apps...")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Filter Button
                    Button(action: { showingFilterOptions = true }) {
                        Image(systemName: userSettings.filterOnSaleOnly || userSettings.hideFreeApps ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    
                    // Sort Button
                    Button(action: { showingSortOptions = true }) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                    
                    // Loading Indicator
                    if wishlistService.isLoading || isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
            }
            .refreshable {
                await refreshPrices()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddAppView()
                    .environmentObject(wishlistService)
            }
            .sheet(item: $selectedApp) { app in
                AppDetailView(app: app)
                    .environmentObject(wishlistService)
            }
            .confirmationDialog("Sort Apps", isPresented: $showingSortOptions) {
                ForEach(SortOrder.allCases, id: \.self) { sortOption in
                    Button(sortOption.displayName) {
                        userSettings.sortOrder = sortOption
                        triggerHapticFeedback()
                    }
                }
            }
            .confirmationDialog("Filter Options", isPresented: $showingFilterOptions) {
                Button(userSettings.filterOnSaleOnly ? "Show All Apps" : "Show Only On Sale") {
                    userSettings.filterOnSaleOnly.toggle()
                    triggerHapticFeedback()
                }
                
                Button(userSettings.hideFreeApps ? "Show Free Apps" : "Hide Free Apps") {
                    userSettings.hideFreeApps.toggle()
                    triggerHapticFeedback()
                }
            }
            .alert("Price Update Error", isPresented: .constant(wishlistService.lastError != nil), presenting: wishlistService.lastError) { error in
                Button("OK") {
                    // Error is automatically dismissed
                }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Mark app as active for price update suggestions
            if !appsNeedingUpdate.isEmpty && userSettings.autoUpdatePrices {
                suggestPriceUpdate()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func sortApps(_ apps: [WishlistApp], by sortOrder: SortOrder) -> [WishlistApp] {
        switch sortOrder {
        case .discountPercentage:
            return apps.sorted { $0.discountPercentage > $1.discountPercentage }
        case .priceLowToHigh:
            return apps.sorted { $0.currentPrice < $1.currentPrice }
        case .priceHighToLow:
            return apps.sorted { $0.currentPrice > $1.currentPrice }
        case .alphabetical:
            return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            return apps.sorted { $0.dateAdded > $1.dateAdded }
        case .developer:
            return apps.sorted { $0.developer.localizedCaseInsensitiveCompare($1.developer) == .orderedAscending }
        }
    }
    
    private func refreshPrices() async {
        guard !wishlistService.isLoading else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let priceChanges = try await wishlistService.updateAllPrices()
            
            if !priceChanges.isEmpty {
                // Show brief success feedback
                triggerHapticFeedback(.success)
                
                // Update last check timestamp
                userSettings.updateLastCheckTimestamp()
                
                // Handle price drop notifications
                handlePriceDrops(priceChanges)
            }
        } catch {
            triggerHapticFeedback(.error)
            print("Failed to refresh prices: \(error)")
        }
    }
    
    private func deleteApps(at offsets: IndexSet) {
        let appsToDelete = offsets.map { filteredAndSortedApps[$0] }
        
        Task {
            for app in appsToDelete {
                do {
                    try await wishlistService.removeApp(withId: app.id)
                } catch {
                    print("Failed to delete app \(app.name): \(error)")
                }
            }
        }
        
        triggerHapticFeedback(.warning)
    }
    
    private func handlePriceDrops(_ priceChanges: [(app: WishlistApp, oldPrice: Double, newPrice: Double)]) {
        let significantDrops = priceChanges.filter { change in
            let discountPercentage = ((change.oldPrice - change.newPrice) / change.oldPrice) * 100
            return userSettings.meetsThreshold(discountPercentage: discountPercentage)
        }
        
        if !significantDrops.isEmpty && userSettings.notificationsEnabled {
            // Schedule local notifications for price drops
            scheduleNotifications(for: significantDrops)
        }
    }
    
    private func scheduleNotifications(for drops: [(app: WishlistApp, oldPrice: Double, newPrice: Double)]) {
        // This will be implemented in Sprint 5 with NotificationService
        // For now, just log the price drops
        for drop in drops {
            print("Price drop detected: \(drop.app.name) from $\(drop.oldPrice) to $\(drop.newPrice)")
        }
    }
    
    private func suggestPriceUpdate() {
        // Gentle suggestion to update prices if apps haven't been checked recently
        // This could be implemented as a subtle banner or popup
    }
    
    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType = .light) {
        guard userSettings.hapticFeedbackEnabled else { return }
        
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        @unknown default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Supporting Views

struct SavingsHeaderView: View {
    let totalSavings: Double
    let appsOnSale: Int
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Savings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(userSettings.formattedTotalSavings)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Apps on Sale")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(appsOnSale)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct AppListView: View {
    let apps: [WishlistApp]
    @Binding var isRefreshing: Bool
    @Binding var selectedApp: WishlistApp?
    let onRefresh: () async -> Void
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(apps) { app in
                AppRowView(app: app)
                    .onTapGesture {
                        selectedApp = app
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await onRefresh()
        }
    }
}

struct SearchEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No apps match '\(searchText)'")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyWishlistView: View {
    @Binding var showingAddApp: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Apps in Wishlist")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add apps from the App Store to track their prices and get notified when they go on sale")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                showingAddApp = true
            }) {
                Label("Add Your First App", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct FloatingAddButton: View {
    @Binding var showingAddApp: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingAddApp = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Placeholder Views

// These will be implemented in subsequent files
struct AppRowView: View {
    let app: WishlistApp
    
    var body: some View {
        HStack {
            // App icon placeholder
            AsyncImage(url: URL(string: app.bestIconURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(app.developer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(app.formattedPrice ?? "$\(app.currentPrice, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if app.isOnSale {
                        Text(app.formattedDiscountPercentage)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AppDetailView: View {
    let app: WishlistApp
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("App Detail View - \(app.name)")
                    .padding()
            }
            .navigationTitle(app.name)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AddAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add App View")
                    .padding()
            }
            .navigationTitle("Add App")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { dismiss() }
            )
        }
    }
}

// MARK: - Preview Provider

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
            .environmentObject(WishlistService.shared)
            .environmentObject(UserSettings.shared)
    }
}
