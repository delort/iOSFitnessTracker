//
//  LogEntry.h
//  TempLogger
//
//  Created by Stephen Schiffli on 11/26/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import <MetaWear/MetaWear.h>

@interface LogEntry : NSObject <NSCoding>
@property (nonatomic, readonly) NSNumber *totalRMS;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic, readonly) int steps;
@property (nonatomic, readonly) float calories;

@property (nonatomic, readonly) NSString *titleText;
@property (nonatomic, readonly) NSString *valueText;

- (instancetype)initWithTotalRMS:(NSNumber *)totalRMS timestamp:(NSDate *)timestamp;
@end
