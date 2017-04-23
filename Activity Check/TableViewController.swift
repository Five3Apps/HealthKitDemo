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
    
    //MARK: Properties
    var statisticsDataArray : [ActivityInterval]? = nil {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let dateDisplayFormatter = DateFormatter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dateDisplayFormatter.dateStyle = DateFormatter.Style.medium
        self.dateDisplayFormatter.timeStyle = DateFormatter.Style.medium
    }
    
    
    //MARK: <UITableViewDataSource>
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.statisticsDataArray != nil else {
            return 0
        }
        
        return self.statisticsDataArray!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell")!
        let activityInterval = self.statisticsDataArray?[indexPath.row]
        
        cell.textLabel?.text = self.dateDisplayFormatter.string(from:(activityInterval?.timestamp)!)
        
        let stepCount = activityInterval?.steps ?? 0.0
        let activeCalories = activityInterval?.activeCalories ?? 0.0
        cell.detailTextLabel?.text = String.init(format:"Steps: %1.0f Calories: %1.0f", arguments:[stepCount, activeCalories])
        
        return cell
    }
}
