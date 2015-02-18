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
        self.summedRMS = [aDecoder decodeObjectForKey:@"summedRMS"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.summedRMS forKey:@"summedRMS"];
}

- (void)runOnDeviceBoot:(MBLMetaWear *)device
{
    device.accelerometer.fullScaleRange = MBLAccelerometerRange8G;
    device.accelerometer.filterCutoffFreq = 0;
    device.accelerometer.highPassFilter = YES;
    
    // Program to sum accelerometer RMS and log sample every minute
    self.summedRMS = [[device.accelerometer.rmsDataReadyEvent summationOfEvent] periodicSampleOfEvent:60000];
    [self.summedRMS startLogging];
}

@end
