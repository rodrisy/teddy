//
//  HealthManager.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 9/6/25.
//

import Foundation
import HealthKit

extension Date {
    static var startOfDay: Date {
    Calendar.current.startOfDay(for:Date())
    }
}


class HealthManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    @Published var activities: [String: Activity] = [:]
    
    @Published var selectedDate: Date = .startOfDay
    
    @Published var availableSleepDates: Set<Date> = []
    
    @Published var usePatternBasedCycles: Bool = true
    @Published var averageCycleMinutes: Int = 90
    
    @Published var sleepSegments: [SleepSegment] = []
    @Published var sleepSessions: [[SleepSegment]] = []
    
    @Published var visibleActivityIDs: Set<Int> = [3, 4, 5, 6, 7] // Default visible ones
    

    
    init() {
        let steps = HKQuantityType(.stepCount)
        let flights = HKQuantityType(.flightsClimbed)
        let distance = HKQuantityType(.distanceWalkingRunning)
        
        let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let HealthTypes: Set = [steps, flights, distance, sleep]
        
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare : [], read : HealthTypes)
                refreshAllData(for: selectedDate)
            } catch {
                print("error fetching health data")
            }
        }
    }
    
    func refreshAllData(for date: Date) {
        fetchTodaySteps()
        fetchTodayFlights()
        fetchDistanceWalkingRunning()
        fetchSleep(for: date)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        refreshAllData(for: selectedDate)
    }

    func goToNextDay() {
        // Prevent viewing future dates
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        if tomorrow <= Date() {
            selectedDate = tomorrow
            refreshAllData(for: selectedDate)
        }
    }


    
    
    func fetchTodaySteps() {
        let steps = HKQuantityType(.stepCount)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: [])
        let query = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: predicate) {_ , result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
            print("errorr fetchign totdays step data")
            return
            }
            
            let stepCount = quantity.doubleValue(for: .count())
            
            let activity = Activity(id: 0, title: "Today's steps", subtitle: "Goal: 10,000", image: "figure.walk", amount: stepCount.formattedString(), color: .green)
            
            DispatchQueue.main.async{
                self.activities["todaySteps"] = activity
            }
             
//            print(stepCount.formattedString())
         }
        
        healthStore.execute(query)
    }
    
    func fetchTodayFlights() {
        let flights = HKQuantityType(.flightsClimbed)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: flights, quantitySamplePredicate: predicate) {_ , result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("errorr fetchign totdays flights data")
                return
            }
            
            let flightsClimbed = quantity.doubleValue(for: .count())
            let activity = Activity(id: 1, title: "Today's flights climbed", subtitle: "Goal: 10", image: "figure.stairs", amount: flightsClimbed.formattedString(), color: .green)
            
            DispatchQueue.main.async{
                self.activities["todaysFlights"] = activity
            }
            
//            print(flightsClimbed.formattedString())
        }
        healthStore.execute(query)
            
    }
    
    func fetchDistanceWalkingRunning() {
        let distance = HKQuantityType(.distanceWalkingRunning)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: distance, quantitySamplePredicate: predicate) {_ , result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("errorr fetchign totdays distance data")
                return
            }
            
            let distanceWalkingRunning = quantity.doubleValue(for: .meter()) / 1000
            
            let formattedDistance = String(format: "%.2f km", distanceWalkingRunning)
            
            let activity = Activity(id: 2, title: "Walking + Running Distance", subtitle: "Goal: 10km", image: "figure.run", amount: formattedDistance, color: .green)
            
            DispatchQueue.main.async{
                self.activities["todaysDistance"] = activity
            }
            
//            print(distanceWalkingRunning)
        }
        healthStore.execute(query)
            
    }
    
    func fetchSleep(for date: Date) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Sleep type unavailable")
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let samples = results as? [HKCategorySample], error == nil else {
                print("Error fetching sleep data")
                return
            }

            let filteredSamples = samples
                .filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                .filter { $0.sourceRevision.source.bundleIdentifier.starts(with: "com.apple.health") }
                .sorted { $0.startDate < $1.startDate }

            // Group into sessions — split where gaps > 30 min
            var sessions: [[HKCategorySample]] = []
            var currentSession: [HKCategorySample] = []
            
            var remSleepSeconds: TimeInterval = 0
            var deepSleepSeconds: TimeInterval = 0
            var coreSleepSeconds: TimeInterval = 0
            var awakeningsCount = 0

            for sample in filteredSamples {
                
                let value = sample.value
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    switch value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        coreSleepSeconds += duration
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        awakeningsCount += 1
                    default:
                        break
                    }
                
                if let last = currentSession.last {
                    let gap = sample.startDate.timeIntervalSince(last.endDate)
                    if gap > 30 * 60 {
                        if !currentSession.isEmpty {
                            sessions.append(currentSession)
                        }
                        currentSession = [sample]
                    } else {
                        currentSession.append(sample)
                    }
                } else {
                    currentSession.append(sample)
                }
            }

            // Don't forget last session
            if !currentSession.isEmpty {
                sessions.append(currentSession)
            }

            var sessionSegments: [[SleepSegment]] = []

            for session in sessions {
                var timeline: [SleepSegment] = []
                
                for sample in session {
                    // build your SleepSegment
                    let newSegment = SleepSegment(
                        stage: SleepStage(value: sample.value),
                        start: sample.startDate,
                        end: sample.endDate
                    )
                    
                    if let last = timeline.last, last.end > newSegment.start {
                        if newSegment.start > last.start {
                            timeline[timeline.count - 1] = SleepSegment(stage: last.stage, start: last.start, end: newSegment.start)
                        } else {
                            continue
                        }
                    }
                    
                    if newSegment.end > newSegment.start {
                        timeline.append(newSegment)
                    }
                }
                
                if !timeline.isEmpty {
                    sessionSegments.append(timeline)
                }
            }

            
            // Calculate summary
            let totalSleepSeconds = filteredSamples
                .filter {
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

            let totalMinutes = Int(totalSleepSeconds / 60)
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            let formatted = String(format: "%dh %02dm", hours, minutes)

            var estimatedCycles = 0
            
            var timeline: [SleepSegment] = []

            if self.usePatternBasedCycles {
                // Check each session individually
                for timeline in sessionSegments {
                    var stageQueue: [SleepStage] = []

                    for segment in timeline {
                        let stage = segment.stage
                        if stage == .deep || stage == .core || stage == .rem {
                            stageQueue.append(stage)

                            // Keep the last 3 stages only
                            if stageQueue.count > 3 {
                                stageQueue.removeFirst()
                            }

                            if stageQueue.count == 3 &&
                               stageQueue[0] == .deep &&
                               stageQueue[1] == .core &&
                               stageQueue[2] == .rem {
                                estimatedCycles += 1
                                stageQueue.removeAll() // Reset after finding a cycle
                            }
                        }
                    }
                }
            } else {
                // Estimate based on duration (total across all sessions)
                estimatedCycles = Int(totalSleepSeconds / (Double(self.averageCycleMinutes) * 60))
            }

            let remMinutes = Int(remSleepSeconds / 60)
            let deepMinutes = Int(deepSleepSeconds / 60)
            let coreMinutes = Int(coreSleepSeconds / 60)

            let activity = Activity(
                id: 3,
                title: "Today's Sleep",
                subtitle: "Goal: 8 hrs",
                image: "bed.double.fill",
                amount: formatted, color: .green
            )

            let cyclesActivity = Activity(
                id: 4,
                title: "Sleep Cycles",
                subtitle: "Est. cycles last night",
                image: "circle.grid.cross",
                amount: "\(estimatedCycles)", color: .green
            )
            
            let remActivity = Activity(
                id: 5,
                title: "REM Sleep",
                subtitle: "",
                image: "brain.head.profile",
                amount: "\(remMinutes) min",
                color: .purple
            )

            let deepActivity = Activity(
                id: 6,
                title: "Deep Sleep",
                subtitle: "",
                image: "moon.stars.fill",
                amount: "\(deepMinutes) min",
                color: .blue
            )

            let coreActivity = Activity(
                id: 7,
                title: "Core Sleep",
                subtitle: "",
                image: "bed.double.fill",
                amount: "\(coreMinutes) min",
                color: .teal
            )

            let awakeActivity = Activity(
                id: 8,
                title: "Awakenings",
                subtitle: "",
                image: "eye.fill",
                amount: "\(awakeningsCount)",
                color: .orange
            )

            
            
            DispatchQueue.main.async {
                self.sleepSessions = sessionSegments
                self.activities["todaysSleep"] = activity
                self.activities["todaysSleepCycles"] = cyclesActivity
                let dayOnly = Calendar.current.startOfDay(for: date)
                self.availableSleepDates.insert(dayOnly)
                
                self.activities["todaysREM"] = remActivity
                self.activities["todaysDeep"] = deepActivity
                self.activities["todaysCore"] = coreActivity
                self.activities["todaysAwake"] = awakeActivity
            }


            print("Total sleep: \(formatted), Cycles: \(estimatedCycles)")
        }

        healthStore.execute(query)
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let heartRatePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: heartRatePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let heartSamples = results as? [HKQuantitySample], error == nil else {
                print("Error fetching heart rate data")
                return
            }

            let heartRates = heartSamples.map { $0.quantity.doubleValue(for: .init(from: "count/min")) }

            guard !heartRates.isEmpty else {
                print("No heart rate data found during sleep")
                return
            }

            let minHR = Int(heartRates.min()!)
            let maxHR = Int(heartRates.max()!)
            let avgHR = Int(heartRates.reduce(0, +) / Double(heartRates.count))

            let minHRActivity = Activity(
                id: 9,
                title: "Min Heart Rate",
                subtitle: "During sleep",
                image: "heart.fill",
                amount: "\(minHR) bpm",
                color: .mint
            )

            let maxHRActivity = Activity(
                id: 10,
                title: "Max Heart Rate",
                subtitle: "During sleep",
                image: "heart.circle.fill",
                amount: "\(maxHR) bpm",
                color: .red
            )

            let avgHRActivity = Activity(
                id: 11,
                title: "Avg Heart Rate",
                subtitle: "During sleep",
                image: "waveform.path.ecg",
                amount: "\(avgHR) bpm",
                color: .indigo
            )

            DispatchQueue.main.async {
                self.activities["minHeartRate"] = minHRActivity
                self.activities["maxHeartRate"] = maxHRActivity
                self.activities["avgHeartRate"] = avgHRActivity
            }

            print("Heart Rate - Min: \(minHR), Max: \(maxHR), Avg: \(avgHR)")
        }

        healthStore.execute(heartRateQuery)
    }


    
}

extension Double {
    func formattedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        return numberFormatter.string(from: NSNumber(value: self)) ?? "0"
    }
}


