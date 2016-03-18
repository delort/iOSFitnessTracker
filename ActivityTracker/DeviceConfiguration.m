/**
 * DeviceConfiguration.m
 * ActivityTracker
 *
 * Created by Stephen Schiffli on 2/3/15.
 * Copyright 2014-2015 MbientLab Inc. All rights reserved.
 *
 * IMPORTANT: Your use of this Software is limited to those specific rights
 * granted under the terms of a software license agreement between the user who
 * downloaded the software, his/her employer (which must be your employer) and
 * MbientLab Inc, (the "License").  You may not use this Software unless you
 * agree to abide by the terms of the License which can be found at
 * www.mbientlab.com/terms.  The License limits your use, and you acknowledge,
 * that the Software may be modified, copied, and distributed when used in
 * conjunction with an MbientLab Inc, product.  Other than for the foregoing
 * purpose, you may not use, reproduce, copy, prepare derivative works of,
 * modify, distribute, perform, display or sell this Software and/or its
 * documentation for any purpose.
 *
 * YOU FURTHER ACKNOWLEDGE AND AGREE THAT THE SOFTWARE AND DOCUMENTATION ARE
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF MERCHANTABILITY, TITLE,
 * NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
 * MBIENTLAB OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE,
 * STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE
 * THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED
 * TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR CONSEQUENTIAL DAMAGES, LOST
 * PROFITS OR LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
 * SERVICES, OR ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
 * DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *
 * Should you have any questions regarding your right to use this Software,
 * contact MbientLab via email: hello@mbientlab.com
 */

#import "DeviceConfiguration.h"
#import "LogEntry.h"

@interface DeviceConfiguration ()
@property (nonatomic, strong) MBLEvent *differentialSummedRMS;
@property (nonatomic, strong) MBLEvent *stepEvent;
@property (nonatomic, strong) MBLEvent *dummyEvent;
@end

@implementation DeviceConfiguration

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
        [self.differentialSummedRMS startLoggingAsync];
    } else if ([device.accelerometer isKindOfClass:[MBLAccelerometerBMI160 class]]) {
        MBLAccelerometerBMI160 *accelerometer = (MBLAccelerometerBMI160 *)device.accelerometer;
        
        // For the step counter to work, we need to enable the stepEvent, but we don't really need the
        // step event data so we start logging it but just discard all data throught a switch filter
        self.dummyEvent = [accelerometer.stepEvent conditionalDataSwitch:NO];
        [self.dummyEvent startLoggingAsync];
        
        self.stepEvent = [[accelerometer.stepCounter periodicReadWithPeriod:500] differentialSampleOfEvent:60000];
        [self.stepEvent startLoggingAsync];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"This MetaWear hardware version has not yet been enabled for Activity Tracking"
                                   delegate:nil
                          cancelButtonTitle:@"Okay"
                          otherButtonTitles:nil] show];
    }
}

- (void)startDownload
{
    if (self.differentialSummedRMS) {
        [[[self.differentialSummedRMS downloadLogAndStopLoggingAsync:NO progressHandler:^(float number) {
            [self.delegate downloadDidUpdateProgress:number];
        }] success:^(id  _Nonnull array) {
            for (MBLRMSAccelerometerData *data in array) {
                NSLog(@"Activity added: %@", data);
                [self.delegate downloadDidRecieveEntry:[[LogEntry alloc] initWithTotalRMS:[NSNumber numberWithFloat:data.rms] timestamp:data.timestamp]];
            }
            [self.delegate downloadCompleteWithError:nil];
        }] failure:^(NSError * _Nonnull error) {
            [self.delegate downloadCompleteWithError:error];
        }];
    }
    if (self.stepEvent) {
        [[[self.stepEvent downloadLogAndStopLoggingAsync:NO progressHandler:^(float number) {
            [self.delegate downloadDidUpdateProgress:number];
        }] success:^(id  _Nonnull array) {
            for (MBLNumericData *steps in array) {
                NSLog(@"Steps added: %@", steps);
                [self.delegate downloadDidRecieveEntry:[[LogEntry alloc] initWithSteps:steps.value.intValue timestamp:steps.timestamp]];
            }
            [self.delegate downloadCompleteWithError:nil];
        }] failure:^(NSError * _Nonnull error) {
            [self.delegate downloadCompleteWithError:error];
        }];
    }
}

@end
