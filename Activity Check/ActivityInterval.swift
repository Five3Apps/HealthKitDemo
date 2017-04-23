//
//  ActivityInterval.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/19/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import Foundation
import HealthKit


class ActivityInterval : NSObject {
    
    //MARK: Properties
    var timestamp : Date? = nil
    var steps : Double? = 0
    var activeCalories : Double? = 0
    
    
    //MARK: Functions

    func addData(fromStatistic: HKStatistics) -> Void {
        switch fromStatistic.quantityType.identifier {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            self.steps = fromStatistic.sumQuantity()?.doubleValue(for: HKUnit.count())
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            self.activeCalories = fromStatistic.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
        default:
            break
        }
    }
    
}
