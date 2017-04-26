//
//  LogEntry.swift
//  ActivityTracker
//
//  Created by Stephen Schiffli on 4/25/17.
//  Copyright © 2017 MBIENTLAB Inc. All rights reserved.
//

import UIKit


// Rough estimate of how many raw accelerometer counts are in a step
fileprivate let ActivityPerStep = 2.000;
// Estimate of calories burned per step assuming casual walking speed @150 pounds
fileprivate let CaloriesPerStep = 0.045;

class LogEntry: NSObject, NSCoding {
    let totalRMS: Double?
    let timestamp: Date?
    let steps: Int
    let calories: Double
    
    var valueText: String {
        return "\(steps) Steps"
    }
    var titleText: String {
        if let timestamp = timestamp {
            return DateFormatter.localizedString(from: timestamp, dateStyle: .medium, timeStyle: .short)
        } else {
            return "Not Enough Data"
        }
    }
    
    override init() {
        totalRMS = nil
        timestamp = nil
        steps = 0
        calories = 0
    }
    
    init(totalRMS: Double, timestamp: Date) {
        self.totalRMS = totalRMS
        self.timestamp = timestamp
        self.steps = Int(totalRMS / ActivityPerStep)
        self.calories = Double(steps) * CaloriesPerStep
    }
    
    init(steps: Int, timestamp: Date) {
        self.totalRMS = Double(steps) * ActivityPerStep
        self.timestamp = timestamp
        self.steps = steps
        self.calories = Double(steps) * CaloriesPerStep
    }
    
    required init?(coder aDecoder: NSCoder) {
        totalRMS = aDecoder.decodeObject(forKey: "totalRMS") as? Double
        timestamp = aDecoder.decodeObject(forKey: "time") as? Date
        steps = Int(totalRMS ?? 0 / ActivityPerStep)
        calories = Double(steps) * CaloriesPerStep
    }
    

    func encode(with aCoder: NSCoder) {
        aCoder.encode(totalRMS, forKey: "totalRMS")
        aCoder.encode(timestamp, forKey: "time")
    }
}
