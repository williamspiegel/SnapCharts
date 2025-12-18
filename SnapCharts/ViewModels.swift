//
//  ViewModels.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import Foundation
import Combine
import CoreData

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [StockAsset] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $query
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self else { return }
                if !searchText.isEmpty {
                    Task {
                        await self.performSearch(searchText)
                    }
                } else {
                    self.results = []
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(_ text: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let assets = try await YahooFinanceService.shared.searchAssets(query: text)
            self.results = assets
        } catch {
            self.errorMessage = "Failed to search: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

@MainActor
class StockDetailViewModel: ObservableObject {
    @Published var bars: [StockBar] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadBars(symbol: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedBars = try await YahooFinanceService.shared.getBars(symbol: symbol)
            self.bars = fetchedBars
        } catch {
            self.errorMessage = "Failed to load chart: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func isFavorited(symbol: String, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<SavedStock> = SavedStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    func toggleFavorite(symbol: String, name: String?, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<SavedStock> = SavedStock.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "symbol == %@", symbol)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existing = results.first {
                // Remove
                context.delete(existing)
            } else {
                // Add
                let newStock = SavedStock(context: context)
                newStock.symbol = symbol
                newStock.name = name
                newStock.timestamp = Date()
            }
            try context.save()
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
}
