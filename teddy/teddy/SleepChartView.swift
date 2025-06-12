//
//  SleepChartView.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 11/6/25.
//

import SwiftUI
import Charts

struct SleepChartView: View {
    let segments: [SleepSegment]

    var body: some View {
        Chart(segments) { segment in
            BarMark(
                xStart: .value("Start", segment.start),
                xEnd: .value("End", segment.end),
                y: .value("Stage", "Sleep")
            )
            .clipShape(Capsule())
            .foregroundStyle(segment.stage.color)
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 1)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
            }
        }
        .frame(height: 60)
        .padding(.horizontal)
    }
}
