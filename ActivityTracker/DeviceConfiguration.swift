//
//  DeviceConfiguration.swift
//  ActivityTracker
//
//  Created by Stephen Schiffli on 4/25/17.
//  Copyright © 2017 MBIENTLAB Inc. All rights reserved.
//

import UIKit
import MetaWear

protocol DeviceDelegate: class {
    func downloadDidUpdateProgress(_ number: Float)
    func downloadDidRecieveEntry(_ entry: LogEntry)
    func downloadCompleteWithError(_ error: Error?)
}

fileprivate let BlockSizeMs: UInt32 = 5 * 1000

class DeviceConfiguration: NSObject, MBLRestorable {
    weak var delegate: DeviceDelegate?

    var differentialSummedRMS: MBLEvent<MBLRMSAccelerometerData>?
    var stepEvent: MBLEvent<MBLNumericData>?
    var dummyEvent: MBLDataSwitch<MBLNumericData>?
    
    func run(onDeviceBoot device: MBLMetaWear) {
        if let accelerometer = device.accelerometer as? MBLAccelerometerMMA8452Q {
            accelerometer.sampleFrequency = 100.0
            accelerometer.fullScaleRange = .range8G
            accelerometer.highPassCutoffFreq = .higheset
            accelerometer.highPassFilter = true
            
            // Program to sum accelerometer RMS and log sample every minute
            differentialSummedRMS = accelerometer.rmsDataReadyEvent.summationOfEvent().differentialSample(ofEvent: BlockSizeMs)
            differentialSummedRMS?.startLoggingAsync()
        } else if let accelerometer = device.accelerometer as? MBLAccelerometerBMI160 {
            // For the step counter to work, we need to enable the stepEvent, but we don't really need the
            // step event data so we start logging it but just discard all data throught a switch filter
            dummyEvent = accelerometer.stepEvent.conditionalDataSwitch(false)
            dummyEvent?.startLoggingAsync()
            
            stepEvent = accelerometer.stepCounter.periodicRead(withPeriod: 500).differentialSample(ofEvent: BlockSizeMs)
            stepEvent?.startLoggingAsync()
        } else {
            print("This MetaWear hardware version has not yet been enabled for Activity Tracking")
        }
    }
    
    func startDownload() {
        if let differentialSummedRMS = differentialSummedRMS {
            differentialSummedRMS.downloadLogAndStopLoggingAsync(false, progressHandler: { (number) in
                self.delegate?.downloadDidUpdateProgress(number)
            }).success({ (array) in
                for data in array as! [MBLRMSAccelerometerData] {
                    print("Activity added \(data)")
                    self.delegate?.downloadDidRecieveEntry(LogEntry(totalRMS: data.rms, timestamp: data.timestamp))
                }
                self.delegate?.downloadCompleteWithError(nil)
            }).failure({ (error) in
                self.delegate?.downloadCompleteWithError(error)
            })
        }
        if let stepEvent = stepEvent {
            stepEvent.downloadLogAndStopLoggingAsync(false, progressHandler: { (number) in
                self.delegate?.downloadDidUpdateProgress(number)
            }).success({ (array) in
                for data in array as! [MBLNumericData] {
                    print("Steps added \(data)")
                    self.delegate?.downloadDidRecieveEntry(LogEntry(steps: data.value.intValue, timestamp: data.timestamp))
                }
                self.delegate?.downloadCompleteWithError(nil)
            }).failure({ (error) in
                self.delegate?.downloadCompleteWithError(error)
            })
        }
    }
}

