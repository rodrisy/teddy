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
    
    @Published var sleepSegments: [SleepSegment] = []
    
    @Published var selectedDate: Date = .startOfDay


    
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
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: predicate) {_ , result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
            print("errorr fetchign totdays step data")
            return
            }
            
            let stepCount = quantity.doubleValue(for: .count())
            
            let activity = Activity(id: 0, title: "Today's steps", subtitle: "Goal: 10,000", image: "figure.walk", amount: stepCount.formattedString())
            
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
            let activity = Activity(id: 1, title: "Today's flights climbed", subtitle: "Goal: 10", image: "figure.stairs", amount: flightsClimbed.formattedString())
            
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
            
            let activity = Activity(id: 2, title: "Walking + Running Distance", subtitle: "Goal: 10km", image: "figure.run", amount: formattedDistance)
            
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

            let sleepStages: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]

            let totalSleepSeconds = samples
                .filter { sleepStages.contains($0.value) }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

            let hours = totalSleepSeconds / 3600
            let formatted = String(format: "%.1f hrs", hours)

            let estimatedCycles = Int(totalSleepSeconds / (90 * 60)) // one cycle ~90 mins

            let activity = Activity(
                id: 3,
                title: "Today's Sleep",
                subtitle: "Goal: 8 hrs",
                image: "bed.double.fill",
                amount: formatted
            )

            let cyclesActivity = Activity(
                id: 4,
                title: "Sleep Cycles",
                subtitle: "Est. cycles last night",
                image: "circle.grid.cross", // You can change to any relevant SF Symbol
                amount: "\(estimatedCycles)"
            )

            DispatchQueue.main.async {
                self.activities["todaysSleep"] = activity
                self.activities["todaysSleepCycles"] = cyclesActivity

                self.sleepSegments = samples
                    .filter { $0.value != HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                    .map {
                        SleepSegment(
                            stage: SleepStage(value: $0.value),
                            start: $0.startDate,
                            end: $0.endDate
                        )
                    }
            }

            print("Total sleep: \(formatted), Cycles: \(estimatedCycles)")
        }

        healthStore.execute(query)
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


