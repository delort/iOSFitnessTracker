//
//  LogEntry.m
//  TempLogger
//
//  Created by Stephen Schiffli on 11/26/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogEntry.h"

// Rough estimate of how many raw accelerometer counts are in a step
static NSInteger const ActivityPerStep = 2000;
// Estimate of calories burned per step assuming casual walking speed @150 pounds
static CGFloat const CaloriesPerStep = 0.045;

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
        self.steps = totalRMS.intValue / ActivityPerStep;
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
        self.steps = self.totalRMS.intValue / ActivityPerStep;
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
