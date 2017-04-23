//
//  TableViewController.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/19/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import UIKit
import HealthKit


class TableViewController: UITableViewController {
    
    enum DataDisplayType : Int {
        case DisplayNoData = 0
        case DisplayStatisticsData
        case DisplaySampleData
    }
    
    //MARK: Properties
    var displayType : DataDisplayType = DataDisplayType.DisplayNoData
    var statisticsDataArray : [ActivityInterval]? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    var samplesDataArray : [ActivitySample]? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let dateDisplayFormatter = DateFormatter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dateDisplayFormatter.dateStyle = DateFormatter.Style.short
        self.dateDisplayFormatter.timeStyle = DateFormatter.Style.medium
    }
    
    
    //MARK: <UITableViewDataSource>
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.displayType == DataDisplayType.DisplayStatisticsData {
            guard self.statisticsDataArray != nil else {
                return 0
            }
            
            return self.statisticsDataArray!.count
        }
        else if self.displayType == DataDisplayType.DisplaySampleData {
            guard self.samplesDataArray != nil else {
                return 0
            }
            
            return self.samplesDataArray!.count
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell")!
        
        if self.displayType == DataDisplayType.DisplayStatisticsData {
            let activityInterval = self.statisticsDataArray?[indexPath.row]
            
            cell.textLabel?.text = self.dateDisplayFormatter.string(from:(activityInterval?.timestamp)!)
            
            let stepCount = activityInterval?.steps ?? 0.0
            let activeCalories = activityInterval?.activeCalories ?? 0.0
            cell.detailTextLabel?.text = String.init(format:"Steps: %1.0f Calories: %1.0f", arguments:[stepCount, activeCalories])
        }
        else if self.displayType == DataDisplayType.DisplaySampleData {
            let activitySample = self.samplesDataArray?[indexPath.row]
            
            cell.textLabel?.text = self.dateDisplayFormatter.string(from:(activitySample?.timestamp)!)
            
            let stepCount = activitySample?.steps ?? 0.0
            let activeCalories = activitySample?.activeCalories ?? 0.0
            cell.detailTextLabel?.text = String.init(format:"From: %@ Steps: %1.0f Calories: %1.0f", arguments:[activitySample?.name ?? "", stepCount, activeCalories])
        }
        
        return cell
    }
}
