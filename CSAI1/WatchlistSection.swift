import SwiftUI

struct WatchlistSectionView: View {
    // We’ll use EnvironmentObject to access the MarketViewModel
    @EnvironmentObject var marketVM: MarketViewModel
    
    // These bindings come from the parent (HomeView) so we can toggle them there
    @Binding var showAllWatchlist: Bool
    @Binding var isEditingWatchlist: Bool

    // Compute the user’s watchlist
    private var liveWatchlist: [MarketCoin] {
        marketVM.coins.filter { $0.isFavorite }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title for the watchlist
            sectionHeading("Your Watchlist", iconName: "eye")

            // Decide how many coins to show
            let coinsToShow = showAllWatchlist
                ? liveWatchlist
                : Array(liveWatchlist.prefix(3))
            
            // A background card behind the List
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Our list of watchlist coins
                List {
                    ForEach(coinsToShow) { coin in
                        NavigationLink(destination: CoinDetailView(coin: coin)) {
                            watchlistRow(coin)
                        }
                        // Make the list rows blend in with the background
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    .onMove(perform: moveCoinInWatchlist)
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: showAllWatchlist ? 300 : 180)
                .environment(\.editMode, .constant(isEditingWatchlist ? .active : .inactive))
                .cornerRadius(10)
                .padding(.vertical, -8)
                .padding(.horizontal, -8)
            }
            .frame(maxWidth: .infinity)
            
            // If the watchlist has more than 3 coins, let user toggle Show More / Show Less
            if liveWatchlist.count > 3 {
                Button {
                    withAnimation(.spring()) {
                        showAllWatchlist.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllWatchlist ? "Show Less" : "Show More")
                            .font(.callout)
                            .foregroundColor(.white)
                        
                        Image(systemName: showAllWatchlist ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                            .font(.footnote)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Row UI
    private func watchlistRow(_ coin: MarketCoin) -> some View {
        HStack {
            coinIconView(for: coin, size: 24)
            
            Text(coin.symbol.uppercased())
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(formatPrice(coin.price))
                .foregroundColor(.white)
            
            Text("\(coin.dailyChange, specifier: "%.2f")%")
                .foregroundColor(coin.dailyChange >= 0 ? .green : .red)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.02))
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // Remove from watchlist by setting isFavorite = false
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
        // Take the favorites subset
        var favorites = marketVM.coins.filter { $0.isFavorite }
        // Move them within that subset
        favorites.move(fromOffsets: source, toOffset: destination)
        
        // The rest are not favorites
        let nonFavorites = marketVM.coins.filter { !$0.isFavorite }
        
        // Combine them back
        marketVM.coins = nonFavorites + favorites
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
                        image.resizable()
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
