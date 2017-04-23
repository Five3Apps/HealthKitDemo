//
//  ActivityKit.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/17/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import HealthKit


class ActivityKit : NSObject {
    
    //MARK: ActivityKit Error info
    let errorDomain = "com.five3apps.healthkit"
    enum ActivityKitError: Int {
        case HealthKitUnknown       = 1000
        case HealthKitUnavailable   = 1001
        case NoStatisticsRequested  = 1002
        case NoStatisticsReturned   = 1003
    }
    
    //MARK: Properties
    
    /// The minute interval between HealthKit data objects. Defaults to 15.
    var dataInterval = 15
    
    
    //MARK: Internal properties
    
    private let healthStore = HKHealthStore()
    
    
    //MARK: Functions
    
    //************************************************
    //STEP 1: Request Authorization
    //************************************************
    
    /// Will prompt the user for authorization to their HealthKit data
    ///
    /// - Parameter completion: Completion to be called after HealthKit authorization is complete, or there was an error.
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: NSError?) -> Void)?) {
        guard HKHealthStore.isHealthDataAvailable() == true else {
            let error = NSError(domain: self.errorDomain, code: ActivityKitError.HealthKitUnavailable.rawValue, userInfo: nil)
            completion?(false, error)
            return
        }
        
        // Request authorization to read/write the specified data types
        self.healthStore.requestAuthorization(toShare: nil, read: self.healthKitActivityTypesToRead()) { (success: Bool, error: Error?) -> Void in
            DispatchQueue.main.async {
                completion?(success, error as NSError?)
            }
        }
    }
    
    /// Request HKQuantityTypes to be used for reading HealthKit data.
    ///
    /// - Returns: Set of HKQuantityType
    func healthKitActivityTypesToRead() -> Set<HKObjectType>? {
        var healthDataToRead = Set<HKObjectType>()
        
        healthDataToRead.insert(HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
        healthDataToRead.insert(HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!)
        
        if #available(iOS 9.3, *) { //Exercise time was not added until iOS 9.3, so guard against this
            healthDataToRead.insert(HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.appleExerciseTime)!)
        }
        
        return healthDataToRead
    }
    
    
    //************************************************
    //STEP 2: Request statistics data
    //************************************************
    
    /// Get all activity data as specified by 'healthKitActivityTypesToRead()'. Public entry point for calling a query of the HK database.
    ///
    /// - Parameters:
    ///   - start: Start date determining the beginning point for which statistics will be returned
    ///   - completion: A completion to run when the query finishes. Dictionary, if present returns arrays of HKStatistics objects that are keyed using HKIdentifier for each quantity type.
    func getActivityData(since start: Date?, completion:(([ActivityInterval]?, NSError?) -> Void)?) {
        
        //Make sure we're ready to get all specified activity types
        guard let healthTypes = self.healthKitActivityTypesToRead() else {
            NSLog("Not set to read any health data.")
            
            let error = NSError(domain: self.errorDomain, code: ActivityKitError.NoStatisticsRequested.rawValue, userInfo: nil)
            completion?(nil, error)
            return
        }
        
        // Set date bounds
        let endDate = Date()
        let startDate = start ?? Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // Prep for response
        var resultsDictionary = [String: Array<HKStatistics>]()
        
        //Dispatch group to wait for multiple async responses
        let queryGroup = DispatchGroup()
        
        for typeToRead in healthTypes {
            queryGroup.enter()
            self.queryForActivity(since: startDate, to: endDate, for: (typeToRead as! HKQuantityType), completion: { statisticsArray, error in
                
                if statisticsArray != nil {
                    resultsDictionary[typeToRead.identifier] = statisticsArray
                }
                
                queryGroup.leave()
            })
        }
        
        queryGroup.notify(queue: DispatchQueue.main) {
            if resultsDictionary.count > 0 {
                let resultsArray = self.convertActivity(fromStatistics: resultsDictionary)
                completion?(resultsArray, nil)
            } else {
                let error = NSError(domain: self.errorDomain, code: ActivityKitError.NoStatisticsReturned.rawValue, userInfo: nil)
                completion?(nil, error)
            }
        }
    }
    
    
    //************************************************
    //STEP 2b: Request statistics data
    //************************************************
    
    /// Get all activity data as specified by 'healthKitActivityTypesToRead()'. Public entry point for calling a query of the HK database.
    ///
    /// - Parameters:
    ///   - start: Start date determining the beginning point for which statistics will be returned
    ///   - completion: A completion to run when the query finishes. Dictionary, if present returns arrays of HKStatistics objects that are keyed using HKIdentifier for each quantity type.
    func getActivitySamples(since start: Date?, completion:(([ActivitySample]?, NSError?) -> Void)?) {
        
        //Make sure we're ready to get all specified activity types
        guard let healthTypes = self.healthKitActivityTypesToRead() else {
            NSLog("Not set to read any health data.")
            
            let error = NSError(domain: self.errorDomain, code: ActivityKitError.NoStatisticsRequested.rawValue, userInfo: nil)
            completion?(nil, error)
            return
        }
        
        // Set date bounds
        let endDate = Date()
        let startDate = start ?? Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // Prep for response
        var resultsDictionary = [String: Array<HKQuantitySample>]()
        
        //Dispatch group to wait for multiple async responses
        let queryGroup = DispatchGroup()
        
        for typeToRead in healthTypes {
            queryGroup.enter()
            self.queryForActivitySample(since: startDate, to: endDate, for: (typeToRead as! HKQuantityType), completion: { sampleArray, error in
                
                if sampleArray != nil {
                    resultsDictionary[typeToRead.identifier] = sampleArray
                }
                
                queryGroup.leave()
            })
        }
        
        queryGroup.notify(queue: DispatchQueue.main) {
            if resultsDictionary.count > 0 {
                let resultsArray = self.convertActivitySample(fromSamples: resultsDictionary)
                completion?(resultsArray, nil)
            } else {
                let error = NSError(domain: self.errorDomain, code: ActivityKitError.NoStatisticsReturned.rawValue, userInfo: nil)
                completion?(nil, error)
            }
        }
    }
    
    
    //MARK: Private functions
    
    //************************************************
    // Used for statistics collection query
    //************************************************
    
    /// Run a statistics collection query for a specific data type. Only used privately inside this class.
    ///
    /// - Parameters:
    ///   - startDate: start of range for which to query
    ///   - endDate: end of range for which to query
    ///   - quantityType: type of data to query
    ///   - completion: block to run with results or error. Will not return an empty array; array is either populated or nil
    private func queryForActivity(since startDate: Date, to endDate: Date, for quantityType: HKQuantityType, completion: ((Array<HKStatistics>?, NSError?) -> Void)?) {
        var interval = DateComponents()
        interval.minute = self.dataInterval
        
        //construct calorie query
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let anchorDate = NSCalendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: endDate)! //establish anchor date with 00:00 so intervals occur precisely
        let query = HKStatisticsCollectionQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: interval)
        
        //handle results from the initial query
        query.initialResultsHandler = { collectionQuery, queryResults, error in
            guard let statsCollection = queryResults else {
                NSLog("Error fetching results: \(String(describing: error))")
                completion?(nil, error as NSError?)
                return
            }
            
            if statsCollection.statistics().isEmpty == false {
                completion?(statsCollection.statistics(), nil)
            } else {
                completion?(nil, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Takes dictionary of HKStatistics to be converted to an array of ActivityInterval.
    ///
    /// - Parameter statistics: Dictionary with keys that are expected to be HKQuantityType.identifiers, referencing arrays of HKStatistics of that HKQuantityType
    /// - Returns: Array of ActivityInterval objects that contain the data from all the HKStatistics that were passed in.
    public func convertActivity(fromStatistics statistics: [String: Array<HKStatistics>]) -> [ActivityInterval]? {
        var results = Array<ActivityInterval>()
        
        for (_, statsArray) in statistics {
            for statsObject in statsArray {
                if let activity = results.first(where: { $0.timestamp == statsObject.startDate }) {
                    activity.addData(fromStatistic: statsObject)
                } else {
                    let activity = ActivityInterval()
                    activity.timestamp = statsObject.startDate
                    activity.addData(fromStatistic: statsObject)
                    results.append(activity)
                }
            }
        }
        
        return results.sorted(by: { $0.timestamp! < $1.timestamp! })
    }
    
    //************************************************
    // Used for sample query
    //************************************************
    
    /// Run a sample query for a specific data type. Only used privately inside this class.
    ///
    /// - Parameters:
    ///   - startDate: start of range for which to query
    ///   - endDate: end of range for which to query
    ///   - quantityType: type of data to query
    ///   - completion: block to run with results or error. Will not return an empty array; array is either populated or nil
    private func queryForActivitySample(since startDate: Date, to endDate: Date, for sampleType: HKQuantityType, completion: ((Array<HKQuantitySample>?, NSError?) -> Void)?) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) { query, results, error in
            guard let samples = results as? [HKQuantitySample] else {
                NSLog("Error fetching results: \(String(describing: error))")
                completion?(nil, error as NSError?)
                return
            }
            
            if samples.isEmpty == false {
                completion?(samples, nil)
            } else {
                completion?(nil, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    /// Takes dictionary of HKSamples to be converted to an array of ActivityInterval.
    ///
    /// - Parameter statistics: Dictionary with keys that are expected to be HKQuantityType.identifiers, referencing arrays of HKStatistics of that HKQuantityType
    /// - Returns: Array of ActivityInterval objects that contain the data from all the HKStatistics that were passed in.
    public func convertActivitySample(fromSamples samples: [String: Array<HKQuantitySample>]) -> [ActivitySample]? {
        var results = Array<ActivitySample>()
        
        for (_, samplesArray) in samples {
            for sampleObject in samplesArray {
                if let activity = results.first(where: { $0.timestamp == sampleObject.startDate }) {
                    activity.addData(fromSample: sampleObject)
                } else {
                    let activity = ActivitySample()
                    activity.timestamp = sampleObject.startDate
                    activity.addData(fromSample: sampleObject)
                    results.append(activity)
                }
            }
        }
        
        return results.sorted(by: { $0.timestamp! < $1.timestamp! })
    }
}
