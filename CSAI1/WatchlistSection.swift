import SwiftUI

struct WatchlistSectionView: View {
    @EnvironmentObject var marketVM: MarketViewModel
    @Binding var isEditingWatchlist: Bool
    
    // Local state to control Show More / Show Less
    @State private var showAll = false
    
    // Compute the user’s watchlist (all favorites)
    private var liveWatchlist: [MarketCoin] {
        marketVM.coins.filter { $0.isFavorite }
    }
    
    // How many coins to show when collapsed
    private let maxVisible = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section heading
            sectionHeading("Your Watchlist", iconName: "eye")
            
            if liveWatchlist.isEmpty {
                emptyWatchlistView
            } else {
                // Show either all or the first maxVisible
                let coinsToShow = showAll ? liveWatchlist : Array(liveWatchlist.prefix(maxVisible))
                
                // Subtle background container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                    
                    // Use a List so we can reorder or swipe to remove
                    List {
                        ForEach(coinsToShow, id: \.id) { coin in
                            VStack(spacing: 0) {
                                rowContent(for: coin)
                                
                                // Slim gold separator
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 1)
                                    .listRowSeparator(.hidden)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: moveCoinInWatchlist)
                    }
                    .listStyle(.plain)
                    .listRowSpacing(0)
                    .scrollDisabled(true) // rely on showAll toggle
                    // Height is # of coins * ~45
                    .frame(
                        height: showAll
                            ? CGFloat(liveWatchlist.count) * 45
                            : CGFloat(maxVisible) * 45
                    )
                    .animation(.easeInOut, value: showAll)
                    // If editing is active, we can reorder
                    .environment(\.editMode, .constant(isEditingWatchlist ? .active : .inactive))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                
                // Show toggle button if we have more coins than maxVisible
                if liveWatchlist.count > maxVisible {
                    Button {
                        withAnimation(.spring()) {
                            showAll.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAll ? "Show Less" : "Show More")
                                .font(.callout)
                                .foregroundColor(.white)
                            
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white)
                                .font(.footnote)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
    
    // MARK: - Empty Watchlist
    private var emptyWatchlistView: some View {
        VStack(spacing: 16) {
            Text("No coins in your watchlist yet.")
                .font(.callout)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Row Content
    private func rowContent(for coin: MarketCoin) -> some View {
        HStack(spacing: 8) {
            // Left accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
            
            // Coin icon + details
            coinIconView(for: coin, size: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(formatPrice(coin.price))
                    .foregroundColor(.white.opacity(0.7))
                    .font(.footnote)
            }
            
            Spacer()
            
            // We’ll use dailyChange from your existing MarketCoin
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
                .font(.footnote)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        // Swipe to remove
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // If we find the coin in the main array, un-favorite it
                if let index = marketVM.coins.firstIndex(where: { $0.id == coin.id }) {
                    marketVM.coins[index].isFavorite = false
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Reordering
    private func moveCoinInWatchlist(from source: IndexSet, to destination: Int) {
        // Grab the subset of coins that are favorited
        var favorites = marketVM.coins.filter { $0.isFavorite }
        
        // Move them within that subset
        favorites.move(fromOffsets: source, toOffset: destination)
        
        // The rest are not favorites
        let nonFavorites = marketVM.coins.filter { !$0.isFavorite }
        
        // Combine them back
        marketVM.coins = nonFavorites + favorites
        
        // Optionally animate the reorder
        withAnimation(.spring()) {
            // This triggers a UI refresh
        }
    }
    
    // MARK: - Helpers
    private func formatPrice(_ value: Double) -> String {
        guard value > 0 else { return "$0.00" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if value < 1.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }
        return "$" + (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
    
    private func coinIconView(for coin: MarketCoin, size: CGFloat) -> some View {
        Group {
            if let imageUrl = coin.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle().fill(Color.gray.opacity(0.3))
                            .frame(width: size, height: size)
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle().fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
    }
    
    private func sectionHeading(_ text: String, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(.yellow)
                }
                Text(text)
                    .font(.title3).bold()
                    .foregroundColor(.white)
            }
            Divider()
                .background(Color.white.opacity(0.15))
        }
    }
}
