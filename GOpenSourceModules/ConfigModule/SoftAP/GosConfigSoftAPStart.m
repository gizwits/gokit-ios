//
//  GizConfigSoftAPStart.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPStart.h"
#import "GosSoftAPDetection.h"
#import "GosCommon.h"

@interface GosConfigSoftAPStart () <GizSoftAPDetectionDelegate, UIAlertViewDelegate>

@property (strong) GosSoftAPDetection *softapDetection;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump;
@property (weak, nonatomic) IBOutlet UIButton *btnHelp;
@property (weak, nonatomic) IBOutlet UIImageView *imgSoftapTips;

@property (weak, nonatomic) IBOutlet UIButton *connectToSoftApBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentSSID;

@end

@implementation GosConfigSoftAPStart

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.connectToSoftApBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.connectToSoftApBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.connectToSoftApBtn.layer setCornerRadius:19.0];
    
    // Do any additional setup after loading the view.
    // 为按钮添加下划线
    NSString *str = self.btnHelp.titleLabel.text;
    NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc] initWithString:str];
    [mstr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, str.length)];
    [self.btnHelp setAttributedTitle:mstr forState:UIControlStateNormal];

    self.imgSoftapTips.gifPath = [[NSBundle mainBundle] pathForResource:@"04-softap-tips" ofType:@"gif"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.imgSoftapTips startGIF];
    [self onUpdateSSID];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdateSSID) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.imgSoftapTips stopGIF];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)onUpdateSSID {
    self.currentSSID.text = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"current connect", nil), GetCurrentSSID()];
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
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = NSLocalizedString(@"Connect successfully, click to return App", nil);
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    GIZ_LOG_BIZ("switch_wifi_notify_show", "success", "wifi switch success notify is shown");
    
    return YES;
}

- (void)willEnterForeground {
    // 检测到 soft ap 模式，则跳转页面
    if ([GetCurrentSSID() hasPrefix:SSID_PREFIX]) {
        [self onPushToConfigurePage];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didBecomeActive {
    self.softapDetection = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (IBAction)onOpenConfig:(id)sender {
    // 开启后台 SoftAP 状态检测
    
    self.softapDetection = [[GosSoftAPDetection alloc] initWithSoftAPSSID:SSID_PREFIX delegate:self];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    NSURL *url = [NSURL URLWithString:@"prefs:root=WIFI"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil) disappear:YES];
    }
}

- (void)onPushToConfigurePage {
    [self.btnAutoJump sendActionsForControlEvents:UIControlEventTouchUpInside];
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
