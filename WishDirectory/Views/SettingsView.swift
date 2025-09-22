//
//  SettingsView.swift
//  WishDirectory
//
//  Enhanced for Sprint 5 - Notifications & Price Tracking
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    // MARK: - State Management
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var wishlistService = WishlistService.shared
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.openURL) private var openURL
    
    // MARK: - Local State
    @State private var isUpdatingPrices = false
    @State private var showingClearDataAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingPermissionAlert = false
    @State private var lastUpdateText = "Never"
    @State private var updateProgress: Double = 0.0
    @State private var showingUpdateProgress = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Statistics Section
                StatisticsSection()
                
                // MARK: - Enhanced Notifications Section
                NotificationsSection(
                    showingNotificationSettings: $showingNotificationSettings,
                    showingPermissionAlert: $showingPermissionAlert
                )
                
                // MARK: - Enhanced Price Tracking Section
                PriceTrackingSection(
                    isUpdatingPrices: $isUpdatingPrices,
                    updateProgress: $updateProgress,
                    showingUpdateProgress: $showingUpdateProgress,
                    lastUpdateText: $lastUpdateText
                )
                
                // MARK: - Display Settings Section
                DisplaySettingsSection()
                
                // MARK: - Regional Settings Section
                RegionalSettingsSection()
                
                // MARK: - Privacy Section
                PrivacySection()
                
                // MARK: - Data Management Section
                DataManagementSection(showingClearDataAlert: $showingClearDataAlert)
                
                // MARK: - About Section
                AboutSection()
            }
            .navigationTitle("Settings")
            .onAppear {
                updateLastUpdateText()
            }
            .onReceive(wishlistService.$lastUpdateTimestamp) { _ in
                updateLastUpdateText()
            }
            .onReceive(wishlistService.$updateProgress) { progress in
                updateProgress = progress
                showingUpdateProgress = progress > 0 && progress < 1.0
            }
            .alert("Notification Settings", isPresented: $showingNotificationSettings) {
                Button("Open Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To receive price drop notifications, please enable notifications for Wish Directory in Settings.")
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Allow Notifications") {
                    Task {
                        await requestNotificationPermission()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Allow notifications to receive alerts when app prices drop.")
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Data", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will remove all apps from your wishlist and reset your settings. This action cannot be undone.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Private Methods
    
    private func updateLastUpdateText() {
        if let lastUpdate = userSettings.lastUpdateTimestamp {
            lastUpdateText = lastUpdate.formatted(.relative(presentation: .named))
        } else {
            lastUpdateText = "Never"
        }
    }
    
    private func requestNotificationPermission() async {
        let granted = await notificationService.requestPermission()
        await MainActor.run {
            userSettings.notificationsEnabled = granted
        }
    }
    
    private func updateAllPrices() {
        guard !isUpdatingPrices else { return }
        
        isUpdatingPrices = true
        Task {
            do {
                let priceChanges = try await wishlistService.updateAllPrices()
                await MainActor.run {
                    isUpdatingPrices = false
                    showingUpdateProgress = false
                    updateLastUpdateText()
                    
                    // Show success feedback
                    if !priceChanges.isEmpty {
                        // Trigger haptic feedback for price changes
                        if userSettings.hapticFeedbackEnabled {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isUpdatingPrices = false
                    showingUpdateProgress = false
                    print("Failed to update prices: \(error)")
                }
            }
        }
    }
    
    private func clearAllData() {
        Task {
            do {
                try await wishlistService.clearAllApps()
                await MainActor.run {
                    userSettings.resetToDefaults()
                    updateLastUpdateText()
                }
            } catch {
                print("Failed to clear data: \(error)")
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsUrl)
        }
    }
}

// MARK: - Statistics Section

struct StatisticsSection: View {
    @StateObject private var wishlistService = WishlistService.shared
    @StateObject private var userSettings = UserSettings.shared
    
    private var priceDropStats: (totalDrops: Int, totalSavings: Double, averageDiscount: Double) {
        return wishlistService.getPriceDropStatistics()
    }
    
    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("Apps Tracked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(wishlistService.getAllApps().count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("On Sale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(wishlistService.getAppsOnSale().count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(userSettings.formattedTotalSavings)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Price Drops Found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(priceDropStats.totalDrops)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Statistics")
        }
    }
}

// MARK: - Enhanced Notifications Section

struct NotificationsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var notificationService = NotificationService.shared
    @Binding var showingNotificationSettings: Bool
    @Binding var showingPermissionAlert: Bool
    
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled in Settings"
        case .notDetermined:
            return "Not Requested"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        default:
            return .secondary
        }
    }
    
    var body: some View {
        Section {
            // Notification Status Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundColor(notificationStatusColor)
                }
                
                Spacer()
                
                if notificationService.authorizationStatus == .notDetermined {
                    Button("Allow Notifications") {
                        showingPermissionAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else if notificationService.authorizationStatus == .denied {
                    Button("Settings") {
                        showingNotificationSettings = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Price Drop Notifications Toggle
            Toggle("Price Drop Notifications", isOn: Binding(
                get: {
                    userSettings.notificationsEnabled && notificationService.isPermissionGranted
                },
                set: { newValue in
                    if newValue && !notificationService.isPermissionGranted {
                        if notificationService.authorizationStatus == .notDetermined {
                            showingPermissionAlert = true
                        } else {
                            showingNotificationSettings = true
                        }
                    } else {
                        userSettings.notificationsEnabled = newValue
                    }
                }
            ))
            .disabled(!notificationService.isPermissionGranted)
            
            // Price Drop Threshold Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Price Drop Threshold")
                    Spacer()
                    Text("\(Int(userSettings.priceDropThreshold))%")
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                
                Slider(
                    value: $userSettings.priceDropThreshold,
                    in: 5...50,
                    step: 5
                ) {
                    Text("Threshold")
                } minimumValueLabel: {
                    Text("5%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("50%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)
                .disabled(!userSettings.notificationsEnabled)
            }
            
            // Update Frequency Picker
            Picker("Update Frequency", selection: $userSettings.updateFrequencyHours) {
                Text("Every 6 hours").tag(6)
                Text("Every 12 hours").tag(12)
                Text("Once daily").tag(24)
                Text("Every 3 days").tag(72)
            }
            .disabled(!userSettings.autoUpdatePrices)
            
            // Auto Update Toggle
            Toggle("Automatic Price Updates", isOn: $userSettings.autoUpdatePrices)
            
            // Pending Notifications Count
            if notificationService.pendingNotificationsCount > 0 {
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(notificationService.pendingNotificationsCount)")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
        } header: {
            Text("Notifications")
        } footer: {
            if userSettings.notificationsEnabled && notificationService.isPermissionGranted {
                Text("Get notified when apps drop by at least \(Int(userSettings.priceDropThreshold))%. \(userSettings.updateFrequencyDescription.lowercased()).")
            } else if !notificationService.isPermissionGranted {
                Text("Enable notifications to get alerts about price drops.")
            } else {
                Text("Notification settings are disabled.")
            }
        }
    }
}

// MARK: - Enhanced Price Tracking Section

struct PriceTrackingSection: View {
    @StateObject private var userSettings = UserSettings.shared
    @StateObject private var wishlistService = WishlistService.shared
    @Binding var isUpdatingPrices: Bool
    @Binding var updateProgress: Double
    @Binding var showingUpdateProgress: Bool
    @Binding var lastUpdateText: String
    
    private var appsNeedingUpdate: Int {
        return wishlistService.appsNeedingUpdate().count
    }
    
    var body: some View {
        Section {
            // Manual Update Button with Progress
            VStack(spacing: 8) {
                Button(action: {
                    updateAllPrices()
                }) {
                    HStack {
                        if isUpdatingPrices {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("Checking Prices...")
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Prices Now")
                        }
                        Spacer()
                    }
                }
                .disabled(isUpdatingPrices || wishlistService.getAllApps().isEmpty)
                
                // Progress Bar
                if showingUpdateProgress {
                    VStack(spacing: 4) {
                        ProgressView(value: updateProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        HStack {
                            Text("Updating prices...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(updateProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .transition(.opacity)
                }
            }
            
            // Last Update Info
            HStack {
                Text("Last Price Check")
                Spacer()
                Text(lastUpdateText)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            // Apps Needing Update
            if appsNeedingUpdate > 0 {
                HStack {
                    Text("Apps Need Update")
                    Spacer()
                    Text("\(appsNeedingUpdate)")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
            
            // Next Auto Update Time
            if userSettings.autoUpdatePrices, let nextUpdate = userSettings.nextUpdateTime {
                HStack {
                    Text("Next Auto Update")
                    Spacer()
                    Text(nextUpdate.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        } header: {
            Text("Price Tracking")
        } footer: {
            if wishlistService.getAllApps().isEmpty {
                Text("Add apps to your wishlist to start tracking prices.")
            } else if isUpdatingPrices {
                Text("Checking \(wishlistService.getAllApps().count) apps for price changes...")
            } else {
                Text("Manually check for price updates or enable automatic updates above.")
            }
        }
    }
    
    private func updateAllPrices() {
        guard !isUpdatingPrices else { return }
        
        isUpdatingPrices = true
        Task {
            do {
                let priceChanges = try await wishlistService.updateAllPrices()
                await MainActor.run {
                    isUpdatingPrices = false
                    showingUpdateProgress = false
                    updateLastUpdateText()
                    
                    // Show success feedback
                    if !priceChanges.isEmpty {
                        if userSettings.hapticFeedbackEnabled {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isUpdatingPrices = false
                    showingUpdateProgress = false
                }
            }
        }
    }
    
    private func updateLastUpdateText() {
        if let lastUpdate = userSettings.lastUpdateTimestamp {
            lastUpdateText = lastUpdate.formatted(.relative(presentation: .named))
        } else {
            lastUpdateText = "Never"
        }
    }
}

// MARK: - Display Settings Section

struct DisplaySettingsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Section {
            Picker("Sort Order", selection: $userSettings.sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { sortOrder in
                    Label(sortOrder.displayName, systemImage: sortOrder.icon)
                        .tag(sortOrder)
                }
            }
            
            Toggle("Show Only On Sale", isOn: $userSettings.filterOnSaleOnly)
            
            Toggle("Hide Free Apps", isOn: $userSettings.hideFreeApps)
            
            Toggle("Haptic Feedback", isOn: $userSettings.hapticFeedbackEnabled)
            
        } header: {
            Text("Display")
        }
    }
}

// MARK: - Regional Settings Section

struct RegionalSettingsSection: View {
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Section {
            Picker("Region", selection: $userSettings.preferredRegion) {
                ForEach(Array(AppStoreRegions.availableRegions.keys.sorted()), id: \.self) { code in
                    Text("\(AppStoreRegions.regionName(for: code)) (\(code))")
                        .tag(code)
                }
            }
            
            HStack {
                Text("Currency")
                Spacer()
                Text(userSettings.formattedCurrency())
                    .foregroundColor(.secondary)
            }
            
        } header: {
            Text("Regional Settings")
        } footer: {
            Text("Prices will be displayed in the currency for your selected region.")
        }
    }
}

// MARK: - Privacy Section

struct PrivacySection: View {
    @StateObject private var userSettings = UserSettings.shared
    
    var body: some View {
        Section {
            Toggle("Anonymous Analytics", isOn: $userSettings.analyticsEnabled)
            
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
            
        } header: {
            Text("Privacy")
        } footer: {
            Text("Help improve the app by sharing anonymous usage data. No personal information is collected.")
        }
    }
}

// MARK: - Data Management Section

struct DataManagementSection: View {
    @StateObject private var wishlistService = WishlistService.shared
    @Binding var showingClearDataAlert: Bool
    
    var body: some View {
        Section {
            Button("Export Wishlist Data") {
                exportData()
            }
            
            Button("Clear All Data", role: .destructive) {
                showingClearDataAlert = true
            }
            .disabled(wishlistService.getAllApps().isEmpty)
            
        } header: {
            Text("Data Management")
        } footer: {
            Text("Export your wishlist data or completely reset the app.")
        }
    }
    
    private func exportData() {
        guard let data = wishlistService.exportApps() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [data],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    @Environment(\.openURL) private var openURL
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundColor(.secondary)
            }
            
            Button("Contact Support") {
                if let url = URL(string: "mailto:support@wishdirectory.app") {
                    openURL(url)
                }
            }
            
            Button("Rate on App Store") {
                if let url = URL(string: "https://apps.apple.com/app/wish-directory/idXXXXXXXXX") {
                    openURL(url)
                }
            }
            
        } header: {
            Text("About")
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us. This privacy policy explains what information we collect, how we use it, and your rights regarding your data.")
                
                Group {
                    Text("Information We Collect")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• App Store URLs you add to your wishlist\n• Price information from public iTunes API\n• Your app preferences and settings\n• Anonymous usage analytics (if enabled)")
                    
                    Text("How We Use Information")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• To track app prices and notify you of changes\n• To provide app recommendations\n• To improve app functionality and user experience")
                    
                    Text("Data Storage")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("All your data is stored locally on your device. We do not transmit your personal data to external servers.")
                    
                    Text("Your Rights")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("• Export your data at any time\n• Delete all your data\n• Disable analytics collection\n• Control notification preferences")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
