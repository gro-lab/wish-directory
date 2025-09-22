//
//  ContentView.swift
//  WishDirectory
//
//  Created by Radu-Ovidiu GavrilÄƒ on 22.09.2025.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Environment & State
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    
    // MARK: - Local State
    @State private var showingAddAppSheet = false
    @State private var hasInitialized = false
    @State private var tabBarHeight: CGFloat = 49 // Default tab bar height
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Wishlist Tab
            WishlistTabView(showingAddApp: $showingAddAppSheet)
                .tabItem {
                    Label("Wishlist", systemImage: "star.fill")
                }
                .tag(0)
                .badge(appState.savedApps.count > 0 ? "\(appState.savedApps.count)" : nil)
            
            // MARK: - Settings Tab
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
                .badge(appState.shouldRefreshPrices ? "!" : nil)
        }
        .onAppear {
            performInitialSetup()
        }
        .onChange(of: selectedTab) { _, newTab in
            handleTabChange(to: newTab)
        }
        .onChange(of: appState.shouldRefreshPrices) { _, shouldRefresh in
            if shouldRefresh {
                handlePriceRefreshRequest()
            }
        }
        .sheet(isPresented: $showingAddAppSheet) {
            AddAppPlaceholder()
                .environmentObject(appState)
        }
    }
    
    // MARK: - Setup & Lifecycle
    
    private func performInitialSetup() {
        guard !hasInitialized else { return }
        
        // Initialize view state
        hasInitialized = true
        
        // Set initial tab if needed
        if selectedTab < 0 || selectedTab > 1 {
            selectedTab = 0
        }
        
        // Log app opening for analytics (if consented)
        logAppOpen()
    }
    
    private func handleTabChange(to newTab: Int) {
        // Save tab selection to UserDefaults (handled by @AppStorage in WishDirectoryApp)
        
        // Haptic feedback for tab switch
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Handle tab-specific actions
        switch newTab {
        case 0:
            // Wishlist tab selected
            if appState.shouldRefreshPrices {
                // Will trigger price refresh in WishlistTabView
            }
        case 1:
            // Settings tab selected
            // Could trigger settings reload if needed
            break
        default:
            break
        }
    }
    
    private func handlePriceRefreshRequest() {
        // This will be implemented in Sprint 5
        // For now, just reset the flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            appState.shouldRefreshPrices = false
            appState.updateLastCheck()
        }
    }
    
    private func logAppOpen() {
        // Future analytics implementation
        // Only log if user has consented to analytics
        if UserDefaults.standard.bool(forKey: "analyticsEnabled") {
            // Log event (to be implemented)
        }
    }
}

// MARK: - Wishlist Tab View

struct WishlistTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingAddApp: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                if appState.savedApps.isEmpty {
                    // Empty state
                    EmptyWishlistView(showingAddApp: $showingAddApp)
                } else {
                    // App list (placeholder for Sprint 3)
                    WishlistContentPlaceholder()
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddAppButton(showingAddApp: $showingAddApp)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appState.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Settings Tab View

struct SettingsTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var priceDropThreshold = UserDefaults.standard.double(forKey: "priceDropThreshold")
    
    var body: some View {
        NavigationView {
            Form {
                // Notifications Section
                Section {
                    Toggle("Price Drop Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
                        }
                    
                    HStack {
                        Text("Price Drop Threshold")
                        Spacer()
                        Text("\(Int(priceDropThreshold))%")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get notified when apps drop by at least \(Int(priceDropThreshold))%")
                        .font(.caption)
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Apps Tracked")
                        Spacer()
                        Text("\(appState.savedApps.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastUpdate = appState.lastUpdateTimestamp {
                        HStack {
                            Text("Last Price Check")
                            Spacer()
                            Text(lastUpdate, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Statistics")
                }
                
                // Actions Section
                Section {
                    Button(action: {
                        appState.shouldRefreshPrices = true
                    }) {
                        HStack {
                            Text("Check Prices Now")
                            Spacer()
                            if appState.shouldRefreshPrices {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(appState.shouldRefreshPrices || appState.savedApps.isEmpty)
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Empty State View

struct EmptyWishlistView: View {
    @Binding var showingAddApp: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Apps in Wishlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add apps from the App Store to track their prices")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddApp = true
            }) {
                Label("Add Your First App", systemImage: "plus.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
    }
}

// MARK: - Add App Button

struct AddAppButton: View {
    @Binding var showingAddApp: Bool
    
    var body: some View {
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
                .shadow(radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Placeholder Views (Will be replaced in future sprints)

struct WishlistContentPlaceholder: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            ForEach(appState.savedApps, id: \.self) { appId in
                HStack {
                    Image(systemName: "app.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("App ID: \(appId)")
                            .font(.headline)
                        Text("Price tracking enabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    appState.removeApp(appState.savedApps[index])
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct AddAppPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var appUrl = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add App from App Store")
                    .font(.headline)
                    .padding(.top, 40)
                
                Text("Paste an App Store URL below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("https://apps.apple.com/...", text: $appUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                
                Button(action: {
                    // For Sprint 1, just add a dummy app ID
                    if !appUrl.isEmpty {
                        appState.addApp(appUrl)
                        dismiss()
                    }
                }) {
                    Text("Add App")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appUrl.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .disabled(appUrl.isEmpty)
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedTab: .constant(0))
            .environmentObject(AppState())
    }
}
