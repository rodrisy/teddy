import SwiftUI

struct SleepView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack {
            if healthManager.sleepSegments.isEmpty {
                Text("No sleep data available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                SleepChartView(segments: healthManager.sleepSegments)
            }
        }
        .navigationTitle("Sleep Data")
        .padding()
    }
}

#Preview {
    SleepView()
        .environmentObject(HealthManager()) // Provide a preview environment object
}
