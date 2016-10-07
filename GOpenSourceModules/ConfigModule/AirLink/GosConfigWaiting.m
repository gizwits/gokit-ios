//
//  GizConfigWaiting.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigWaiting.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"
#import "UAProgressView.h"

#import "GosConfigSoftAPStart.h"

//#import "GizSDKInstance.h"

#define CONFIG_TIMEOUT      60

@interface GosConfigWaiting () <GizWifiSDKDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) NSInteger timeout;

@property (weak, nonatomic) IBOutlet UILabel *textTips;
@property (weak, nonatomic) IBOutlet UILabel *textTimeoutTips;

@property (weak, nonatomic) IBOutlet UAProgressView *progressView;

@end

@implementation GosConfigWaiting

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
    self.timeout = CONFIG_TIMEOUT;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    GosCommon *dataCommon = [GosCommon sharedInstance];
    
    if (GetCurrentSSID().length > 0) {
        
        NSString *key = [dataCommon getPasswrodFromSSID:dataCommon.ssid];
        
        GIZ_LOG_BIZ("airlink_config_start", "success", "start airlink config, current ssid: %s, config ssid: %s", GetCurrentSSID().UTF8String, dataCommon.ssid.UTF8String);
        
        [GizWifiSDK sharedInstance].delegate = self;
        
        [[GizWifiSDK sharedInstance] setDeviceOnboarding:dataCommon.ssid key:key configMode:GizWifiAirLink softAPSSIDPrefix:nil timeout:CONFIG_TIMEOUT wifiGAgentType:@[@([GosCommon sharedInstance].airlinkConfigType)]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    } else {
        [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"Device is not connected to Wi-Fi, can not configure", nil) disappear:YES];
        [self onPushToSoftapFailed];
        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            usleep(500000);//0.5s
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Device is not connected to Wi-Fi, can not configure", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
//                [self onPushToSoftapFailed];
//            });
//        });
    }
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

    NSInteger elapsed = CONFIG_TIMEOUT-timeout;
    if (elapsed >= 1 && elapsed <= 8) {
        self.textTips.text = NSLocalizedString(@"Searching for devices", nil);
    } else if (elapsed >= 9 && elapsed <= 10) {
        self.textTips.text = NSLocalizedString(@"Searched to device", nil);
    } else if (elapsed >= 11 && elapsed <= CONFIG_TIMEOUT) {
        self.textTips.text = NSLocalizedString(@"Trying to connect with the device", nil);
        
        if (elapsed == 59) {
//            __block UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Bad network, switch to manual connection", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
//            [alertView show];
//            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                sleep(1);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
//                    alertView = nil;
//                });
//            });
        }
    } else {
        self.textTips.text = NSLocalizedString(@"Search for and connect the device", nil);
    }
    self.textTimeoutTips.text = [NSString stringWithFormat:@"%@ %i %@", NSLocalizedString(@"It is expected to need", nil), (int)timeout, NSLocalizedString(@"seconds", nil)];
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
    [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"Configuration success", nil) disappear:YES];
    [[GosCommon sharedInstance] onSucceed:device];
}

- (void)onConfigFailed {
    [[GosCommon sharedInstance] cancelAlertViewDismiss];
    [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"Bad network, switch to manual connection", nil) disappear:YES];
    [self onPushToSoftapFailed];
}

- (void)onWillEnterForeground {
//    [self onConfigFailed];
}

- (void)onPushToSoftapFailed {
    
//    UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GizSoftAP" bundle:nil] instantiateInitialViewController];
//    GizConfigSoftAPStart *GizConfigSoftAPStartVC = nav.viewControllers.firstObject;
//    GizConfigSoftAPStartVC.delegate = self;
//    [self.navigationController pushViewController:GizConfigSoftAPStartVC animated:YES];
    
    
    UIStoryboard *softapFlow =[UIStoryboard storyboardWithName:@"GosSoftAP" bundle:nil];
    UINavigationController *navCtrl = [softapFlow instantiateInitialViewController];
    
    UIViewController *softapStartCtrl = navCtrl.viewControllers.firstObject;
    
    NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
    
    @try {
        [viewControllers addObjectsFromArray:@[softapStartCtrl]];
        [self.navigationController setViewControllers:viewControllers];
    }
    @catch (NSException *exception) {
        GIZ_LOG_ERROR("cause exception: %s", exception.description.UTF8String);
    }
}

- (IBAction)onCancel:(id)sender {
//    SHOW_ALERT_CANCEL_CONFIG(self);
    [[GosCommon sharedInstance] showAlertCancelConfig:self];
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
        GIZ_LOG_BIZ("airlink_config_end", "success", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
//        for (GizWifiDevice* dev in [GizWifiSDK sharedInstance].deviceList) {
//            if ([dev.macAddress isEqualToString:mac]) {
//                [self onConfigSucceed:dev];
//                break;
//            }
//        }
        [self onConfigSucceed:nil];
    }
    else if (result.code == GIZ_SDK_DEVICE_CONFIG_IS_RUNNING) {
        GIZ_LOG_BIZ("airlink_config_end", "warn", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
        /*
        __block UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:info delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(3);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
                alertView = nil;
            });
        });
         
         */
    }
    else {
        GIZ_LOG_BIZ("airlink_config_end", "failed", "end airlink config，result is :%s, current ssid is %s, elapsed: %i(s)", info.UTF8String, GetCurrentSSID().UTF8String, CONFIG_TIMEOUT-self.timeout);
        [self onConfigFailed];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 1:
            [[GosCommon sharedInstance] onCancel];
            break;
        default:
            break;
    }
}

@end
