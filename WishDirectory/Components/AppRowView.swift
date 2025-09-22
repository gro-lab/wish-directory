//
//  AppRowView.swift
//  WishDirectory
//
//  Created by Development Team on 23.09.2025.
//

import SwiftUI

// MARK: - App Row View

struct AppRowView: View {
    // MARK: - Properties
    let app: WishlistApp
    var onTap: (() -> Void)? = nil
    var showLastChecked: Bool = false
    
    // MARK: - State
    @StateObject private var userSettings = UserSettings.shared
    @State private var iconLoadFailed = false
    
    // MARK: - Computed Properties
    
    private var priceDisplayText: String {
        if app.isFree {
            return "Free"
        }
        
        if let formattedPrice = app.formattedPrice {
            return formattedPrice
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = app.currency
        return formatter.string(from: NSNumber(value: app.currentPrice)) ?? "$\(app.currentPrice, specifier: "%.2f")"
    }
    
    private var originalPriceText: String? {
        guard app.isOnSale && !app.wasOriginallyFree else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = app.currency
        return formatter.string(from: NSNumber(value: app.originalPrice))
    }
    
    private var savingsText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = app.currency
        return formatter.string(from: NSNumber(value: app.discountAmount)) ?? "$\(app.discountAmount, specifier: "%.2f")"
    }
    
    private var lastCheckedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: app.lastChecked, relativeTo: Date())
    }
    
    private var needsUpdateIndicator: Bool {
        return app.needsPriceUpdate
    }
    
    // MARK: - Main Body
    
    var body: some View {
        Button(action: {
            onTap?()
            triggerHapticFeedback()
        }) {
            HStack(spacing: 12) {
                // App Icon
                AppIconView(
                    iconURL: app.bestIconURL,
                    iconLoadFailed: $iconLoadFailed
                )
                
                // App Information
                VStack(alignment: .leading, spacing: 4) {
                    // App Name
                    Text(app.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    // Developer Name
                    Text(app.developer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    // Price and Discount Information
                    PriceInfoView(
                        currentPrice: priceDisplayText,
                        originalPrice: originalPriceText,
                        isOnSale: app.isOnSale,
                        discountPercentage: app.discountPercentage,
                        isFree: app.isFree
                    )
                    
                    // Last Checked or Additional Info
                    if showLastChecked || needsUpdateIndicator {
                        LastCheckedView(
                            lastCheckedText: lastCheckedText,
                            needsUpdate: needsUpdateIndicator
                        )
                    }
                }
                
                Spacer()
                
                // Right Side Indicators
                VStack(alignment: .trailing, spacing: 8) {
                    // Price Drop Badge
                    if app.isOnSale {
                        PriceDropBadge(
                            discountPercentage: app.discountPercentage,
                            savingsText: savingsText
                        )
                    }
                    
                    // Navigation Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(AppRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to view app details")
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = "\(app.name) by \(app.developer), \(priceDisplayText)"
        
        if app.isOnSale {
            label += ", on sale, \(Int(app.discountPercentage))% off, was \(originalPriceText ?? "")"
        }
        
        if needsUpdateIndicator {
            label += ", price needs update"
        }
        
        return label
    }
    
    // MARK: - Helper Methods
    
    private func triggerHapticFeedback() {
        guard userSettings.hapticFeedbackEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Supporting Views

struct AppIconView: View {
    let iconURL: String
    @Binding var iconLoadFailed: Bool
    
    var body: some View {
        AsyncImage(url: URL(string: iconURL)) { phase in
            switch phase {
            case .empty:
                IconPlaceholder(isLoading: true)
                
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onAppear {
                        iconLoadFailed = false
                    }
                    
            case .failure(_):
                IconPlaceholder(isLoading: false)
                    .onAppear {
                        iconLoadFailed = true
                    }
                    
            @unknown default:
                IconPlaceholder(isLoading: false)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

struct IconPlaceholder: View {
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            } else {
                Image(systemName: "app.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PriceInfoView: View {
    let currentPrice: String
    let originalPrice: String?
    let isOnSale: Bool
    let discountPercentage: Double
    let isFree: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            // Current Price
            Text(currentPrice)
                .font(.subheadline)
                .fontWeight(isOnSale ? .semibold : .medium)
                .foregroundColor(isFree ? .green : (isOnSale ? .orange : .primary))
            
            // Original Price (if on sale)
            if let originalPrice = originalPrice, isOnSale {
                Text(originalPrice)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough()
            }
            
            Spacer()
        }
    }
}

struct PriceDropBadge: View {
    let discountPercentage: Double
    let savingsText: String
    
    private var badgeColor: Color {
        switch discountPercentage {
        case 0..<10:
            return .blue
        case 10..<25:
            return .orange
        case 25..<50:
            return .red
        default:
            return .purple
        }
    }
    
    private var displayText: String {
        if discountPercentage >= 1 {
            return "-\(Int(discountPercentage))%"
        } else {
            return "Sale"
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Percentage Badge
            Text(displayText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(badgeColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Savings Amount
            if discountPercentage >= 1 {
                Text("Save \(savingsText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LastCheckedView: View {
    let lastCheckedText: String
    let needsUpdate: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if needsUpdate {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.caption2)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
            
            Text("Updated \(lastCheckedText)")
                .font(.caption2)
                .foregroundColor(needsUpdate ? .orange : .tertiary)
        }
    }
}

// MARK: - Button Style

struct AppRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color(.systemGray6) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Layout Variants

extension AppRowView {
    /// Compact variant for dense lists
    static func compact(app: WishlistApp, onTap: (() -> Void)? = nil) -> some View {
        CompactAppRowView(app: app, onTap: onTap)
    }
}

struct CompactAppRowView: View {
    let app: WishlistApp
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 10) {
                // Smaller App Icon
                AsyncImage(url: URL(string: app.bestIconURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: "app.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // App Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(app.developer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Price and Discount
                VStack(alignment: .trailing, spacing: 2) {
                    if app.isOnSale {
                        Text("-\(Int(app.discountPercentage))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    
                    Text(app.formattedPrice ?? "$\(app.currentPrice, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(app.isOnSale ? .orange : .primary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .buttonStyle(AppRowButtonStyle())
    }
}

// MARK: - Preview Provider

struct AppRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Regular app
            AppRowView(app: .mockApp)
            
            // Free app
            AppRowView(app: .mockFreeApp)
            
            // App on sale
            AppRowView(app: .mockSaleApp, showLastChecked: true)
            
            // Compact variant
            AppRowView.compact(app: .mockSaleApp)
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
