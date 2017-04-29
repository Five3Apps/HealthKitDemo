//
//  ActivitySample.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/22/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import Foundation
import HealthKit


class ActivitySample : NSObject {
    
    //MARK: Properties
    var timestamp : Date? = nil
    var name : String? = nil
    
    var steps : Double? = 0
    var activeCalories : Double? = 0
    var exerciseTime : Double? = 0
    
    
    //MARK: Functions
    
    func addData(fromSample: HKQuantitySample) -> Void {
        switch fromSample.quantityType.identifier {
            
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            self.steps = fromSample.quantity.doubleValue(for: HKUnit.count())
            
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            self.activeCalories = fromSample.quantity.doubleValue(for: HKUnit.kilocalorie())
            
//        case HKQuantityTypeIdentifier.appleExerciseTime.rawValue:
//            self.exerciseTime = fromSample.quantity.doubleValue(for: HKUnit.count())
            
        default:
            break
        }
        
        self.name = fromSample.sourceRevision.source.name
    }
    
}
