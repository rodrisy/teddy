import SwiftUI
import HealthKit

// MARK: - HealthKitManager

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var hoursOfSleep: Double = 0.0

    // Request authorization to access sleep data
    func requestAuthorization() {
        let sleepType = HKQuantityType.categoryType(forIdentifier: .sleepAnalysis)!
        let typesToRead: Set<HKObjectType> = [sleepType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                print("HealthKit Authorization Granted")
                self.fetchSleepData()
            } else {
                print("HealthKit Authorization Denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    // Fetch sleep data for the last 24 hours
    func fetchSleepData() {
        let sleepType = HKQuantityType.categoryType(forIdentifier: .sleepAnalysis)!

        // Predicate to fetch data for the last 24 hours
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-24 * 60 * 60)
        let predicate = HKQuery.predicateForSamples(withStart: twentyFourHoursAgo, end: now, options: .strictEndDate)

        // Sort descriptor to get the most recent data first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                return
            }

            guard let sleepSamples = samples as? [HKCategorySample] else { return }

            var totalSleep: TimeInterval = 0

            for sample in sleepSamples {
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            DispatchQueue.main.async {
                self.hoursOfSleep = totalSleep / 3600.0 // Convert seconds to hours
            }
        }
        healthStore.execute(query)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject var healthKitManager = HealthKitManager()

    var body: some View {
        VStack {
            Image(systemName: "moon.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()

            Text("Sleep Data (Last 24 Hours)")
                .font(.headline)
                .padding(.bottom, 5)

            Text("\(healthKitManager.hoursOfSleep, specifier: "%.2f") hours")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .onAppear {
            healthKitManager.requestAuthorization()
        }
        .padding()
    }
}

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
