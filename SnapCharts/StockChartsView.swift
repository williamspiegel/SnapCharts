//
//  StockChartsView.swift
//  SnapCharts
//
//  Created by William Spiegel on 12/17/25.
//

import SwiftUI
import DGCharts

struct StockChart: UIViewRepresentable {
    let bars: [StockBar]
    
    func makeUIView(context: Context) -> DGCharts.CandleStickChartView {
        let chartView = DGCharts.CandleStickChartView()
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        chartView.legend.enabled = false
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        // Avoid skipping labels if possible, but for large datasets it might be needed.
        // chartView.xAxis.forceLabelsEnabled = true 
        
        chartView.rightAxis.enabled = true
        chartView.leftAxis.enabled = false
        chartView.rightAxis.drawGridLinesEnabled = true
        
        // Basic styling
        chartView.chartDescription.enabled = false
        
        return chartView
    }
    
    func updateUIView(_ uiView: DGCharts.CandleStickChartView, context: Context) {
        guard !bars.isEmpty else {
            uiView.data = nil
            return
        }
        
        // Update X-Axis formatter with new bars
        let dateFormatter = DateValueFormatter(bars: bars)
        uiView.xAxis.valueFormatter = dateFormatter
        
        let entries = bars.enumerated().map { (index, bar) in
            CandleChartDataEntry(x: Double(index), shadowH: bar.h, shadowL: bar.l, open: bar.o, close: bar.c)
        }
        
        let dataSet = CandleChartDataSet(entries: entries, label: "Data")
        dataSet.axisDependency = .right
        dataSet.setColor(.label)
        dataSet.shadowColor = .label
        dataSet.shadowWidth = 0.7
        dataSet.decreasingColor = .systemRed
        dataSet.decreasingFilled = true
        dataSet.increasingColor = .systemGreen
        dataSet.increasingFilled = true
        dataSet.neutralColor = .systemBlue
        dataSet.drawValuesEnabled = false
        
        let data = CandleChartData(dataSet: dataSet)
        uiView.data = data
        uiView.notifyDataSetChanged()
    }
    
    class DateValueFormatter: AxisValueFormatter {
        let bars: [StockBar]
        private let dateFormatter: DateFormatter
        
        init(bars: [StockBar]) {
            self.bars = bars
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "MM/dd" // Short date format
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let index = Int(value)
            guard index >= 0 && index < bars.count else { return "" }
            return dateFormatter.string(from: bars[index].t)
        }
    }
}
