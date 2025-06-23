import SwiftUI

struct SleepView: View {
    @EnvironmentObject var healthManager: HealthManager
    
    @State private var showSettings = false
    
    @State private var showingFilter = false
    @State private var visibleActivityKeys: Set<String> = [] // default visible

    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // top navigation date bar
                HStack {
                    // date
                    VStack(alignment: .leading) {
                        Text(healthManager.selectedDate, format: .dateTime.weekday(.wide))
                            .font(.title).opacity(1)
                        Text(healthManager.selectedDate, format: .dateTime.day().month().year())
                            .font(.headline).opacity(0.5)
                    }
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .padding().font(.title)
                    }
                    .sheet(isPresented: $showSettings) {
                        SettingsView(
                            usePatternBasedCycles: $healthManager.usePatternBasedCycles,
                            averageCycleMinutes: $healthManager.averageCycleMinutes,
                            healthManager: healthManager
                        )
                        .onChange(of: healthManager.averageCycleMinutes) { _ in
                            healthManager.fetchSleep(for: healthManager.selectedDate)
                        }
                    }
                    
                }
                .padding(.horizontal)
                
                HStack {
                    if healthManager.usePatternBasedCycles {
                        Label("Pattern-based cycles", systemImage: "circle.grid.cross")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    } else {
                        Label("Fixed cycles: \(healthManager.averageCycleMinutes) min", systemImage: "clock")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                
                // MARK: - Day Navigation Header
                HStack {
                    Button(action: {
                        healthManager.goToPreviousDay()
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(healthManager.selectedDate, format: .dateTime.day().month().year())
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        healthManager.goToNextDay()
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                    .disabled(Calendar.current.isDateInToday(healthManager.selectedDate))
                }
                .padding(.horizontal)
                
                // MARK: - Chart or Message
                ForEach(0..<healthManager.sleepSessions.count, id: \.self) { index in
                    SleepChartView(segments: healthManager.sleepSessions[index])
                }
                .padding()
                .frame(width: 350,)
                .background(Color.gray.opacity(0.2)).cornerRadius(15)
                
                //
                
                //time slept
                //time slept and quality of sleep
                
                HStack {
                    if let todaysSleep = healthManager.activities["todaysSleep"] {
                        Text("Slept: \(todaysSleep.amount)")
                    } else {
                        Text("No sleep data")
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Button {
                        showingFilter.toggle()
                    } label: {
                        Text("Edit")
                    }
                    .padding(.trailing)
                    .sheet(isPresented: $showingFilter) {
                        EditActivityFilterView(
                            allActivities: healthManager.activities,
                            visibleActivityKeys: $visibleActivityKeys
                        )
                    }
                    
                }.padding(.horizontal)
                
                
                // blocks of info
                // Activity grid filtered
                // Grid
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 20), count: 2)) {
                    ForEach(
                        healthManager.activities
                            .filter { visibleActivityKeys.contains($0.key) }
                            .sorted(by: { $0.value.id < $1.value.id }),
                        id: \.key
                    ) { item in
                        ActivityCard(activity: item.value)
                    }
                }
                .onChange(of: healthManager.selectedDate) { newDate in
                    healthManager.fetchSleep(for: newDate)
                    print("reloaded")
                }
                .padding(.horizontal)
                
                
                
                Spacer()
            }
            .navigationTitle("Sleep Data")
            .padding()
            .onAppear{
                healthManager.fetchSleep(for: healthManager.selectedDate)
            }
        }
        .refreshable {
            await refreshData()
        }
    }
    func refreshData() async {
        await MainActor.run {
            healthManager.refreshAllData(for: healthManager.selectedDate)
        }
    }
}

#Preview {
    SleepView()
        .environmentObject(HealthManager())
}
