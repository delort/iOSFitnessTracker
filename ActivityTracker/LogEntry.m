/**
 * LogEntry.m
 * ActivityTracker
 *
 * Created by Stephen Schiffli on 11/26/14.
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

#import "LogEntry.h"

// Rough estimate of how many raw accelerometer counts are in a step
static float const ActivityPerStep = 2.000;
// Estimate of calories burned per step assuming casual walking speed @150 pounds
static float const CaloriesPerStep = 0.045;

@interface LogEntry ()
@property (nonatomic) NSNumber *totalRMS;
@property (nonatomic) NSDate *timestamp;
@property (nonatomic) int steps;
@property (nonatomic) float calories;
@end

@implementation LogEntry

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.totalRMS = nil;
        self.timestamp = nil;
        self.steps = 0;
        self.calories = 0;
    }
    return self;
}

- (instancetype)initWithTotalRMS:(NSNumber *)totalRMS timestamp:(NSDate *)timestamp
{
    self = [super init];
    if (self) {
        self.totalRMS = totalRMS;
        self.timestamp = timestamp;
        self.steps = totalRMS.floatValue / ActivityPerStep;
        self.calories = self.steps * CaloriesPerStep;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.totalRMS = [aDecoder decodeObjectForKey:@"totalRMS"];
        self.timestamp = [aDecoder decodeObjectForKey:@"time"];
        self.steps = self.totalRMS.floatValue / ActivityPerStep;
        self.calories = self.steps * CaloriesPerStep;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.totalRMS forKey:@"totalRMS"];
    [aCoder encodeObject:self.timestamp forKey:@"time"];
}

- (NSString *)titleText
{
    if (!self.totalRMS) {
        return @"Not Enough Data";
    } else {
        return [NSDateFormatter localizedStringFromDate:self.timestamp
                                              dateStyle:NSDateFormatterMediumStyle
                                              timeStyle:NSDateFormatterShortStyle];
    }
}

- (NSString *)valueText
{
    return [NSString stringWithFormat:@"%d Steps", self.steps];
}


@end
