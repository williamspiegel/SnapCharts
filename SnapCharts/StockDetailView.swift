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
    @State private var selectedBar: StockBar?
    
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
                    let displayBar = selectedBar ?? lastBar
                    VStack(alignment: .center) {
                        Text(String(format: "$%.2f", displayBar.c))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let selected = selectedBar {
                            Text("Price at \(formatDate(selected.t))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Text("O: \(String(format: "%.2f", selected.o))")
                                Text("H: \(String(format: "%.2f", selected.h))")
                                Text("L: \(String(format: "%.2f", selected.l))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        } else {
                            Text("Current Price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top)
                }
                
                StockChart(bars: viewModel.bars, selectedBar: $selectedBar)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
