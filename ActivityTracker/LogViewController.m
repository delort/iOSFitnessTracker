//
//  LogViewController.m
//  ActivityTracker
//
//  Created by Yu Suo on 11/5/14.
//  Copyright (c) 2014 MbientLab Inc. All rights reserved.
//

#import "LogViewController.h"

#import "JBLineChartView.h"
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBChartInformationView.h"

#import "MBProgressHUD.h"

@interface LogViewController () <JBBarChartViewDataSource, JBBarChartViewDelegate>

@property (nonatomic, strong) MBLMetaWear *device;

@property (nonatomic, strong) JBBarChartView *barChartView;
@property (nonatomic, strong) JBChartInformationView *informationView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *identifierLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *demoSwitch;
@property (nonatomic, strong) NSString *logFilename;
@property (nonatomic, strong) NSMutableArray *logData;
@property (nonatomic, strong) NSMutableArray *chartData;
@property (nonatomic, strong) NSMutableArray *timeData;

@end

// Bar chart size and position constants
CGFloat const BarChartViewControllerChartHeight = 260.0f;
CGFloat const BarChartViewControllerChartPadding = 15.0f;
CGFloat const BarChartViewControllerChartHeightPadding = 150.0f;
CGFloat const BarChartViewControllerChartHeaderHeight = 80.0f;
CGFloat const BarChartViewControllerChartHeaderPadding = 10.0f;
CGFloat const BarChartViewControllerBarPadding = 1.0f;
NSInteger const BarChartViewControllerNumBars = 60;

JBChartHeaderView *headerView;

// Used for Demo Mode data generation
NSInteger const BarChartViewControllerMaxBarHeight = 100;
NSInteger const BarChartViewControllerMinBarHeight = 0;

// Rough estimate of how many raw accelerometer counts are in a step
NSInteger const ActivityPerStep = 2000;
// Estimate of steps per mile assuming casual walking speed @150 pounds
NSInteger const StepsPerMile = 2000;
// Estimate of calories burned per step assuming casual walking speed @150 pounds
CGFloat const CaloriesPerStep = 0.045;

@implementation LogViewController
@synthesize logFilename = _logFilename;

- (NSString *)logFilename
{
    if (!_logFilename) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *name = [NSString stringWithFormat:@"%@/logfile.txt", paths[0]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:name]) {
            [[NSFileManager defaultManager] createFileAtPath:name contents:nil attributes:nil];
        }
        _logFilename = name;
    }
    return _logFilename;
}

- (IBAction)connectionButtonPressed:(id)sender
{
    if ([self.navigationItem.leftBarButtonItem.title isEqualToString:@"Connect"])
    {
        [self performSegueWithIdentifier:@"ShowScanScreen" sender:nil];
    } else {
        MBLMetaWear *device = self.device;
        self.device = nil;
        
        [device connectWithHandler:^(NSError *error) {
            // Clear the log currently on the device
            MBLEvent *event = [self.device retrieveEventWithIdentifier:@"com.mbientlab.ActivityTrackerEvent"];
            if (event && event.isLogging) {
                [event downloadLogAndStopLogging:YES handler:^(NSArray *array, NSError *error) {
                } progressHandler:nil];
            };
            // Clean up log and data array in the App
            [self clearLogPressed:nil];
            
            [device resetDevice];
        }];
        
        [self clearLogPressed:nil];
        [device forgetDevice];
        self.identifierLabel.text = @"";
        self.statusLabel.text = @"No MetaWear Connected";
        [self updateHeader];
        [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
    }
}

- (void)setupMetaWear:(NSNotification *)note
{
    [[MBLMetaWearManager sharedManager] retrieveSavedMetaWearsWithHandler:^(NSArray *array) {
        if (array.count) {
            self.device = array[0];
            self.identifierLabel.text = self.device.identifier.UUIDString;
            self.statusLabel.text = @"Logging...";
            [self.navigationItem.leftBarButtonItem setTitle:@"Remove"];
            [self refreshPressed:self];
        } else {
            [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
            self.identifierLabel.text = @"";
            self.statusLabel.text = @"No MetaWear Connected";
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupMetaWear:nil];
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
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = CGRectMake(BarChartViewControllerChartPadding, BarChartViewControllerChartHeightPadding, self.view.bounds.size.width - (BarChartViewControllerChartPadding * 2), BarChartViewControllerChartHeight);
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.headerPadding = BarChartViewControllerChartHeaderPadding;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = ColorBarChartBackground;

    [self.view addSubview:self.barChartView];
    
    // Setup title and header
    headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(BarChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(BarChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (BarChartViewControllerChartPadding * 2), BarChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = @"Steps in Last Hour";
    headerView.separatorColor = ColorBarChartHeaderSeparatorColor;
    self.barChartView.headerView = headerView;
    
    // Setup view used to display temperature upon selection
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.barChartView.frame), self.view.bounds.size.width, 100)];
    
    [self.view addSubview:self.informationView];

    [self readLog];
    [self updateHeader];
    [self.barChartView reloadData];
}

- (void)updateHeader
{
    // Set calorie label to new value
    NSMutableString *header_label = [NSMutableString stringWithString:@"Active Calories burned: "];
    int calories_burned = [self totalCaloriesBurned];
    [header_label appendString:[NSString stringWithFormat:@"%d", calories_burned]];
    headerView.subtitleLabel.text = header_label;
}

- (void)readLog
{
    // Read the log file that already exists and parse it into array format so we can add to it later
    NSString *file = [NSString stringWithContentsOfFile:self.logFilename encoding:NSUTF8StringEncoding error:nil];
    self.logData = [[file componentsSeparatedByString:@"\n"] mutableCopy];
    if ([[self.logData lastObject] isEqualToString:@""]) {
        [self.logData removeLastObject];
    }
    
    // If there are not enough samples, then add zeros to the array until there are enough samples and give a warning message.
    if (self.logData.count < BarChartViewControllerNumBars) {
        //[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Not enough samples, chart data will be limited." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        int x = (BarChartViewControllerNumBars-(int)self.logData.count)+1;
        for (int i = 0; i < x; i++){
            [self.logData insertObject:@"0,0" atIndex:0];
        }
    }
    
    // Parse the last BarChartViewControllerNumBars number of entries of the logData array into a data and time array since the Bar Chart expects separate arrays with only 1 dimension.
    
    self.chartData = [[NSMutableArray alloc] init];
    self.timeData = [[NSMutableArray alloc] init];
    
    for (int i = ((int)self.logData.count-(BarChartViewControllerNumBars+1)); i < self.logData.count; i++)
    {
        NSString *line = self.logData[i];
        NSArray *csv =[line componentsSeparatedByString:@","];
        NSString *time = [csv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *data = [csv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.chartData addObject:data];
        [self.timeData addObject:time];
    }
}
- (int)totalCaloriesBurned
{
    float calories_burned = 0;
    for (int i = 0; i < BarChartViewControllerNumBars; i++)
    {
        NSNumber *cur_act_value = [self.chartData objectAtIndex:i];
        NSNumber *next_act_value = [self.chartData objectAtIndex:(i + 1)];
        int act_value = abs([next_act_value intValue] - [cur_act_value intValue]);
        int num_steps = act_value/ActivityPerStep;
        calories_burned = calories_burned + (num_steps*CaloriesPerStep);
    }
    return (int)calories_burned;
}

- (void)initFakeData
{
    NSMutableArray *mutableChartData = [NSMutableArray array];
    NSMutableArray *mutableTimeData = [NSMutableArray array];
    for (int i=0; i<BarChartViewControllerNumBars+1; i++)
    {
        [mutableChartData addObject:[NSNumber numberWithFloat:MAX((BarChartViewControllerMinBarHeight), arc4random() % (BarChartViewControllerMaxBarHeight))*1000]];
        [mutableTimeData addObject:[NSNumber numberWithInt:0]];
    }
    _chartData = mutableChartData;
    _timeData = mutableTimeData;
}

- (IBAction)refreshPressed:(id)sender
{
    if (!self.device) {
        return;
    }
    
    if(self.demoSwitch.on) {
        return;
    }
    
    self.statusLabel.text = @"Connecting...";
    [self.device connectWithHandler:^(NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Cannot connect to logger, make sure it is charged and within range" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            return;
        }
        
        MBLEvent *event = [self.device retrieveEventWithIdentifier:@"com.mbientlab.ActivityTrackerEvent"];
        if (!event) {
            // Program to sum accelerometer RMS and log sample every 1 second
            event = [[self.device.accelerometer.rmsDataReadyEvent summationOfEvent] periodicSampleOfEvent:60000 identifier:@"com.mbientlab.ActivityTrackerEvent"];
        }
        if (!event.isLogging) {
            self.device.accelerometer.fullScaleRange = MBLAccelerometerRange8G;
            self.device.accelerometer.filterCutoffFreq = 0;
            self.device.accelerometer.highPassFilter = YES;
            [event startLogging];
        }
        
        self.progressBar.hidden = NO;
        self.progressBar.progress = 0;
        self.statusLabel.text = @"Syncing...";
        
        [event downloadLogAndStopLogging:NO handler:^(NSArray *array, NSError *error)  {
            if (error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } else {
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:self.logFilename];
                [handle seekToEndOfFile];
                for (MBLNumericData *data in array) {
                    NSLog(@"Activity added: %@", data);
                    NSString *line = [NSString stringWithFormat:@"%f,%d\n", data.timestamp.timeIntervalSince1970, data.value.intValue];
                    NSArray *csv =[line componentsSeparatedByString:@","];
                    NSString *time = [csv[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *data = [csv[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    [self.chartData addObject:data];
                    [self.timeData addObject:time];
                    [self.chartData removeObjectAtIndex:0];
                    [self.timeData removeObjectAtIndex:0];
                    
                    [handle writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
                    
                }
                [handle closeFile];

                self.progressBar.hidden = YES;
                self.statusLabel.text = @"Logging...";
                [self readLog];
                
                if (self.chartData.count) {
                    [self updateHeader];
                    [self.barChartView reloadData];
                }
            }
            
            // We have our data so get outta here
            [self.device disconnectWithHandler:nil];
        } progressHandler:^(float number, NSError *error) {
            [self.progressBar setProgress:number animated:YES];
        }];
    }];
}

- (IBAction)switchChanged:(id)sender
{
    if(self.demoSwitch.on)
    {
        [self initFakeData];
        [self.barChartView reloadData];
        [self updateHeader];
    }
    else
    {
        [self readLog];
        [self refreshPressed:self];
        [self.barChartView reloadData];
        [self updateHeader];
    }
}

- (IBAction)clearLogPressed:(id)sender
{
    [[NSFileManager defaultManager] createFileAtPath:self.logFilename contents:nil attributes:nil];
    [self.chartData removeAllObjects];
    [self.timeData removeAllObjects];
    [self readLog];
    [self.barChartView reloadData];
}

- (IBAction)resetDevicePressed:(id)sender
{
    if (!self.device) {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.device resetDevice];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.device connectWithHandler:^(NSError *error) {
            // Clear the log currently on the device
            MBLEvent *event = [self.device retrieveEventWithIdentifier:@"com.mbientlab.ActivityTrackerEvent"];
            if (event && event.isLogging) {
                [event downloadLogAndStopLogging:YES handler:^(NSArray *array, NSError *error) {
                    [hud hide:YES afterDelay:0.5];
                } progressHandler:nil];
            } else {
                [hud hide:YES afterDelay:0.5];
            }
            
            // Clean up log and data array in the App
            [self clearLogPressed:nil];
            
            // Reprogram and refresh the data.
            [self refreshPressed:nil];
        }];
    });
}


- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    return BarChartViewControllerNumBars;
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
    NSString *time_data = self.timeData[index+1];
    if ([time_data intValue] == 0) {
        [self.informationView setTitleText:@"Not Enough Data"];
    }
    else {
        NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:[time_data intValue]];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:timestamp
                                                             dateStyle:NSDateFormatterMediumStyle
                                                             timeStyle:NSDateFormatterShortStyle];
        [self.informationView setTitleText:dateString];
    }
    
    NSNumber *cur_act_value = [self.chartData objectAtIndex:index];
    NSNumber *next_act_value = [self.chartData objectAtIndex:((int)index + 1)];
    int act_value = abs([next_act_value intValue] - [cur_act_value intValue]);
    int num_steps = act_value/ActivityPerStep;
    [self.informationView setValueText:[NSString stringWithFormat:@"%d Steps", num_steps] unitText:nil];
    
    [self.informationView setHidden:NO animated:YES];
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
    [self.informationView setHidden:YES animated:YES];
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    int bar_height = abs([[self.chartData objectAtIndex:((int)index+1)] intValue] - [[self.chartData objectAtIndex:index] intValue]);
    return bar_height/ActivityPerStep;
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
