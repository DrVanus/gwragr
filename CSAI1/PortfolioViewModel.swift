import SwiftUI
import Combine

class PortfolioViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var holdings: [Holding] = []
    @Published var transactions: [Transaction] = []
    @Published var editingTransaction: Transaction? = nil

    // Computed property for total portfolio value.
    var totalValue: Double {
        holdings.reduce(0) { $0 + $1.currentValue }
    }
    
    // MARK: - Data Loading and Auto-Refresh
    
    /// Loads sample holdings data. Replace this with your data fetching logic.
    func loadHoldings() {
        holdings = [
            Holding(
                coinName: "Bitcoin",
                coinSymbol: "BTC",
                quantity: 1,
                currentPrice: 35000,
                costBasis: 20000,
                imageUrl: nil,
                isFavorite: true,
                dailyChange: 2.1,
                purchaseDate: Date()
            ),
            Holding(
                coinName: "Ethereum",
                coinSymbol: "ETH",
                quantity: 10,
                currentPrice: 1800,
                costBasis: 15000,
                imageUrl: nil,
                isFavorite: false,
                dailyChange: -1.2,
                purchaseDate: Date()
            ),
            Holding(
                coinName: "Solana",
                coinSymbol: "SOL",
                quantity: 100,
                currentPrice: 20,
                costBasis: 2000,
                imageUrl: nil,
                isFavorite: false,
                dailyChange: 3.5,
                purchaseDate: Date()
            )
        ]
    }
    
    // Timer to auto-refresh data periodically.
    private var timer: Timer?
    
    /// Starts a timer to refresh portfolio data every 60 seconds.
    func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.refreshPortfolioData()
            }
        }
    }
    
    /// Stops the auto-refresh timer.
    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Refreshes portfolio data. Replace with your network request or logic as needed.
    func refreshPortfolioData() async {
        // Simulate a refresh by reloading sample data.
        await MainActor.run {
            loadHoldings()
        }
    }
    
    // MARK: - Transaction and Holding Management
    
    /// Removes a holding at the given index set.
    func removeHolding(at indexSet: IndexSet) {
        holdings.remove(atOffsets: indexSet)
    }
    
    /// Deletes a manual transaction.
    func deleteManualTransaction(_ tx: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == tx.id && $0.isManual }) {
            transactions.remove(at: index)
        }
    }
    
    // MARK: - NEW: Add a Holding
    
    /// Creates and appends a new Holding to the array, matching what AddHoldingView calls.
    func addHolding(
        coinName: String,
        coinSymbol: String,
        quantity: Double,
        currentPrice: Double,
        costBasis: Double,
        imageUrl: String?,
        purchaseDate: Date
    ) {
        let newHolding = Holding(
            coinName: coinName,
            coinSymbol: coinSymbol,
            quantity: quantity,
            currentPrice: currentPrice,
            costBasis: costBasis,
            imageUrl: imageUrl,
            isFavorite: false,    // default to not-favorite
            dailyChange: 0.0,     // or fetch real data if available
            purchaseDate: purchaseDate
        )
        
        holdings.append(newHolding)
    }
    
    // MARK: - NEW: Toggle Favorite
    
    /// Toggles the isFavorite flag on a specific holding.
    /// This fixes the "no dynamic member 'toggleFavorite'" error in PortfolioCoinRow.
    func toggleFavorite(_ holding: Holding) {
        // Because Holding conforms to Equatable, we can locate it by 'id' or by '=='
        guard let index = holdings.firstIndex(where: { $0.id == holding.id }) else { return }
        holdings[index].isFavorite.toggle()
    }
}
