//
//  SleepSegment.swift
//  teddy
//
//  Created by Rodrigo Sánchez Yuste on 11/6/25.
//

import Foundation
import SwiftUI
import HealthKit


enum SleepStage: String {
    case deep = "Deep"
    case core = "Core"
    case rem = "Rem"
    case awake = "Awake"
    case unknown = "Unknown"

    init(value: Int) {
        switch value {
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            self = .deep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
            self = .core
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            self = .rem
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            self = .awake
        default:
            self = .unknown
        }
    }
}

//
//enum SleepStage: String, CaseIterable {
//    case awake, rem, core, deep, unknown
//
//    init(value: Int) {
//        switch value {
//        case HKCategoryValueSleepAnalysis.awake.rawValue: self = .awake
//        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: self = .rem
//        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: self = .core
//        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: self = .deep
//        default: self = .unknown
//        }
//    }
//
//    var color: Color {
//        switch self {
//        case .awake: return .yellow
//        case .rem: return .purple
//        case .core: return .blue
//        case .deep: return .indigo
//        case .unknown: return .gray
//        }
//    }
//}

struct SleepSegment: Identifiable {
    let id = UUID()
    let stage: SleepStage
    var start: Date
    var end: Date
}

