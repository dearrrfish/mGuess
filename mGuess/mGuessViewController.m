//
//  mGuessViewController.m
//  mGuess
//
//  Created by Yu Jin on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "mGuessViewController.h"

@implementation mGuessViewController

@synthesize theSwitch;
//@synthesize accelXAxisLabel, accelYAxisLabel, accelZAxisLabel;
//@synthesize accelXAxisProgress, accelYAxisProgress,accelZAxisProgress;
@synthesize screenOrientationLabel;
@synthesize ipLabel, infoLabel;
@synthesize locLabel, speedLabel, locMgr, speedProgress;
@synthesize sndAvgLabel, sndPeakLabel, sndAvgProgress, sndPeakProgress;
@synthesize AltLabel, ActButton, ActButton2;


#pragma mark - Shared functions
// Formate current datetime to NSString
- (NSString *)getDateString {
    NSDate *date = [NSDate date];
    NSDateFormatter *dateToStringFormatter=[[NSDateFormatter alloc] init];
    [dateToStringFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *nsDate=[dateToStringFormatter stringFromDate:date];
    [dateToStringFormatter release];
    return nsDate;
}

//- (float)getTimestamp
//{
//    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//    NSDate *now;
//    NSDateComponents *comps = [[NSDateComponents alloc] init];
//    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | 
//    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
//    now=[NSDate date];
//    comps = [calendar components:unitFlags fromDate:now];
//    int year = [comps year];
//    int month = [comps month];
//    int day = [comps day];
//    int hour = [comps hour];
//    int min = [comps minute];
////    int sec = [comps second];
//    
//    // eg. 20120316.190315
//// float timestamp = day + month*100 + year*10000 + hour*0.01 + min*0.0001 + sec*0.000001;
//    float timestamp = min + hour*pow(10, 2) + day*pow(10, 4) + month*pow(10, 6) + year*pow(10, 8); 
//    return timestamp;
//}

#pragma mark - Trendulate delegate

- (void)requestSucceed:(NSString *)connectionIdentifier
{
    sendCnt++;
    if (sendCnt >= recordCntMax) {
        [ActButton setTitle:@"Request" forState:UIControlStateNormal];
        //ActButton.enabled = YES;
        actStage = 4;
    }
    return;
}
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    sendCnt++;
    if (sendCnt >= recordCntMax) {
        [ActButton setTitle:@"Reuqest" forState:UIControlStateNormal];
        //ActButton.enabled = YES;
        actStage = 4;
    }
    infoLabel.text = [NSString stringWithFormat:@"Error - %@", [self getDateString]];    
}




#pragma mark - Proximity
//proximity call back function
- (void)proximityDidChange:(NSNotification *)n 
{
    UIDevice *device = [n object];
    
    if (device.proximityState) {
        theSwitch.on = !(theSwitch.on);
        mProximity = 1;
    }
    else 
    {
        mProximity = 0;   
    }
}


#pragma mark - Audio/Microphone
//microphone call back function
- (void)avTimerCallback: (NSTimer *)timer {
    
    [avRecorder updateMeters];   
    mSndAvg = [avRecorder averagePowerForChannel:0];
    mSndPeak = [avRecorder peakPowerForChannel:0];
    
    sndAvgProgress.progress = ABS(1 + mSndAvg/120);
    sndPeakProgress.progress = ABS(1 + mSndPeak/120);
    sndAvgLabel.text = [NSString stringWithFormat:@"%8f", mSndAvg];
    sndPeakLabel.text = [NSString stringWithFormat:@"%8f", mSndPeak];
    
    NSLog(@"Avg：%f Peak：%f", mSndAvg, mSndPeak);
        
}

#pragma mark - Accelerometer
// accelerometer
- (void) accelerometer:(UIAccelerometer *) meter didAccelerate: (UIAcceleration *) accel {
    
    //Accelerometer Sensor XYZ normalized value
//    accelXAxisLabel.text = [NSString stringWithFormat:@"%8f", accel.x];
//    accelYAxisLabel.text = [NSString stringWithFormat:@"%8f", accel.y];
//    accelZAxisLabel.text = [NSString stringWithFormat:@"%8f", accel.z];
//    
//    //Accelerometer Sensor XYZ progress view
//    accelXAxisProgress.progress = ABS(accel.x);
//    accelYAxisProgress.progress = ABS(accel.y);
//    accelZAxisProgress.progress = ABS(accel.z);
    
    
    UIDevice *device = [UIDevice currentDevice] ; 
        
    //Get device orientation
    switch (device.orientation) {
        case UIDeviceOrientationFaceUp:
            screenOrientationLabel.text = @"Face Up";
            mPortrait = 0;
            break;
            
        case UIDeviceOrientationFaceDown:
            screenOrientationLabel.text = @"Face Down";
            mPortrait = 0;
            break;
        
        case UIDeviceOrientationUnknown:
            screenOrientationLabel.text = @"Unknown";
            mPortrait = 0;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            screenOrientationLabel.text = @"Landscape Left";
            mPortrait = 0;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            screenOrientationLabel.text = @"Landscape Right";
            mPortrait = 0;
            break;
            
        case UIDeviceOrientationPortrait:
            screenOrientationLabel.text = @"Portrait";
            mPortrait = 1;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            screenOrientationLabel.text = @"Portrait Upside Down";
            mPortrait = 0;
            break;
            
        default:
            screenOrientationLabel.text = @"Unable";
            mPortrait = 0;
            break;
    }
    
}


#pragma mark - Connections

- (id)fetchSSIDInfo
{
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    //NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CNCopyCurrentNetworkInfo((CFStringRef)ifnam);
        //NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        if (info && [info count]) {
            break;
        }
        [info release];
    }
    [ifs release];
    return [info autorelease];
}


// referenced from App Dev sample code - Reachability
- (void)checkInternet {
    internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus) {
        case NotReachable:
        {
            isInternetOK = NO;
            isWifi = NO;
            break;
        }
        case ReachableViaWiFi:
        {
            isInternetOK = YES;
            isWifi = YES;
            break;
        }
        case ReachableViaWWAN:
        {
            isInternetOK = YES;
            isWifi = NO;
            break;
        }
            
        default:
            isInternetOK = YES;
            isWifi = NO;
            break;
    }
}


- (void)checkHost {
    hostReachable = [Reachability reachabilityWithHostName:@"alpha.trendulate.com"];
    
    NetworkStatus hostStatus = [hostReachable currentReachabilityStatus];
    switch (hostStatus) {
        case NotReachable:
        {
            isHostOK = NO;
            isWifi = NO;
            break;
        }
        case ReachableViaWiFi:
        {
            isHostOK = YES;
            isWifi = YES;
            break;
        }
        case ReachableViaWWAN:
        {
            isHostOK = YES;
            isWifi = NO;
            break;
        }
            
        default:
            isHostOK = YES;
            isWifi = NO;
            break;
    }
}

- (BOOL)checkConnection {
    [self checkInternet];
    [self checkHost];
    
    if (mNetwork != nil) {
        [mNetwork release];
        mNetwork = nil;
    }

    
    if (isWifi) {
        mNetwork = [[NSString alloc] initWithString:[[self fetchSSIDInfo] objectForKey:@"SSID"]];
    }
    else
    {
        mNetwork = [[NSString alloc] initWithString:@"<3G>"];
    }
    
    if (isInternetOK && isHostOK) {
        ipLabel.text = [@"Connected to host via " stringByAppendingString:mNetwork];
        infoLabel.text = [[self getDateString] stringByAppendingString:@"\nChecked network connection."];
        return YES;
    }
    else
    {
        if(!isInternetOK)
        {
            if (mNetwork != nil) {
                [mNetwork release];
                mNetwork = nil;
            }
            mNetwork = [[NSString alloc] initWithString:@"<NA>"];
            ipLabel.text = @"Internet connection failed.";
        }
        else if(!isHostOK)
        {
            ipLabel.text = [@"Failed to connect to host via " stringByAppendingString:mNetwork];
        }
        infoLabel.text = [[self getDateString] stringByAppendingString:@"\nChecked network connection."];
        return NO;
 
    }    
    
}


#pragma mark - Location
- (void)locMgrInit
{
    //locationManager initialize
    locMgr = [[CLLocationManager alloc] init];
    locMgr.delegate = self;
    
    // unit (0.01 km)
    locMgr.distanceFilter = 0.05;
    
    locMgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *) oldLocation {
    
    mLat = newLocation.coordinate.latitude;
    mLng = newLocation.coordinate.longitude;
    mSpeed = newLocation.speed;
    
    NSString *longtitudeText = [@"Lng:" stringByAppendingFormat:[NSString stringWithFormat:@"%f", newLocation.coordinate.longitude]];
    NSString *latitudeText = [@" Lat:" stringByAppendingFormat:[NSString stringWithFormat:@"%f", newLocation.coordinate.latitude]];
//    NSString *altitudeText = [@" Alt:" stringByAppendingFormat:[NSString stringWithFormat:@"%f", newLocation.altitude]];
    
    NSString *speedText = [NSString stringWithFormat:@"%.4f m/s", [newLocation speed]];
    
    locLabel.text = [longtitudeText stringByAppendingFormat:latitudeText];
    speedLabel.text = speedText;
//    AltLabel.text = altitudeText;
    
    speedProgress.progress = ABS(mSpeed/10);
    
}


#pragma mark - Initilization
- (void)initSensors
{
    // Apple reference values
    NSURL *url=[NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *set = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithFloat:44100.0],
                         AVSampleRateKey,     
                         [NSNumber numberWithInt:kAudioFormatAppleLossless],
                         AVFormatIDKey,     
                         [NSNumber numberWithInt:1], 
                         AVNumberOfChannelsKey,     
                         [NSNumber numberWithInt:AVAudioQualityMax],
                         AVEncoderAudioQualityKey,     
                         nil];  
    NSError *error;
    
    avRecorder=[[AVAudioRecorder alloc] initWithURL:url settings:set error:&error]; 
    
        
    [self locMgrInit];

}


- (void)startSensing
{
    // Initialize variables
    mProximity = 0;
    mPortrait = 0;  
    
    // accelerometer settings
    accelerometer = [UIAccelerometer sharedAccelerometer];
    accelerometer.updateInterval = 1.0f/10.0f;  // time interval, 10times per second
    accelerometer.delegate = self;

    // av audio control, microphone
    // reference from apple settings
    
    if (avRecorder) {     
        [avRecorder prepareToRecord];    
        avRecorder.meteringEnabled=YES;    
        [avRecorder record];                
        
        avTimer=[NSTimer scheduledTimerWithTimeInterval:0.5
                                                 target:self
                                               selector:@selector(avTimerCallback:)
                                               userInfo:nil repeats:YES]; 
    } 
    else {    
        NSLog(@"error"); 
    }
    
    
    //proximity control
    UIDevice *device = [UIDevice currentDevice];
    device.proximityMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityDidChange:)
                                                 name:@"UIDeviceProximityStateDidChangeNotification"
                                               object:device];
    // check connections
    [self checkConnection];
    netTimer = [NSTimer scheduledTimerWithTimeInterval:3 
                                                target:self 
                                              selector:@selector(checkConnection)
                                              userInfo:nil repeats:YES];
    
    // track location
    [locMgr stopUpdatingLocation];
    [locMgr startUpdatingLocation];
    


}

- (void)stopSensing
{
    accelerometer = nil;
    
    [avTimer invalidate];
    avTimer = nil;
    
    [netTimer invalidate];
    netTimer =nil;
    
    [accelerometer release];
    accelerometer = nil;
    
    [locMgr stopUpdatingLocation];
}

#pragma mark - Trends
- (void)createTrend
{
    NSDictionary *schema1 = [NSDictionary dictionaryWithObjectsAndKeys:@"pu", @"unit", @"numeric", @"type", @"CountIndex", @"label", nil];
    NSDictionary *schema2 = [NSDictionary dictionaryWithObjectsAndKeys:@"pu", @"unit", @"string", @"type", @"Timestamp", @"label", nil];
    NSDictionary *schema3 = [NSDictionary dictionaryWithObjectsAndKeys:@"degree", @"unit", @"numeric", @"type", @"Longitude", @"label", nil];
    NSDictionary *schema4 = [NSDictionary dictionaryWithObjectsAndKeys:@"degree", @"unit", @"numeric", @"type", @"Latitude", @"label", nil];
    NSDictionary *schema5 = [NSDictionary dictionaryWithObjectsAndKeys:@"m/s", @"unit", @"numeric", @"type", @"Speed", @"label", nil];
    NSDictionary *schema6 = [NSDictionary dictionaryWithObjectsAndKeys:@"pu", @"unit", @"string", @"type", @"Network", @"label", nil];
    NSDictionary *schema7 = [NSDictionary dictionaryWithObjectsAndKeys:@"dB", @"unit", @"numeric", @"type", @"SoundAveragePower", @"label", nil];
    NSDictionary *schema8 = [NSDictionary dictionaryWithObjectsAndKeys:@"dB", @"unit", @"numeric", @"type", @"SoundPeakPower", @"label", nil];
    NSDictionary *schema9 = [NSDictionary dictionaryWithObjectsAndKeys:@"pu", @"unit", @"numeric", @"type", @"Proximity", @"label", nil];

    NSArray *schema = [NSArray arrayWithObjects:schema1, schema2, schema3, schema4, schema5, schema6, schema7, schema8, schema9, nil];
    
    UUIDForCreatingTrendWithMultiSchemas = [engine createTrendWithName:@"mGuess" schemas:schema privacy:@"public" description:@"Data trend of mGuess App." node:@""];

}

- (void)sendTrend
{    
    sendCnt = 0;
    engine = [[TUTrendulateEngine TrendulateEngineWithUsername:@"dearrrfish" password:@"momo88415" delegate:self] retain];
    //    [self createTrend];       // create trend, run once, then commented

    // sort sending array by countIndex
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"CountIndex" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [pointQueue sortUsingDescriptors:sortDescriptors];
    
    for (NSDictionary *dict in pointQueue) {
        NSString *ts = [dict objectForKey:@"Timestamp"];
        UUIDForCreatingTrendPointForMultiSchemaTrend = [engine createTrendPointForTrend:@"mGuess"
                                                                                   data:dict
                                                                                   note:ts];
    }
    
}




#pragma mark - Record and generate trend points
- (void)singleRecord:(int)count timeIndex:(NSString *)index deviceOrientation:(int)orient longitude:(float)lng latitude:(float)lat speed:(float)speed network:(NSString *)conn soundAveragePower:(float)sndAvg soundPeakPower:(float)sndPeak proximity:(int)proximity
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:count], @"CountIndex",
                          index, @"Timestamp",
                          [NSNumber numberWithInt:orient], @"DeviceOrientation",
                          [NSNumber numberWithFloat:lng], @"Longitude",
                          [NSNumber numberWithFloat:lat], @"Latitude",
                          [NSNumber numberWithFloat:speed], @"Speed",
                          conn, @"Network",
                          [NSNumber numberWithFloat:sndAvg], @"SoundAveragePower",
                          [NSNumber numberWithFloat:sndPeak], @"SoundPeakPower",
                          [NSNumber numberWithInt:proximity], @"Proximity",
                          nil];
    [pointQueue addObject:dict];
}

- (void)record
{
    if (recordCnt < recordCntMax) {
        recordCnt++;
//        NSLog(@"Count - %d", recordCnt);
        
        int cnt = recordCnt;
        NSString *index = mIndex;
//        NSLog(@"Timestamp: %@", index);
        int portrait = mPortrait;
        float lat = mLat;
        float lng = mLng;
        float speed = mSpeed;
        NSString *network = mNetwork;
//        NSLog(@"network %@", mNetwork);
        float sndAvg = mSndAvg;
        float sndPeak = mSndPeak;
        int proximity = mProximity;
        
        [self singleRecord:cnt timeIndex:index deviceOrientation:portrait longitude:lng latitude:lat speed:speed network:network soundAveragePower:sndAvg soundPeakPower:sndPeak proximity:proximity];
    }
    else
    {
        [recordTimer invalidate];
        [self stopSensing];
        
        AltLabel.text = [NSString stringWithFormat:@"After:%@",mIndex];
        
        actStage = 2;
        [ActButton setTitle:@"Send" forState:UIControlStateNormal];
    }
    
}

- (void)startRecord
{
    pointQueue = [NSMutableArray new];
    mIndex = [[NSString alloc] initWithString:[self getDateString]];
//    mIndex = [self getTimestamp];
    AltLabel.text = [NSString stringWithFormat:@"Before:%@",mIndex];

    recordCnt = 0;
    recordCntMax = 240;
    recordTimeInterval = 0.5;

    recordTimer = [NSTimer scheduledTimerWithTimeInterval:recordTimeInterval
                                          target:self
                                                 selector:@selector(record)
                                        userInfo:nil repeats:YES];
    
}

- (NSString *)requestGuess:(NSString *)timestamp
{
    NSString *ts = [timestamp stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://mguessweb.appspot.com/?timestamp=%@", ts]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *boundary = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *boundaryString = [NSString stringWithFormat: 
                                @"multipart/form-data; boundary=%@", boundary];

    [request addValue: boundaryString forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod:@"GET"];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request 
                                           returningResponse:&response error:&error];
    [request release];
    
    if (error) {
        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                 message:[error localizedDescription] 
                                                                delegate:nil 
                                                       cancelButtonTitle:@"Close" 
                                                       otherButtonTitles:nil];
        [errorAlertView show];
        [errorAlertView release];
        return nil;
    }
    
        
    NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
//    NSString *jsonString = [NSString stringWithFormat:@"[%@]", resultString];
    
//    NSLog(resultString);
    
    NSData *resultData = [resultString dataUsingEncoding:NSUTF8StringEncoding];

    id jsonObject = [NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingAllowFragments error:&error];
    if (jsonObject != nil && error == nil){
        NSLog(@"Successfully deserialized...");
        if ([jsonObject isKindOfClass:[NSDictionary class]]){
            NSDictionary *deserializedDictionary = (NSDictionary *)jsonObject;
            NSLog(@"Dersialized JSON Dictionary = %@", deserializedDictionary);
        } else if ([jsonObject isKindOfClass:[NSArray class]]){
            NSArray *deserializedArray = (NSArray *)jsonObject;
            NSLog(@"Dersialized JSON Array = %@", deserializedArray);
        } else {
        NSLog(@"An error happened while deserializing the JSON data.");
    }
    }
    
    return resultString;
}

//TODO

- (void)truthSurvey:(NSString *)r surveyStep:(int)step
{
    UIAlertView *resultAlert = nil;
    if (step == 0) {
        resultAlert = [[UIAlertView alloc] initWithTitle:@"Movement Correct?"  
                                                              message:r 
                                                             delegate:self 
                                                    cancelButtonTitle:@"Yes"
                                                    otherButtonTitles:@"No", nil];
        [resultAlert show];
    }
    
    else if(step == 1)
    {
        resultAlert = [[UIAlertView alloc] initWithTitle:@"Interior/Outdoor Correct?"  
                                                 message:r 
                                                delegate:self 
                                       cancelButtonTitle:@"Yes"
                                       otherButtonTitles:@"No", nil];
        [resultAlert show];
    }
    else if(step == 2)
    {
        resultAlert = [[UIAlertView alloc] initWithTitle:@"Call Event Correct?"  
                                                 message:r 
                                                delegate:self 
                                       cancelButtonTitle:@"Yes"
                                       otherButtonTitles:@"No", nil];
        [resultAlert show]; 
    }
    
    
    if (resultAlert != nil)
    {
        resultAlert = nil;
        [resultAlert release];
    }
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString * string=[NSString stringWithFormat:@"You pressed %@",[alertView buttonTitleAtIndex:buttonIndex]];
    NSLog(@"%@ %d",string, buttonIndex);
    alertChoice = buttonIndex;

    if (alertStep <= 2) {
        alertStep++;
    }
    else
    {
        alertStep = -1;
    }
    
}


- (IBAction)buttonAction:(id)sender
{
    // action stage, 0 - beginning, 1 - recording, 2 - recorded, 3 - sending, 4 - sended, 5 - requesting, 6 - received
    switch (actStage) {
        case 0:
            actStage = 1;
            [ActButton setTitle:@"Recording" forState:UIControlStateNormal];
            [self initSensors];
            [self startSensing];
            [self startRecord];
            
            break;
        case 1: //disable
            break;
        case 2:
            // if internet connection stable, start to send trend points.
            if ([self checkConnection]) {
                actStage = 3;
                [ActButton setTitle:@"Sending" forState:UIControlStateNormal];
                //ActButton.enabled = NO;
                [self sendTrend];
            }
            break;
        case 3:
            break;
        case 4:
//            mIndex = @"2012-04-20 14:07:12";
            if ([self checkConnection]) {
                [ActButton setTitle:@"Requesting" forState:UIControlStateNormal];
                //ActButton.enabled = NO;
                result = [self requestGuess:mIndex];
                
                
                if (result != nil) {
                    actStage = 5;
                    UIAlertView *resultAlert = [[UIAlertView alloc] initWithTitle:@"Is Guess Correct?"  
                                                                          message:result 
                                                                         delegate:self 
                                                                cancelButtonTitle:@"Yes"
                                                                otherButtonTitles:@"No", nil];
                    [resultAlert show];
                    [resultAlert release];
                    
//                    
//                    while (alertStep != -1) {
//                        [self truthSurvey:result surveyStep:alertStep];
//                    }
                    
                }
                else
                {
                    [ActButton setTitle:@"Retry" forState:UIControlStateNormal];
                }
            }
            break;
        case 5:
            actStage = 0;
            [ActButton setTitle:@"Start" forState:UIControlStateNormal];
            break;
        case 6:
            // TODO - Receiving result
            break;
            
        default:
            break;
    }
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)dealloc
{
    [avRecorder release];
    [avTimer release];
    [netTimer release];
    [accelerometer release];
    [internetReachable release];
    [hostReachable release];
    [pointQueue release];
    [mNetwork release];
    [mIndex release];

}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        // never lock screen
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    alertStep = -1;
    actStage = 0;
    requestSuccess = false;
    [ActButton setTitle:@"Start" forState:UIControlStateNormal];
    
        
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
