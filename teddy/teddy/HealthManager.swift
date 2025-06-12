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
    
    init() {
        let steps = HKQuantityType(.stepCount)
        let flights = HKQuantityType(.flightsClimbed)
        let distance = HKQuantityType(.distanceWalkingRunning)
        
        let HealthTypes: Set = [steps, flights, distance]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare : [], read : HealthTypes)
                fetchTodaySteps()
                fetchTodayFlights()
                fetchDistanceWalkingRunning()
            } catch {
                print("error fetching health data babes")
            }
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
             
            print(stepCount.formattedString())
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
            
            print(flightsClimbed.formattedString())
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
            
            let activity = Activity(id: 2, title: "Walking + Running Distance", subtitle: "10km", image: "figure.run", amount: formattedDistance)
            
            DispatchQueue.main.async{
                self.activities["todaysDistance"] = activity
            }
            
            print(distanceWalkingRunning)
        }
        healthStore.execute(query)
            
    }
    
    
}

extension Double {
    func formattedString() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        
        return numberFormatter.string(from: NSNumber(value: self))!
    }
}
