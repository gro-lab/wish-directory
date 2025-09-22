//
//  LoadingView.swift
//  WishDirectory
//
//  Created by Development Team on 23.09.2025.
//

import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    // MARK: - Properties
    let message: String
    var style: LoadingStyle = .standard
    var showBackground: Bool = true
    var tintColor: Color = .accentColor
    
    // MARK: - State
    @State private var isAnimating = false
    
    // MARK: - Main Body
    
    var body: some View {
        ZStack {
            // Background
            if showBackground {
                backgroundView
            }
            
            // Content
            VStack(spacing: style.spacing) {
                // Loading Indicator
                loadingIndicator
                
                // Message Text
                if !message.isEmpty {
                    Text(message)
                        .font(style.messageFont)
                        .foregroundColor(style.textColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(style.maxLines)
                }
            }
            .padding(style.padding)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundView: some View {
        Group {
            switch style {
            case .overlay:
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            case .card:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            case .inline, .compact:
                Color(.systemGray6)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .fullscreen:
                Color(.systemBackground)
                    .ignoresSafeArea()
            case .standard:
                EmptyView()
            }
        }
    }
    
    private var loadingIndicator: some View {
        Group {
            switch style {
            case .standard, .inline, .fullscreen:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
                    .scaleEffect(style.indicatorScale)
                
            case .compact:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
                    .scaleEffect(0.8)
                
            case .overlay, .card:
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
                        .scaleEffect(1.2)
                    
                    if style == .card {
                        Divider()
                            .opacity(0.5)
                    }
                }
            }
        }
    }
    
    private var accessibilityLabel: String {
        if message.isEmpty {
            return "Loading"
        } else {
            return "Loading: \(message)"
        }
    }
    
    // MARK: - Animation Methods
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAnimating = true
        }
    }
    
    private func stopAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isAnimating = false
        }
    }
}

// MARK: - Loading Style

enum LoadingStyle {
    case standard     // Simple indicator with text
    case compact      // Smaller indicator for tight spaces
    case inline       // Inline with content
    case overlay      // Full screen overlay
    case card         // Card-style with shadow
    case fullscreen   // Full screen without overlay
    
    var spacing: CGFloat {
        switch self {
        case .standard, .inline: return 12
        case .compact: return 6
        case .overlay, .card: return 16
        case .fullscreen: return 20
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .standard: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .compact: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .inline: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .overlay, .card: return EdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32)
        case .fullscreen: return EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
        }
    }
    
    var messageFont: Font {
        switch self {
        case .standard, .inline: return .subheadline
        case .compact: return .caption
        case .overlay, .card: return .headline
        case .fullscreen: return .title2
        }
    }
    
    var textColor: Color {
        switch self {
        case .overlay: return .white
        default: return .secondary
        }
    }
    
    var indicatorScale: CGFloat {
        switch self {
        case .standard, .inline: return 1.0
        case .compact: return 0.8
        case .overlay, .card: return 1.2
        case .fullscreen: return 1.5
        }
    }
    
    var maxLines: Int {
        switch self {
        case .compact: return 1
        case .standard, .inline: return 2
        case .overlay, .card, .fullscreen: return 3
        }
    }
}

// MARK: - Loading View Modifiers

extension View {
    /// Apply a loading overlay to any view
    func loadingOverlay(
        isLoading: Bool,
        message: String = "Loading...",
        style: LoadingStyle = .overlay
    ) -> some View {
        ZStack {
            self
            
            if isLoading {
                LoadingView(
                    message: message,
                    style: style,
                    showBackground: true
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
    
    /// Show loading state conditionally
    func loading(
        _ isLoading: Bool,
        message: String = "",
        style: LoadingStyle = .standard
    ) -> some View {
        Group {
            if isLoading {
                LoadingView(
                    message: message,
                    style: style
                )
                .transition(.opacity)
            } else {
                self
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Specialized Loading Views

struct NetworkLoadingView: View {
    let operation: NetworkOperation
    
    enum NetworkOperation {
        case fetchingApp
        case updatingPrices
        case searchingApps
        case loadingDetails
        
        var message: String {
            switch self {
            case .fetchingApp: return "Adding app to wishlist..."
            case .updatingPrices: return "Checking for price updates..."
            case .searchingApps: return "Searching App Store..."
            case .loadingDetails: return "Loading app details..."
            }
        }
        
        var icon: String {
            switch self {
            case .fetchingApp: return "plus.app"
            case .updatingPrices: return "arrow.clockwise"
            case .searchingApps: return "magnifyingglass"
            case .loadingDetails: return "info.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: operation.icon)
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
                .rotationEffect(.degrees(0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: true)
            
            LoadingView(
                message: operation.message,
                style: .standard,
                showBackground: false
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ProgressLoadingView: View {
    let progress: Double
    let message: String
    let total: Int?
    let current: Int?
    
    private var progressText: String {
        if let current = current, let total = total {
            return "\(current) of \(total)"
        }
        return "\(Int(progress * 100))%"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text(progressText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct PulsingLoadingView: View {
    let message: String
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Pulsing Dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isPulsing ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isPulsing
                        )
                }
            }
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Loading State Helper

struct LoadingStateView<Content: View>: View {
    let isLoading: Bool
    let loadingMessage: String
    let content: () -> Content
    
    init(
        isLoading: Bool,
        message: String = "Loading...",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.loadingMessage = message
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                LoadingView(
                    message: loadingMessage,
                    style: .overlay
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Convenience Initializers

extension LoadingView {
    /// Quick loading view for common operations
    static func priceUpdate() -> LoadingView {
        LoadingView(
            message: "Updating prices...",
            style: .standard,
            tintColor: .orange
        )
    }
    
    static func addingApp() -> LoadingView {
        LoadingView(
            message: "Adding app...",
            style: .card,
            tintColor: .green
        )
    }
    
    static func searching() -> LoadingView {
        LoadingView(
            message: "Searching...",
            style: .inline,
            showBackground: false
        )
    }
    
    static func compact(_ message: String = "") -> LoadingView {
        LoadingView(
            message: message,
            style: .compact,
            showBackground: false
        )
    }
}

// MARK: - Preview Provider

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard styles
            VStack(spacing: 30) {
                LoadingView(message: "Loading apps...", style: .standard)
                LoadingView(message: "Updating", style: .compact)
                LoadingView(message: "Searching App Store...", style: .inline)
            }
            .padding()
            .previewDisplayName("Standard Styles")
            
            // Card and overlay styles
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                LoadingView(
                    message: "Adding app to wishlist...",
                    style: .card
                )
            }
            .previewDisplayName("Card Style")
            
            // Specialized loading views
            VStack(spacing: 20) {
                NetworkLoadingView(operation: .updatingPrices)
                
                ProgressLoadingView(
                    progress: 0.65,
                    message: "Checking prices...",
                    total: 10,
                    current: 6
                )
                
                PulsingLoadingView(message: "Please wait...")
            }
            .padding()
            .previewDisplayName("Specialized Views")
            
            // Loading overlay example
            VStack {
                Text("Content behind loading overlay")
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .loadingOverlay(
                isLoading: true,
                message: "Loading...",
                style: .overlay
            )
            .previewDisplayName("Loading Overlay")
        }
    }
}
