//
//  AddAppView.swift
//  WishDirectory
//
//  Created by Development Team on 23.09.2025.
//

import SwiftUI

// MARK: - Add App View

struct AddAppView: View {
    // MARK: - Environment & Services
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var wishlistService: WishlistService
    @StateObject private var userSettings = UserSettings.shared
    
    // MARK: - State Properties
    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    @State private var addedApp: WishlistApp?
    @State private var showingSuccessAlert = false
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        return !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var cleanedURL: String {
        return urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var hasClipboardURL: Bool {
        guard let clipboardString = UIPasteboard.general.string else { return false }
        return clipboardString.isValidAppStoreURL
    }
    
    // MARK: - Main Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    HeaderSection()
                    
                    // URL Input Section
                    URLInputSection(
                        urlText: $urlText,
                        hasClipboardURL: hasClipboardURL,
                        onPasteFromClipboard: pasteFromClipboard
                    )
                    
                    // Action Buttons
                    ActionButtonsSection(
                        isValidInput: isValidInput,
                        isLoading: isLoading,
                        onAddApp: addAppFromURL,
                        onCancel: { dismiss() }
                    )
                    
                    // Help Section
                    HelpSection()
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Add App")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Add") {
                    Task { await addAppFromURL() }
                }
                .disabled(!isValidInput || isLoading)
            )
            .alert("Error Adding App", isPresented: $showingErrorAlert, presenting: errorMessage) { errorMessage in
                Button("OK") {
                    self.errorMessage = nil
                }
            } message: { errorMessage in
                Text(errorMessage)
            }
            .alert("App Added Successfully!", isPresented: $showingSuccessAlert, presenting: addedApp) { app in
                Button("View in Wishlist") {
                    dismiss()
                }
                Button("Add Another") {
                    clearForm()
                }
            } message: { app in
                Text("'\(app.name)' has been added to your wishlist.")
            }
            .onAppear {
                checkClipboardOnAppear()
            }
        }
    }
    
    // MARK: - Actions
    
    private func addAppFromURL() async {
        guard isValidInput else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate and clean URL
            guard let cleanURL = cleanedURL.cleanAppStoreURL() else {
                throw AddAppError.invalidURL
            }
            
            // Extract app ID
            guard let appId = cleanURL.extractAppStoreId() else {
                throw AddAppError.noAppIdFound
            }
            
            // Check if app already exists
            if wishlistService.getApp(withId: appId) != nil {
                throw AddAppError.appAlreadyExists
            }
            
            // Add app via service
            let newApp = try await wishlistService.addAppFromURL(cleanURL)
            
            // Success handling
            addedApp = newApp
            showingSuccessAlert = true
            
            // Haptic feedback
            triggerHapticFeedback(.success)
            
        } catch let error as AddAppError {
            handleAddAppError(error)
        } catch let error as WishlistError {
            handleWishlistError(error)
        } catch {
            handleGenericError(error)
        }
        
        isLoading = false
    }
    
    private func pasteFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string,
              clipboardString.isValidAppStoreURL else { return }
        
        urlText = clipboardString
        triggerHapticFeedback(.light)
    }
    
    private func clearForm() {
        urlText = ""
        errorMessage = nil
        addedApp = nil
    }
    
    private func checkClipboardOnAppear() {
        // Auto-suggest clipboard URL if it's a valid App Store URL
        if hasClipboardURL && urlText.isEmpty {
            // Don't auto-paste, just make the button prominent
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAddAppError(_ error: AddAppError) {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
        triggerHapticFeedback(.error)
    }
    
    private func handleWishlistError(_ error: WishlistError) {
        errorMessage = error.localizedDescription
        showingErrorAlert = true
        triggerHapticFeedback(.error)
    }
    
    private func handleGenericError(_ error: Error) {
        errorMessage = "Failed to add app: \(error.localizedDescription)"
        showingErrorAlert = true
        triggerHapticFeedback(.error)
    }
    
    private func triggerHapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard userSettings.hapticFeedbackEnabled else { return }
        
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        @unknown default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Supporting Views

struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.app.fill")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            
            Text("Add App to Wishlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Paste an App Store URL to start tracking prices")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct URLInputSection: View {
    @Binding var urlText: String
    let hasClipboardURL: Bool
    let onPasteFromClipboard: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // URL Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("App Store URL")
                    .font(.headline)
                
                TextField("https://apps.apple.com/app/...", text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .submitLabel(.done)
            }
            
            // Paste from Clipboard Button
            if hasClipboardURL {
                Button(action: onPasteFromClipboard) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste from Clipboard")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // URL Validation Feedback
            URLValidationFeedback(urlText: urlText)
        }
    }
}

struct URLValidationFeedback: View {
    let urlText: String
    
    private var validationState: ValidationState {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .empty
        }
        
        if trimmed.isValidAppStoreURL {
            return .valid
        }
        
        return .invalid
    }
    
    var body: some View {
        HStack {
            Image(systemName: validationState.iconName)
                .foregroundColor(validationState.color)
            
            Text(validationState.message)
                .font(.caption)
                .foregroundColor(validationState.color)
            
            Spacer()
        }
        .opacity(validationState == .empty ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: validationState)
    }
    
    enum ValidationState: Equatable {
        case empty, valid, invalid
        
        var iconName: String {
            switch self {
            case .empty: return ""
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .empty: return .clear
            case .valid: return .green
            case .invalid: return .red
            }
        }
        
        var message: String {
            switch self {
            case .empty: return ""
            case .valid: return "Valid App Store URL"
            case .invalid: return "Please enter a valid App Store URL"
            }
        }
    }
}

struct ActionButtonsSection: View {
    let isValidInput: Bool
    let isLoading: Bool
    let onAddApp: () async -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Add App Button
            Button(action: {
                Task { await onAddApp() }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(isLoading ? "Adding App..." : "Add to Wishlist")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidInput && !isLoading ? Color.accentColor : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValidInput || isLoading)
            
            // Cancel Button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .disabled(isLoading)
        }
    }
}

struct HelpSection: View {
    @State private var showingHelpSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(spacing: 12) {
                Text("How to find App Store URLs")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HelpStep(
                        number: "1",
                        text: "Open the App Store app"
                    )
                    
                    HelpStep(
                        number: "2",
                        text: "Find the app you want to track"
                    )
                    
                    HelpStep(
                        number: "3",
                        text: "Tap the share button and copy the link"
                    )
                    
                    HelpStep(
                        number: "4",
                        text: "Return here and paste the URL"
                    )
                }
            }
            
            Button("View Supported URL Formats") {
                showingHelpSheet = true
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
        .sheet(isPresented: $showingHelpSheet) {
            URLFormatsHelpView()
        }
    }
}

struct HelpStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct URLFormatsHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let supportedFormats = [
        "https://apps.apple.com/us/app/app-name/id123456789",
        "https://apps.apple.com/app/id123456789",
        "https://itunes.apple.com/us/app/app-name/id123456789",
        "itms-apps://itunes.apple.com/app/id123456789"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("The following URL formats are supported:")
                        .font(.body)
                        .padding(.bottom, 8)
                    
                    ForEach(supportedFormats, id: \.self) { format in
                        Text(format)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.vertical, 4)
                            .textSelection(.enabled)
                    }
                } header: {
                    Text("Supported URL Formats")
                }
                
                Section {
                    Text("The app automatically extracts the app ID from these URLs and fetches the latest information from the App Store.")
                        .font(.body)
                } header: {
                    Text("How It Works")
                }
            }
            .navigationTitle("URL Formats")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Add App Errors

enum AddAppError: LocalizedError {
    case invalidURL
    case noAppIdFound
    case appAlreadyExists
    case networkError
    case appNotFoundInStore
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Please enter a valid App Store URL"
        case .noAppIdFound:
            return "Could not find app ID in the URL"
        case .appAlreadyExists:
            return "This app is already in your wishlist"
        case .networkError:
            return "Network error. Please check your connection and try again"
        case .appNotFoundInStore:
            return "App not found in the App Store"
        }
    }
}

// MARK: - Preview Provider

struct AddAppView_Previews: PreviewProvider {
    static var previews: some View {
        AddAppView()
            .environmentObject(WishlistService.shared)
    }
}
