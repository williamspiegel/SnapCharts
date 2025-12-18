//
//  StockDetailView.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import SwiftUI
import CoreData

struct StockDetailView: View {
    let symbol: String
    let name: String?
    
    @StateObject private var viewModel = StockDetailViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    // We use a FetchRequest just to monitor changes for the heart icon updates
    @FetchRequest var favorites: FetchedResults<SavedStock>
    
    init(symbol: String, name: String?) {
        self.symbol = symbol
        self.name = name
        _favorites = FetchRequest(
            entity: SavedStock.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "symbol == %@", symbol)
        )
    }
    
    var isFavorited: Bool {
        !favorites.isEmpty
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Chart...")
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else if viewModel.bars.isEmpty {
                Text("No data available for \(symbol)")
            } else {
                StockChart(bars: viewModel.bars)
                    .frame(maxHeight: .infinity)
            }
        }
        .navigationTitle(symbol)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.toggleFavorite(symbol: symbol, name: name, context: viewContext)
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : .gray)
                }
            }
        }
        .task {
            await viewModel.loadBars(symbol: symbol)
        }
    }
}
