//
//  SearchView.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search symbol (e.g. AAPL)", text: $viewModel.query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
                
                List(viewModel.results) { asset in
                    NavigationLink(destination: StockDetailView(symbol: asset.symbol, name: asset.name)) {
                        VStack(alignment: .leading) {
                            Text(asset.symbol).font(.headline)
                            if let name = asset.name {
                                Text(name).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}
