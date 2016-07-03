//
//  GizConfigSoftAPWaiting.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPWaiting.h"
#import "GosCommon.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "UAProgressView.h"

//#import "GizSDKInstance.h"

#define CONFIG_TIMEOUT      60

@interface GosConfigSoftAPWaiting () <GizWifiSDKDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger timeout;

@property (weak, nonatomic) IBOutlet UILabel *textTimeoutTips;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump2;

@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@end

@implementation GosConfigSoftAPWaiting

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.progressView.tintColor = [GosCommon sharedInstance].configProgressViewColor;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60.0, 20.0)];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.userInteractionEnabled = NO; // Allows tap to pass through to the progress view.
    self.progressView.centralView = label;
    self.progressView.progressChangedBlock = ^(UAProgressView *progressView, CGFloat progress) {
        [(UILabel *)progressView.centralView setText:[NSString stringWithFormat:@"%2.0f%%", progress * 100]];
    };
    [self.progressView setProgress:0.1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    GosCommon *dataCommon = [GosCommon sharedInstance];
    
    self.timeout = CONFIG_TIMEOUT;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    
    NSString *key = [dataCommon getPasswrodFromSSID:dataCommon.ssid];
    
    GIZ_LOG_BIZ("softap_config_start", "success", "start softap config, current ssid: %s, config ssid: %s", GetCurrentSSID().UTF8String, dataCommon.ssid.UTF8String);
    
    [GizWifiSDK sharedInstance].delegate = self;
//    [[GizWifiSDK sharedInstance] setDeviceWifi:dataCommon.ssid key:key mode:XPGWifiSDKSoftAPMode softAPSSIDPrefix:SSID_PREFIX timeout:CONFIG_TIMEOUT wifiGAgentType:nil];
    [[GizWifiSDK sharedInstance] setDeviceOnboarding:dataCommon.ssid key:key configMode:GizWifiSoftAP softAPSSIDPrefix:SSID_PREFIX timeout:CONFIG_TIMEOUT wifiGAgentType:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [GizWifiSDK sharedInstance].delegate = nil;
    [self.timer invalidate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTimeout:(NSInteger)timeout {
    _timeout = timeout;
    
    float timeNow = (CONFIG_TIMEOUT-timeout);
    float secOffset = 0.0333*timeNow+(0.5*1.0/-1800)*timeNow*timeNow;
    [self.progressView setProgress:secOffset animated:YES];
    
//    [self.progressView setProgress:(CONFIG_TIMEOUT-timeout)/((float)(CONFIG_TIMEOUT)) animated:YES];
    if (timeout == 58) {
        self.textTimeoutTips.hidden = NO;
    }
}

- (void)onTimer {
    self.timeout--;
    if (0 == self.timeout) {
        [self.timer invalidate];
    }
}

- (void)onConfigSucceed:(GizWifiDevice *)device {
    [self.timer invalidate];
    
    [[GosCommon sharedInstance] cancelAlertViewDismiss];
    
    __block UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Configuration success", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alertView show];
    [[GosCommon sharedInstance] onSucceed:device];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
        });
    });
}

- (void)onConfigSSIDMotMatched {
    [[GosCommon sharedInstance] cancelAlertViewDismiss];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.btnAutoJump2 sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}

- (void)onConfigFailed {
    [[GosCommon sharedInstance] cancelAlertViewDismiss];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.btnAutoJump sendActionsForControlEvents:UIControlEventTouchUpInside];
    });
}

- (void)onWillEnterForeground {
//    [self onConfigFailed];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceOnboarding:(NSError *)result mac:(NSString *)mac did:(NSString *)did productKey:(NSString *)productKey {
    NSString *info = [NSString stringWithFormat:@"%@, %@", @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
    if (result.code == GIZ_SDK_SUCCESS) {
        GIZ_LOG_BIZ("softap_config_end", "success", "end softap config，result is :%s，current ssid is %s, elapsed: %i(s), mac: %s", info.UTF8String, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout, mac.UTF8String);
//        for (GizWifiDevice *dev in [GizWifiSDK sharedInstance].deviceList) {
//            if ([dev.macAddress isEqualToString:mac]) {
//                [self onConfigSucceed:dev];
//            }
//        }
        [self onConfigSucceed:nil];
    } else {
        GIZ_LOG_BIZ("softap_config_end", "failed", "end softap config，result is :%s，current ssid is %s, elapsed: %i(s)", info.UTF8String, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
        if ([GetCurrentSSID() hasPrefix:SSID_PREFIX]) {
            [self onConfigFailed];
        } else {
            if (GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED == result.code) {
                [self onConfigSSIDMotMatched];
            } else {
                [self onConfigFailed];
            }
        }
    }
}

/*
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceWifi:(GizWifiDevice *)device result:(int)result {
    if (result == GIZ_SDK_SUCCESS) {
        GIZ_LOG_BIZ("softap_config_end", "success", "end softap config，errorCode is %i，current ssid is %s, elapsed: %i(s)", result, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
        [self onConfigSucceed:device];
    } else {
        GIZ_LOG_BIZ("softap_config_end", "failed", "end softap config，errorCode is %i，current ssid is %s, elapsed: %i(s)", result, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
        if ([GetCurrentSSID() hasPrefix:SSID_PREFIX]) {
            [self onConfigFailed];
        } else {
            if (XPGWifiError_CONFIGURE_SSID_NOT_MATCHED == result) {
                [self onConfigSSIDMotMatched];
            } else {
                [self onConfigFailed];
            }
        }
    }
}
*/
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 1:
            [[GosCommon sharedInstance] onCancel];
            break;
        default:
            break;
    }
}

- (IBAction)onCancel:(id)sender {
//    SHOW_ALERT_CANCEL_CONFIG(self);
    [[GosCommon sharedInstance] showAlertCancelConfig:self];
}

@end
