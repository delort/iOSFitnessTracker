//
//  DeviceConfiguration.h
//  ActivityTracker
//
//  Created by Stephen Schiffli on 2/3/15.
//  Copyright (c) 2015 MbientLab Inc. All rights reserved.
//

#import <MetaWear/MetaWear.h>

@interface DeviceConfiguration : NSObject <MBLRestorable>
@property (nonatomic, strong) MBLEvent *differentialSummedRMS;
@end
