//
//  DeviceConfiguration.m
//  ActivityTracker
//
//  Created by Stephen Schiffli on 2/3/15.
//  Copyright (c) 2015 MbientLab Inc. All rights reserved.
//

#import "DeviceConfiguration.h"

@implementation DeviceConfiguration

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.differentialSummedRMS = [aDecoder decodeObjectForKey:@"differentialSummedRMS"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.differentialSummedRMS forKey:@"differentialSummedRMS"];
}

- (void)runOnDeviceBoot:(MBLMetaWear *)device
{
    if ([device.accelerometer isKindOfClass:[MBLAccelerometerMMA8452Q class]]) {
        MBLAccelerometerMMA8452Q *accelerometer = (MBLAccelerometerMMA8452Q *)device.accelerometer;
    
        accelerometer.sampleFrequency = 100;
        accelerometer.fullScaleRange = MBLAccelerometerRange8G;
        accelerometer.highPassCutoffFreq = MBLAccelerometerCutoffFreqHigheset;
        accelerometer.highPassFilter = YES;
        
        // Program to sum accelerometer RMS and log sample every minute
        self.differentialSummedRMS = [[accelerometer.rmsDataReadyEvent summationOfEvent] differentialSampleOfEvent:60000];
        [self.differentialSummedRMS startLogging];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"This MetaWear hardware version has not yet been enabled for Activity Tracking"
                                   delegate:nil
                          cancelButtonTitle:@"Okay"
                          otherButtonTitles:nil] show];
    }
}

@end
