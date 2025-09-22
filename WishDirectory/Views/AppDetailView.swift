//
//  AppDetailView.swift
//  WishDirectory
//
//  Created by Sprint 4 Implementation
//

import SwiftUI

struct AppDetailView: View {
    // MARK: - Properties
    let app: WishlistApp
    @StateObject private var wishlistService = WishlistService.shared
    @StateObject private var userSettings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var isUpdatingPrice = false
    @State private var showingRemoveAlert = false
    @State private var showingFullDescription = false
    @State private var selectedScreenshot: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - App Header
                AppHeaderSection(app: app)
                
                // MARK: - Action Buttons
                ActionButtonsSection(
                    app: app,
                    isUpdatingPrice: $isUpdatingPrice,
                    showingRemoveAlert: $showingRemoveAlert,
                    onOpenInStore: openInAppStore,
                    onUpdatePrice: updatePrice,
                    onRemove: { showingRemoveAlert = true }
                )
                
                // MARK: - Price Information
                PriceInformationSection(app: app)
                
                // MARK: - Screenshots
                if !app.screenshots.isEmpty {
                    ScreenshotsSection(
                        screenshots: app.screenshots,
                        selectedScreenshot: $selectedScreenshot
                    )
                }
                
                // MARK: - Description
                DescriptionSection(
                    description: app.description,
                    showingFull: $showingFullDescription
                )
                
                // MARK: - Price History Chart
                if app.priceHistory.count > 1 {
                    PriceHistorySection(app: app)
                }
                
                // MARK: - App Information
                AppInformationSection(app: app)
                
                // MARK: - Tags and Notes
                TagsAndNotesSection(app: app)
            }
            .padding()
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Remove from Wishlist", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeFromWishlist()
            }
        } message: {
            Text("Are you sure you want to remove \(app.name) from your wishlist?")
        }
        .sheet(item: Binding<ScreenshotItem?>(
            get: { selectedScreenshot.map { ScreenshotItem(url: $0) } },
            set: { selectedScreenshot = $0?.url }
        )) { item in
            FullScreenScreenshotView(imageURL: item.url)
        }
    }
    
    // MARK: - Actions
    
    private func openInAppStore() {
        guard let url = URL(string: app.storeURL) else { return }
        openURL(url)
    }
    
    private func updatePrice() {
        isUpdatingPrice = true
        Task {
            do {
                _ = try await wishlistService.updatePriceForApp(withId: app.id)
                await MainActor.run {
                    isUpdatingPrice = false
                }
            } catch {
                await MainActor.run {
                    isUpdatingPrice = false
                }
            }
        }
    }
    
    private func removeFromWishlist() {
        Task {
            do {
                try await wishlistService.removeApp(withId: app.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Header Section

struct AppHeaderSection: View {
    let app: WishlistApp
    
    var body: some View {
        HStack(spacing: 16) {
            // App Icon
            AsyncImage(url: URL(string: app.bestIconURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 120, height: 120)
            .cornerRadius(20)
            .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(app.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                Text(app.developer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let category = app.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                if let rating = app.averageRating {
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    let app: WishlistApp
    @Binding var isUpdatingPrice: Bool
    @Binding var showingRemoveAlert: Bool
    let onOpenInStore: () -> Void
    let onUpdatePrice: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onOpenInStore) {
                    Label("Open in App Store", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onUpdatePrice) {
                    if isUpdatingPrice {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Label("Update Price", systemImage: "arrow.clockwise")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isUpdatingPrice)
            }
            
            Button(action: onRemove) {
                Label("Remove from Wishlist", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Price Information Section

struct PriceInformationSection: View {
    let app: WishlistApp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Information")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if app.isFree {
                        Text("Free")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else {
                        Text(app.formattedPrice ?? "$\(app.currentPrice, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                if app.isOnSale {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("You Save")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text(app.formattedDiscountPercentage)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Text("$\(app.discountAmount, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding()
            .background(app.isOnSale ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            if app.isOnSale {
                HStack {
                    Text("Original Price:")
                        .foregroundColor(.secondary)
                    Text("$\(app.originalPrice, specifier: "%.2f")")
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .font(.caption)
            }
        }
    }
}

// MARK: - Screenshots Section

struct ScreenshotsSection: View {
    let screenshots: [String]
    @Binding var selectedScreenshot: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screenshots")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(screenshots, id: \.self) { screenshot in
                        AsyncImage(url: URL(string: screenshot)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .frame(width: 120, height: 213) // iPhone aspect ratio
                        .cornerRadius(12)
                        .onTapGesture {
                            selectedScreenshot = screenshot
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Description Section

struct DescriptionSection: View {
    let description: String
    @Binding var showingFull: Bool
    
    private var displayText: String {
        if showingFull || description.count <= 200 {
            return description
        } else {
            return String(description.prefix(200)) + "..."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            
            Text(displayText)
                .font(.body)
                .lineSpacing(4)
            
            if description.count > 200 {
                Button(showingFull ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFull.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Price History Section

struct PriceHistorySection: View {
    let app: WishlistApp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History")
                .font(.headline)
            
            // Simple price history chart
            VStack(spacing: 8) {
                ForEach(app.priceHistory.suffix(5), id: \.date) { pricePoint in
                    HStack {
                        Text(pricePoint.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(pricePoint.formattedPrice ?? "$\(pricePoint.price, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - App Information Section

struct AppInformationSection: View {
    let app: WishlistApp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let version = app.version {
                    InfoRow(label: "Version", value: version)
                }
                
                if let size = app.formattedSize {
                    InfoRow(label: "Size", value: size)
                }
                
                if let ageRating = app.ageRating {
                    InfoRow(label: "Age Rating", value: ageRating)
                }
                
                InfoRow(label: "Added to Wishlist", value: app.dateAdded.formatted(date: .abbreviated, time: .omitted))
                
                InfoRow(label: "Last Price Check", value: app.lastChecked.formatted(.relative(presentation: .named)))
            }
        }
    }
}

// MARK: - Tags and Notes Section

struct TagsAndNotesSection: View {
    let app: WishlistApp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !app.tags.isEmpty || app.notes != nil {
                Text("Personal")
                    .font(.headline)
                
                if !app.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                            ForEach(app.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                if let notes = app.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(notes)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

struct ScreenshotItem: Identifiable {
    let id = UUID()
    let url: String
}

struct FullScreenScreenshotView: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZoomableImageView(imageURL: imageURL)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ZoomableImageView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScaleValue
                                    lastScaleValue = value
                                    let newScale = scale * delta
                                    scale = min(max(newScale, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScaleValue = 1.0
                                    if scale < 1 {
                                        withAnimation(.spring()) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                },
                            
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        let newOffset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                        offset = newOffset
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1 {
                                scale = 1
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AppDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppDetailView(app: WishlistApp.mockSaleApp)
        }
    }
}
#endif
