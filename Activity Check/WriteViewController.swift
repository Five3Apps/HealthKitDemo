//
//  WriteViewController.swift
//  Activity Check
//
//  Created by Justin Bergen on 4/24/17.
//  Copyright © 2017 Five3 Apps. All rights reserved.
//

import Foundation
import UIKit

import HealthKit


class WriteViewController: UIViewController {
    
    //MARK: Properties
    
    let activityKit = ActivityKit()
    
    @IBOutlet var timestampTextField: UITextField!
    @IBOutlet var caloriesTextField: UITextField!
    
    //MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    //MARK: Actions
    
    @IBAction func saveActiveCalorieSample(_ sender: UIButton) {
        guard self.timestampTextField.text != nil || self.caloriesTextField.text != nil else {
            NSLog("Cannot save active calorie sample without a timestamp and active calorie value")
            
            return
        }
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            NSLog("Unable to create active calorie quantity type")
            
            return
        }
        
        guard let startDate = ISO8601DateFormatter().date(from: self.timestampTextField.text!) else {
            NSLog("Unable to create a sample date")
            
            return
        }
        
        guard let calories = Double(self.caloriesTextField.text!) else {
            NSLog("Unable to create active calorie quantity")
            
            return
        }
        
        let calorieQuantity = HKQuantity.init(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let activeCalorieSample = HKQuantitySample.init(type: quantityType, quantity: calorieQuantity, start: startDate, end: startDate)
        
        self.activityKit.saveActivitySample(sample: activeCalorieSample, completion: { success, error in
            guard success else {
                NSLog("An error occured saving active calories. The error was: %@.", [error])
                
                return
            }
        })  
    }
    
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    //MARK: <UITextFieldDelegate>
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.timestampTextField {
            self.caloriesTextField.becomeFirstResponder()
        }
        else if textField == self.caloriesTextField {
            self.caloriesTextField.resignFirstResponder()
        }
        
        return true
    }
}
