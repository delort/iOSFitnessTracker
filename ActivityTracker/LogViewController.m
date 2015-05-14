//
//  LogViewController.m
//  ActivityTracker
//
//  Created by Yu Suo on 11/5/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogViewController.h"
#import "LogEntry.h"
#import "DeviceConfiguration.h"

#import "JBLineChartView.h"
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBChartInformationView.h"

#import "MBProgressHUD.h"

@interface LogViewController () <JBBarChartViewDataSource, JBBarChartViewDelegate>
@property (weak, nonatomic) IBOutlet JBChartHeaderView *headerView;
@property (weak, nonatomic) IBOutlet JBBarChartView *barChartView;
@property (weak, nonatomic) IBOutlet JBChartInformationView *informationView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *demoSwitch;

@property (nonatomic, strong) MBLMetaWear *device;
@property (nonatomic, strong) NSString *logFilename;
@property (nonatomic, strong) NSMutableArray *logData;
@property (nonatomic, strong) NSMutableArray *chartData;
@property (nonatomic, strong) NSMutableArray *timeData;
@property (nonatomic) BOOL doingReset;
@end

// Bar chart size and position constants
static CGFloat const BarChartViewControllerBarPadding = 1.0f;
static NSInteger const BarChartViewControllerNumBars = 60;

// Used for Demo Mode data generation
static NSInteger const BarChartViewControllerMaxBarHeight = 100;
static NSInteger const BarChartViewControllerMinBarHeight = 0;

// Estimate of steps per mile assuming casual walking speed @150 pounds
static NSInteger const StepsPerMile = 2000;

@implementation LogViewController
@synthesize logFilename = _logFilename;

- (NSString *)logFilename
{
    if (!_logFilename) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (paths.count) {
            _logFilename = [NSString stringWithFormat:@"%@/archive_logfile", paths[0]];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot find documents directory, logging not supported" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            _logFilename = nil;
        }
    }
    return _logFilename;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set up navigation bar colors
    self.navigationController.navigationBar.tintColor = ColorNavigationTint;
    self.navigationController.navigationBar.barTintColor = ColorNavigationBarTint;
    self.navigationController.navigationBar.translucent = TRUE;
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:ColorNavigationTitle,NSForegroundColorAttributeName, FontNavigationTitle, NSFontAttributeName, nil]];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
   
    // Creating bar chart and defining its properties
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = ColorBarChartBackground;
    
    // Setup title and header
    self.headerView.titleLabel.text = @"Steps in Last Hour";
    self.headerView.separatorColor = ColorBarChartHeaderSeparatorColor;
    
    // Load saved values and display
    self.logData = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.logFilename] mutableCopy];
    if (!self.logData) {
        self.logData = [NSMutableArray arrayWithCapacity:BarChartViewControllerNumBars];
    }
    [self.barChartView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateInterface];
}

- (IBAction)connectionButtonPressed:(id)sender
{
    if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Connect"]) {
        [self performSegueWithIdentifier:@"ShowScanScreen" sender:nil];
    } else {
        MBLMetaWear *device = self.device;
        self.device = nil;
        
        [device connectWithHandler:^(NSError *error) {
            [device setConfiguration:nil handler:nil];
        }];
        [device forgetDevice];
        
        [self clearLogPressed:nil];
        [self updateInterface];
    }
}

- (void)updateInterface
{
    [[MBLMetaWearManager sharedManager] retrieveSavedMetaWearsWithHandler:^(NSArray *array) {
        if (array.count) {
            self.device = array[0];
            self.statusLabel.text = @"Logging...";
            [self.navigationItem.leftBarButtonItem setTitle:@"Remove"];
            [self refreshPressed:self];
        } else {
            [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
            self.statusLabel.text = @"No MetaWear Connected";
        }
    }];
}

- (void)updateHeader
{
    // Set calorie label to new value
    self.headerView.subtitleLabel.text = [NSString stringWithFormat:@"Active Calories burned: %d", [self totalCaloriesBurned]];
}

- (int)totalCaloriesBurned
{
    float totalCalories = 0;
    for (LogEntry *entry in self.logData) {
        totalCalories += entry.calories;
    }
    return totalCalories;
}

- (IBAction)refreshPressed:(id)sender
{
    if (!self.device) {
        return;
    }
    
    if (self.demoSwitch.on) {
        return;
    }
    
    self.statusLabel.text = @"Connecting...";
    [self.device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot connect to logger, make sure it is charged and within range" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.statusLabel.text = @"Syncing...";
        
        DeviceConfiguration *configuration = self.device.configuration;
        [configuration.differentialSummedRMS downloadLogAndStopLogging:NO handler:^(NSArray *array, NSError *error)  {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } else {
                for (MBLRMSAccelerometerData *data in array) {
                    NSLog(@"Activity added: %@", data);
                        [self.logData addObject:[[LogEntry alloc] initWithTotalRMS:[NSNumber numberWithFloat:data.rms] timestamp:data.timestamp]];
                        if (self.logData.count > BarChartViewControllerNumBars) {
                            [self.logData removeObjectAtIndex:0];
                        }
                    }
                }
                [NSKeyedArchiver archiveRootObject:self.logData toFile:self.logFilename];

                if (!self.doingReset) {
                    [self updateHeader];
                    [self.barChartView reloadData];
                } else {
                    self.doingReset = NO;
                    [self clearLogPressed:nil];
                }
                self.progressBar.hidden = YES;
                self.statusLabel.text = @"Logging...";
            // We have our data so get outta here
            [self.device disconnectWithHandler:nil];
        } progressHandler:^(float number, NSError *error) {
            [self.progressBar setProgress:number animated:YES];
        }];
    }];
}

- (IBAction)switchChanged:(id)sender
{
    if (self.demoSwitch.on) {
        // Create some random data
        self.logData = [NSMutableArray arrayWithCapacity:BarChartViewControllerNumBars];
        for (int i = 0; i < BarChartViewControllerNumBars; i++) {
            NSNumber *rand = [NSNumber numberWithFloat:MAX((BarChartViewControllerMinBarHeight), arc4random() % (BarChartViewControllerMaxBarHeight)) * 1000];
            NSDate *timestamp = [NSDate dateWithTimeIntervalSinceNow:(BarChartViewControllerNumBars - i) * -60];
            [self.logData addObject:[[LogEntry alloc] initWithTotalRMS:rand timestamp:timestamp]];
        }
    } else {
        // Reload the real data
        self.logData = [[NSKeyedUnarchiver unarchiveObjectWithFile:self.logFilename] mutableCopy];
    }
    [self updateHeader];
    [self.barChartView reloadData];
}

- (IBAction)clearLogPressed:(id)sender
{
    [[NSFileManager defaultManager] removeItemAtPath:self.logFilename error:nil];
    [self.logData removeAllObjects];
    [self updateHeader];
    [self.barChartView reloadData];
}

- (IBAction)resetDevicePressed:(id)sender
{
    if (!self.device) {
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    MBLMetaWear *device = self.device;
    [device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        [device setConfiguration:device.configuration handler:^(NSError *error) {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                return;
            }
            [device disconnectWithHandler:^(NSError *error) {
                if (error) {
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                    return;
                }
                [hud hide:YES];
            }];
        }];
    }];
}


- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    // If there are not enough samples, then add zeros to the array until there are enough samples and give a warning message.
    if (self.logData.count < BarChartViewControllerNumBars) {
        //[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Not enough samples, chart data will be limited." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        int emptyEntries = BarChartViewControllerNumBars - (int)self.logData.count;
        for (int i = 0; i < emptyEntries; i++){
            [self.logData insertObject:[[LogEntry alloc] init] atIndex:0];
        }
    }
    return BarChartViewControllerNumBars;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    LogEntry *entry = self.logData[index];
    [self.informationView setTitleText:entry.titleText];
    [self.informationView setValueText:entry.valueText unitText:nil];
    [self.informationView setHidden:NO animated:YES];
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    [self.informationView setHidden:YES animated:YES];
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    LogEntry *entry = self.logData[index];
    return entry.steps;
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index
{
    return (index % 2 == 0) ? ColorBarChartBarOrange : ColorBarChartBarRed;
}

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor whiteColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return BarChartViewControllerBarPadding;
}

@end
