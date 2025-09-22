//
//  PriceView.swift
//  WishDirectory
//
//  Created by Development Team on 23.09.2025.
//

import SwiftUI

// MARK: - Price View

struct PriceView: View {
    // MARK: - Properties
    let currentPrice: Double
    let originalPrice: Double?
    let currency: String
    let formattedPrice: String?
    var style: PriceDisplayStyle = .standard
    var showSavings: Bool = true
    var alignment: HorizontalAlignment = .leading
    
    // MARK: - Computed Properties
    
    private var isFree: Bool {
        return currentPrice == 0
    }
    
    private var isOnSale: Bool {
        guard let originalPrice = originalPrice else { return false }
        return currentPrice < originalPrice && currentPrice >= 0
    }
    
    private var discountAmount: Double {
        guard let originalPrice = originalPrice, isOnSale else { return 0 }
        return originalPrice - currentPrice
    }
    
    private var discountPercentage: Double {
        guard let originalPrice = originalPrice, originalPrice > 0, isOnSale else { return 0 }
        return ((originalPrice - currentPrice) / originalPrice) * 100
    }
    
    private var currentPriceText: String {
        if isFree {
            return "Free"
        }
        
        if let formattedPrice = formattedPrice {
            return formattedPrice
        }
        
        return formatPrice(currentPrice)
    }
    
    private var originalPriceText: String? {
        guard let originalPrice = originalPrice, isOnSale, !isFree else { return nil }
        return formatPrice(originalPrice)
    }
    
    private var savingsText: String {
        return formatPrice(discountAmount)
    }
    
    private var discountColor: Color {
        switch discountPercentage {
        case 0..<10:
            return .blue
        case 10..<25:
            return .orange
        case 25..<50:
            return .red
        case 50...:
            return .purple
        default:
            return .gray
        }
    }
    
    // MARK: - Main Body
    
    var body: some View {
        VStack(alignment: alignment, spacing: style.spacing) {
            switch style {
            case .standard:
                StandardPriceView()
            case .compact:
                CompactPriceView()
            case .detailed:
                DetailedPriceView()
            case .badge:
                BadgePriceView()
            case .large:
                LargePriceView()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Style Variants
    
    @ViewBuilder
    private func StandardPriceView() -> some View {
        HStack(spacing: 6) {
            // Current Price
            Text(currentPriceText)
                .font(.subheadline)
                .fontWeight(isOnSale ? .semibold : .medium)
                .foregroundColor(priceTextColor)
            
            // Original Price (strikethrough)
            if let originalPriceText = originalPriceText {
                Text(originalPriceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough()
            }
            
            // Discount Badge
            if isOnSale && showSavings {
                DiscountBadge(
                    percentage: discountPercentage,
                    color: discountColor,
                    style: .small
                )
            }
        }
    }
    
    @ViewBuilder
    private func CompactPriceView() -> some View {
        HStack(spacing: 4) {
            Text(currentPriceText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(priceTextColor)
            
            if isOnSale && showSavings {
                Text("-\(Int(discountPercentage))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(discountColor)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
    
    @ViewBuilder
    private func DetailedPriceView() -> some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(spacing: 8) {
                Text(currentPriceText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(priceTextColor)
                
                if let originalPriceText = originalPriceText {
                    Text(originalPriceText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
            
            if isOnSale && showSavings {
                HStack(spacing: 4) {
                    DiscountBadge(
                        percentage: discountPercentage,
                        color: discountColor,
                        style: .medium
                    )
                    
                    Text("Save \(savingsText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func BadgePriceView() -> some View {
        ZStack {
            if isOnSale {
                VStack(spacing: 2) {
                    Text(currentPriceText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("-\(Int(discountPercentage))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(discountColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(currentPriceText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    @ViewBuilder
    private func LargePriceView() -> some View {
        VStack(alignment: alignment, spacing: 6) {
            HStack(spacing: 12) {
                Text(currentPriceText)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(priceTextColor)
                
                if let originalPriceText = originalPriceText {
                    Text(originalPriceText)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
            
            if isOnSale && showSavings {
                HStack(spacing: 8) {
                    DiscountBadge(
                        percentage: discountPercentage,
                        color: discountColor,
                        style: .large
                    )
                    
                    VStack(alignment: alignment, spacing: 2) {
                        Text("You save")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(savingsText)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var priceTextColor: Color {
        if isFree {
            return .green
        } else if isOnSale {
            return .orange
        } else {
            return .primary
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = currentPriceText
        
        if isOnSale, let originalPriceText = originalPriceText {
            label += ", on sale from \(originalPriceText)"
            if showSavings {
                label += ", \(Int(discountPercentage)) percent off, save \(savingsText)"
            }
        }
        
        return label
    }
    
    // MARK: - Helper Methods
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        // Handle different locales
        if let currencySymbol = Locale.current.currencySymbol,
           currency == Locale.current.currencyCode {
            formatter.locale = Locale.current
        } else {
            // Use US locale as fallback for consistent formatting
            formatter.locale = Locale(identifier: "en_US")
            formatter.currencyCode = currency
        }
        
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price, specifier: "%.2f")"
    }
}

// MARK: - Supporting Views

struct DiscountBadge: View {
    let percentage: Double
    let color: Color
    let style: BadgeStyle
    
    enum BadgeStyle {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 1, leading: 3, bottom: 1, trailing: 3)
            case .medium: return EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4)
            case .large: return EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }
    
    var body: some View {
        Text("-\(Int(percentage))%")
            .font(style.font)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(style.padding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
}

// MARK: - Price Display Style

enum PriceDisplayStyle {
    case standard    // Default inline display
    case compact     // Minimal space usage
    case detailed    // Full information with savings
    case badge       // Badge-style display
    case large       // Prominent display for detail views
    
    var spacing: CGFloat {
        switch self {
        case .standard, .compact: return 4
        case .detailed, .badge: return 6
        case .large: return 8
        }
    }
}

// MARK: - Convenience Initializers

extension PriceView {
    /// Initialize from WishlistApp
    init(
        app: WishlistApp,
        style: PriceDisplayStyle = .standard,
        showSavings: Bool = true,
        alignment: HorizontalAlignment = .leading
    ) {
        self.currentPrice = app.currentPrice
        self.originalPrice = app.originalPrice
        self.currency = app.currency
        self.formattedPrice = app.formattedPrice
        self.style = style
        self.showSavings = showSavings
        self.alignment = alignment
    }
    
    /// Initialize with basic price information
    init(
        currentPrice: Double,
        originalPrice: Double? = nil,
        currency: String = "USD",
        style: PriceDisplayStyle = .standard
    ) {
        self.currentPrice = currentPrice
        self.originalPrice = originalPrice
        self.currency = currency
        self.formattedPrice = nil
        self.style = style
        self.showSavings = true
        self.alignment = .leading
    }
}

// MARK: - Price Comparison View

struct PriceComparisonView: View {
    let currentPrice: Double
    let lowestPrice: Double?
    let highestPrice: Double?
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price History")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    PriceView(
                        currentPrice: currentPrice,
                        currency: currency,
                        style: .compact
                    )
                }
                
                Spacer()
                
                if let lowestPrice = lowestPrice {
                    VStack(alignment: .center, spacing: 4) {
                        Text("Lowest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        PriceView(
                            currentPrice: lowestPrice,
                            currency: currency,
                            style: .compact
                        )
                    }
                }
                
                Spacer()
                
                if let highestPrice = highestPrice {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Highest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        PriceView(
                            currentPrice: highestPrice,
                            currency: currency,
                            style: .compact
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview Provider

struct PriceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                // Free app
                PriceView(currentPrice: 0, currency: "USD", style: .standard)
                
                // Regular priced app
                PriceView(currentPrice: 4.99, currency: "USD", style: .standard)
                
                // App on sale
                PriceView(
                    currentPrice: 1.99,
                    originalPrice: 4.99,
                    currency: "USD",
                    style: .standard
                )
                
                // Detailed style
                PriceView(
                    currentPrice: 0.99,
                    originalPrice: 9.99,
                    currency: "USD",
                    style: .detailed
                )
                
                // Badge style
                PriceView(
                    currentPrice: 2.99,
                    originalPrice: 9.99,
                    currency: "USD",
                    style: .badge
                )
                
                // Large style
                PriceView(
                    currentPrice: 1.99,
                    originalPrice: 19.99,
                    currency: "USD",
                    style: .large
                )
                
                // Price comparison
                PriceComparisonView(
                    currentPrice: 4.99,
                    lowestPrice: 0.99,
                    highestPrice: 9.99,
                    currency: "USD"
                )
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
