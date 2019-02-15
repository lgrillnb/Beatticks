//
//  ViewController.swift
//  Beatticks
//
//  Created by Lori on 15.02.19.
//  Copyright © 2019 Lori. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    @IBOutlet weak var outputTextField: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func applicationShouldRequestHealthAuthorization() {
            healthStore.handleAuthorizationForExtension { (success, error) -> Void in
                //...
            }
            
            //let energyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 425.0)
            
            //let distance = HKQuantity(unit: HKUnit.mile(), doubleValue: 3.2)
            
            let start = Date()
            let end = Date()+100
            // Provide summary information when creating the workout.
            let run = HKWorkout(activityType: HKWorkoutActivityType.running, start: start, end: end)
            
            guard let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
                fatalError("*** Unable to create a heart rate type ***")
            }
            
            healthStore.requestAuthorization(toShare: [heartRateType], read:[heartRateType], completion:{(success, error) in
                // Exception-code
                
                // Save the workout before adding detailed samples.
                self.healthStore.save(run) { (success, error) -> Void in
                    guard success else {
                        // Perform proper error handling here...
                        fatalError("*** An error occurred while saving the " +
                            "workout: \(error?.localizedDescription ?? "")")
                    }
                }
                // Add optional, detailed information for each time interval
                var samples: [HKQuantitySample] = []
                
                let heartRateForInterval = HKQuantity(unit: HKUnit(from: "count/min"),
                                                      doubleValue: 95.0)
                
                let heartRateForIntervalSample =
                    HKQuantitySample(type: heartRateType, quantity: heartRateForInterval,
                                     start: start, end: end)
                
                samples.append(heartRateForIntervalSample)
                
                // Continue adding detailed samples...
                
                // Add all the samples to the workout.
                self.healthStore.add(samples, to: run) { (success, error) -> Void in
                    guard success else {
                        // Perform proper error handling here...
                        fatalError("*** An error occurred while adding a " +
                            "sample to the workout: \(error?.localizedDescription ?? "")")
                    }
                }
            })
        }
        
        applicationShouldRequestHealthAuthorization()
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        if (HKHealthStore.isHealthDataAvailable()){
            var csvString = "Time,Date,Heartrate(BPM)\n"
            
            let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm:ss"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/YYYY"
            
            let query = HKSampleQuery(sampleType:heartRateType, predicate:nil, limit:600, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
                guard let results = results else { return }
                for quantitySample in results {
                    let quantity = (quantitySample as! HKQuantitySample).quantity
                    let heartRateUnit = HKUnit(from: "count/min")
                    
                    csvString += "\(timeFormatter.string(from: quantitySample.startDate)),\(dateFormatter.string(from: quantitySample.startDate)),\(quantity.doubleValue(for: heartRateUnit))\n"
                    print("\(timeFormatter.string(from: quantitySample.startDate)),\(dateFormatter.string(from: quantitySample.startDate)),\(quantity.doubleValue(for: heartRateUnit))")
                    
                }
                
                //let documentsDir = try FileManager.default.url(for: .documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                //try csvString.write(to: NSURL(string:"heartratedata.csv", relativeTo:documentsDir)! as URL, atomically:true, encoding:String.Encoding.ascii)
                DispatchQueue.main.async {
                    self.outputTextField.text = ""
                    self.outputTextField.isEditable = false
                    self.outputTextField.insertText(csvString)
                }
                
            })
            self.healthStore.execute(query)
            
        }
    }
}
