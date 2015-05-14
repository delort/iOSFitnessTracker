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
    device.accelerometer.fullScaleRange = MBLAccelerometerRange8G;
    device.accelerometer.highPassCutoffFreq = MBLAccelerometerCutoffFreqHigheset;
    device.accelerometer.highPassFilter = YES;
    
    // Program to sum accelerometer RMS and log sample every minute
    self.differentialSummedRMS = [[device.accelerometer.rmsDataReadyEvent summationOfEvent] differentialSampleOfEvent:60000];
    [self.differentialSummedRMS startLogging];
}

@end
