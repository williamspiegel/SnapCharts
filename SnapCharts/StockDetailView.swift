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
            // Header: Company Name & Symbol
            VStack(spacing: 5) {
                Text(name ?? symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.top)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading Chart...")
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                Text(error)
                    .foregroundColor(.red)
                Spacer()
            } else if viewModel.bars.isEmpty {
                Spacer()
                Text("No data available for \(symbol)")
                Spacer()
            } else {
                if let lastBar = viewModel.bars.last {
                    VStack(alignment: .center) {
                        Text(String(format: "$%.2f", lastBar.c))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Current Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                
                StockChart(bars: viewModel.bars)
                    .frame(maxHeight: .infinity)
            }
            
            // Range Picker
            Picker("Range", selection: $viewModel.selectedRange) {
                Text("1D").tag("1d")
                Text("1W").tag("5d")
                Text("1M").tag("1mo")
                Text("3M").tag("3mo")
                Text("1Y").tag("1y")
                Text("All").tag("max")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: viewModel.selectedRange) { newRange in
                Task {
                    await viewModel.loadBars(symbol: symbol, range: newRange)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
            // Initial load using default range or whatever is in viewModel
            await viewModel.loadBars(symbol: symbol)
        }
    }
}
