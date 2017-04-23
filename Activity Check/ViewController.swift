//
//  ViewController.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/17/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet var authButton : UIButton!;
    
    let activityKit = ActivityKit()
    

    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityKit.dataInterval = 60
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: External
    
    @IBAction func requestHealthKitAuth(_ sender: UIButton) {
        self.activityKit.authorizeHealthKit(completion: { success, error in
            // Error handling
        })
    }
    
    @IBAction func requestHealthKitData(_ sender: UIButton) {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        self.activityKit.getActivityData(since: startDate, completion: { statisticsArray, error in
            guard statisticsArray != nil else {
                NSLog("View controller did not receive any HealthKit statistics")
                
                return
            }
            
            let dataViewController = self.childViewControllers.first as! TableViewController
            
            dataViewController.statisticsDataArray = statisticsArray
        })
    }
}

