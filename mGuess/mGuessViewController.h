//
//  mGuessViewController.h
//  mGuess
//
//  Created by Yu Jin on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TUTrendulateEngine/TUTrendulateEngine.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface mGuessViewController : UIViewController <UIAlertViewDelegate, UIAccelerometerDelegate, CLLocationManagerDelegate, TUTrendulateEngineDelegate>
{
    int alertChoice;
    int alertStep;
    BOOL requestSuccess;
    NSString *result;
    
    // sensors
    AVAudioRecorder *avRecorder;
    NSTimer *avTimer;
    UIAccelerometer *accelerometer;
    
    NSTimer *netTimer;
    Reachability *internetReachable;
    Reachability *hostReachable;
    BOOL isInternetOK;
    BOOL isHostOK;
    BOOL isWifi;
    
    CLLocationManager *locMgr;
    
    // data collecting
    NSString *mIndex;
//    float mIndex;
    int mPortrait;  // 0:non-portrait, 1:portrait
    float mLat, mLng, mSpeed;
    NSString *mNetwork;     // 3G/NA/<SSID>
    float mSndAvg, mSndPeak;
    int mProximity;     // 0:on, 1:off
    
    NSMutableArray *pointQueue;
    int recordCnt;
    int recordCntMax;
    float recordTimeInterval;
    NSTimer *recordTimer;
    
    
    // trendulate
    TUTrendulateEngine *engine;
    NSString *UUIDForCreatingTrendPointForMultiSchemaTrend;
    NSString *UUIDForCreatingTrendWithMultiSchemas;
    
    // action stage, 0 - beginning, 1 - recording, 2 - recorded, 3 - sending, 4 - sended, 5 - requesting, 6 - received
    int actStage;
    int sendCnt;
    
}

@property (retain, atomic) IBOutlet UISwitch *theSwitch;
//@property (retain, atomic) IBOutlet UIProgressView *accelXAxisProgress;
//@property (retain, atomic) IBOutlet UIProgressView *accelYAxisProgress;
//@property (retain, atomic) IBOutlet UIProgressView *accelZAxisProgress;
//@property (retain, atomic) IBOutlet UILabel *accelXAxisLabel;
//@property (retain, atomic) IBOutlet UILabel *accelYAxisLabel;
//@property (retain, atomic) IBOutlet UILabel *accelZAxisLabel;
@property (retain, atomic) IBOutlet UILabel *screenOrientationLabel;
@property (retain, atomic) IBOutlet UILabel *ipLabel;
@property (retain, atomic) IBOutlet UILabel *infoLabel;
@property (retain, atomic) IBOutlet UILabel *locLabel;
@property (retain, atomic) IBOutlet UILabel *speedLabel;
@property (retain, atomic) CLLocationManager *locMgr;

@property (retain, atomic) IBOutlet UIProgressView *sndAvgProgress;
@property (retain, atomic) IBOutlet UIProgressView *sndPeakProgress;
@property (retain, atomic) IBOutlet UIProgressView *speedProgress;
@property (retain, atomic) IBOutlet UILabel *sndAvgLabel;
@property (retain, atomic) IBOutlet UILabel *sndPeakLabel;
@property (retain, atomic) IBOutlet UILabel *AltLabel;
@property (retain, atomic) IBOutlet UIButton *ActButton;
@property (retain, atomic) IBOutlet UIButton *ActButton2;

-(IBAction)buttonAction:(id)sender;
-(void)truthSurvey:(NSString *)result surveyStep:(int)step;

@end

