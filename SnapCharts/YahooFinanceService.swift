//
//  YahooFinanceService.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import Foundation
import Combine

struct StockBar: Codable, Identifiable {
    var id: Date { t }
    let t: Date // Time
    let o: Double // Open
    let h: Double // High
    let l: Double // Low
    let c: Double // Close
    let v: Double // Volume
}

struct StockAsset: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String?
    let exchange: String?
    let type: String?
}

// MARK: - Yahoo Finance Response Models

struct YahooSearchResponse: Codable {
    let quotes: [YahooQuote]
}

struct YahooQuote: Codable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let exchange: String?
    let typeDisp: String?
    // Add other fields if needed
}

struct YahooChartResponse: Codable {
    let chart: YahooChart
}

struct YahooChart: Codable {
    let result: [YahooChartResult]?
    let error: YahooChartError?
}

struct YahooChartError: Codable {
    let code: String
    let description: String
}

struct YahooChartResult: Codable {
    let meta: YahooChartMeta
    let timestamp: [TimeInterval]?
    let indicators: YahooChartIndicators
}

struct YahooChartMeta: Codable {
    let currency: String?
    let symbol: String
    let exchangeName: String?
    let instrumentType: String?
    let firstTradeDate: TimeInterval?
    let regularMarketTime: TimeInterval?
    let gmtoffset: Int?
    let timezone: String?
}

struct YahooChartIndicators: Codable {
    let quote: [YahooChartQuote]
}

struct YahooChartQuote: Codable {
    let open: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let close: [Double?]?
    let volume: [Double?]?
}

// MARK: - Yahoo Finance Service

class YahooFinanceService: ObservableObject {
    static let shared = YahooFinanceService()
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        // Yahoo Finance sometimes requires a User-Agent to prevent 403 Forbidden
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ]
        self.session = URLSession(configuration: config)
    }
    
    /// Fetches historical data (OHLCV) for a given symbol.
    /// - Parameters:
    ///   - symbol: The stock ticker (e.g., "AAPL").
    ///   - range: The range of data to fetch (e.g., "1d", "5d", "1mo", "1y", "max"). Defaults to "1mo".
    func getBars(symbol: String, range: String = "1mo") async throws -> [StockBar] {
        let interval = getIntervalForRange(range)
        
        // URL: https://query1.finance.yahoo.com/v8/finance/chart/{symbol}
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)")
        components?.queryItems = [
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "range", value: range)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("Yahoo API Error: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        let chartResponse = try JSONDecoder().decode(YahooChartResponse.self, from: data)
        
        guard let result = chartResponse.chart.result?.first else {
            if let error = chartResponse.chart.error {
                print("Yahoo Chart Error: \(error.description)")
            }
            return []
        }
        
        return parseYahooResultToStockBars(result)
    }
    
    /// Searches for assets using Yahoo Finance auto-complete.
    func searchAssets(query: String) async throws -> [StockAsset] {
        guard !query.isEmpty else { return [] }
        
        // URL: https://query1.finance.yahoo.com/v1/finance/search
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v1/finance/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "quotesCount", value: "20"),
            URLQueryItem(name: "newsCount", value: "0"),
            URLQueryItem(name: "enableFuzzyQuery", value: "true")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let searchResponse = try JSONDecoder().decode(YahooSearchResponse.self, from: data)
        
        // Map YahooQuote to StockAsset
        return searchResponse.quotes.map { quote in
            StockAsset(
                symbol: quote.symbol,
                name: quote.shortname ?? quote.longname ?? quote.symbol,
                exchange: quote.exchange,
                type: quote.typeDisp
            )
        }
    }
    
    // MARK: - Helpers
    
    private func getIntervalForRange(_ range: String) -> String {
        switch range {
        case "1d": return "5m"
        case "5d": return "15m"
        case "1mo": return "90m" // or 1d
        case "3mo": return "1d"
        case "6mo": return "1d"
        case "1y": return "1d"
        case "2y": return "1wk"
        case "5y": return "1wk"
        case "10y": return "1mo"
        case "ytd": return "1d"
        case "max": return "3mo"
        default: return "1d"
        }
    }
    
    private func parseYahooResultToStockBars(_ result: YahooChartResult) -> [StockBar] {
        guard let timestamps = result.timestamp,
              let quote = result.indicators.quote.first,
              let opens = quote.open,
              let highs = quote.high,
              let lows = quote.low,
              let closes = quote.close,
              let volumes = quote.volume else {
            return []
        }
        
        var bars: [StockBar] = []
        
        for i in 0..<timestamps.count {
            // Check for nil values (market closures or gaps)
            if i < opens.count, i < highs.count, i < lows.count, i < closes.count, i < volumes.count,
               let o = opens[i], let h = highs[i], let l = lows[i], let c = closes[i], let v = volumes[i] {
                
                let date = Date(timeIntervalSince1970: timestamps[i])
                bars.append(StockBar(t: date, o: o, h: h, l: l, c: c, v: v))
            }
        }
        
        return bars
    }
}
