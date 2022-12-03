//
//  EthPriceHistoryView.swift
//  ETHNFTTracker
//
//  Created by Jan on 10.11.22.
//

import SwiftUI
import Charts

struct EthPriceHistoryView: View {
    
    var body: some View {
        VStack {
            Text("ETH Price History (Minutes)")
                .padding(20)
            PriceChartView(elements: Env.shared.EthPriceHistoryMinutes.elements, timeElements: [Date().forAxis], granularity: 24)
            
            Divider()
            
            Text("ETH Price History (Daily)")
                .padding(20)
            PriceChartView(elements: Env.shared.EthPriceHistoryDaily.elements, timeElements: [Date().forAxis, Date().minusDays(15).forAxis, Date().minus30days.forAxis], granularity: 30)
        }
        .frame(width: 600, height: 600)
    }
}

struct PriceChartView: View {
    
    let elements: [Double]
    let timeElements: [String]
    let granularity: Int
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    let min = (elements.min() ?? 0.0)
                    let max = (elements.max() ?? 1.0)
                    CustomAxisLabels(.vertical, data: [min.rounded(FloatingPointRoundingRule.down), (max.rounded(FloatingPointRoundingRule.up) - min.rounded(FloatingPointRoundingRule.down)) / 2.0 + min.rounded(FloatingPointRoundingRule.down), max.rounded(FloatingPointRoundingRule.up)].reversed(), id: \.self) {
                        Text(String(format: "%.1f", $0))
                            .font(Font.system(size: 10))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40)
                }
                
                ZStack {
                    VStack {
                        Chart(data: elements.chartPrepared)
                            .chartStyle(
                                LineChartStyle(.quadCurve, lineColor: .pink, lineWidth: 2)
                            )
                            .background(
                                GridPattern(horizontalLines: 5, verticalLines: granularity)
                                    .stroke(Color.white.opacity(0.1), style: .init(lineWidth: 1, lineCap: .round))
                            )
                    }
                    VStack {
                        Chart(data: elements.chartPrepared)
                            .chartStyle(
                                AreaChartStyle(.quadCurve, fill:
                                                LinearGradient(gradient: .init(colors: [Color.pink.opacity(0.8), Color.pink.opacity(0.35)]), startPoint: .top, endPoint: .bottom)
                                              )
                            )
                    }
                }
            }
            
            //  horizontal axis
            CustomAxisLabels(.horizontal, data: timeElements, id: \.self) {
                Text("\($0)")
                    .font(Font.system(size: 10))
                    .foregroundColor(.white)
            }
            .padding(.leading, 50)
            .frame(height: 20)
        }
        .padding(10)
    }
}
