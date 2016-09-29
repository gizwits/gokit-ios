//
//  GizConfigSoftAPNotSame.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPNotSame.h"
#import "GosCommon.h"
#import "GosSoftAPDetection.h"

@interface GosConfigSoftAPNotSame () <UIAlertViewDelegate, GizSoftAPDetectionDelegate>

@property (strong, nonatomic) GosSoftAPDetection *softapDetection;
@property (weak, nonatomic) IBOutlet UITextView *textTips;

@property (weak, nonatomic) IBOutlet UIButton *btnConnect;

@end

@implementation GosConfigSoftAPNotSame

- (void)viewDidLoad {
    [super viewDidLoad];
    self.btnConnect.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.btnConnect setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.btnConnect.layer setCornerRadius:19.0];
    if (nil == [GosCommon sharedInstance].ssid) {
        [GosCommon sharedInstance].ssid = @"";
    }
    self.textTips.text = [self.textTips.text stringByReplacingOccurrencesOfString:@"xxwifixx" withString:[GosCommon sharedInstance].ssid];
    
    NSString *btnTitle = [self.btnConnect.titleLabel.text stringByReplacingOccurrencesOfString:@"xxwifixx" withString:[GosCommon sharedInstance].ssid];
    [self.btnConnect setTitle:btnTitle forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)didSoftAPModeDetected:(NSString *)ssid {
    GIZ_LOG_DEBUG("ssid:%s", ssid.UTF8String);
    
    if (nil == ssid) {
        return NO;
    }

    NSString *ossid = [GosCommon sharedInstance].ssid;
    
    if ([ossid isEqualToString:ssid]) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate date];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.alertBody = NSLocalizedString(@"Connect successfully, click to return App", nil);
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];

        GIZ_LOG_BIZ("switch_wifi_notify_show", "success", "wifi switch success notify is shown");

        return YES;
    }
    
    return NO;
}

- (void)willEnterForeground {
    // 检测到 soft ap 模式，则跳转页面
    NSString *ssid = [GosCommon sharedInstance].ssid;
    if ([GetCurrentSSID() isEqualToString:ssid]) {
        [[GosCommon sharedInstance] onCancel];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didBecomeActive {
    self.softapDetection = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (IBAction)onGoConnect:(id)sender {
    // 开启后台 SoftAP 状态检测
    
    NSString *ssid = [GosCommon sharedInstance].ssid;
    self.softapDetection = [[GosSoftAPDetection alloc] initWithSoftAPSSID:ssid delegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    NSURL *url = [NSURL URLWithString:@"prefs:root=WIFI"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil) disappear:YES];
    }
}

- (IBAction)onCancel:(id)sender {
    SHOW_ALERT_CANCEL_CONFIG(self);
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
