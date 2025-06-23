import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var usePatternBasedCycles: Bool
    @Binding var averageCycleMinutes: Int

    @ObservedObject var healthManager: HealthManager  // Add this!

    @State private var tempCycleMinutes: Double = 90
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Cycle Estimation")) {
                    Toggle("Use pattern-based cycles", isOn: $usePatternBasedCycles)

                    if !usePatternBasedCycles {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Average cycle length")
                                Spacer()
                                Text("\(averageCycleMinutes) min")
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $tempCycleMinutes, in: 60...120, step: 5) {
                                Text("Cycle length")
                            }
                            .onChange(of: tempCycleMinutes) { newValue in
                                averageCycleMinutes = Int(newValue)
                                // Recompute sleep based on new average
                                DispatchQueue.main.async {
                                    healthManager.fetchSleep(for: healthManager.selectedDate)
                                }
                            }
                            
                        }
                        .padding(.top, 5)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempCycleMinutes = Double(averageCycleMinutes)
            }
        }
    }
}
