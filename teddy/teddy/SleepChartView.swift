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
        VStack(alignment: .leading) {
            Text("Sleep Stages")
            .font(.headline)
            .padding(.leading)
            Chart(segments.filter { $0.stage != .unknown }) { segment in
                BarMark(
                    xStart: .value("Start", segment.start),
                    xEnd: .value("End", segment.end),
                    y: .value("Stage", segment.stage.rawValue.capitalized)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(by: .value("Stage", segment.stage.rawValue.capitalized))
            }
            // Order Y-axis top-down: Awake → REM → Core → Deep
            .chartYScale(domain: ["Awake", "Rem", "Core", "Deep"])
            .chartForegroundStyleScale([
                "Awake": Color.yellow,
                "Rem": Color.purple,
                "Core": Color.blue,
                "Deep": Color.indigo
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)), centered: true)
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
            
        }
    }
}

