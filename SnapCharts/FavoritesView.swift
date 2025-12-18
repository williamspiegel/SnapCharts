//
//  FavoritesView.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import SwiftUI
import CoreData

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedStock.timestamp, ascending: false)],
        animation: .default)
    private var favorites: FetchedResults<SavedStock>

    var body: some View {
        NavigationView {
            List {
                ForEach(favorites) { stock in
                    NavigationLink(destination: StockDetailView(symbol: stock.symbol ?? "", name: stock.name)) {
                        VStack(alignment: .leading) {
                            Text(stock.symbol ?? "Unknown").font(.headline)
                            if let name = stock.name {
                                Text(name).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { favorites[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
