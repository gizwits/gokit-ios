//
//  Common.h
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImageView+PlayGIF.h"
#import "MBProgressHUD.h"
#import "GizLog.h"
#import <GizWifiSDK/GizWifiDefinitions.h>
#import <GizWifiSDK/GizWifiSDK.h>
#import "WXApi.h"

/**
 登录类型类型
 */
typedef NS_ENUM(NSInteger, GizLoginStatus) {
    
    /**
     未登录
     */
    GizLoginNone = 0,
    
    /**
     用户登录
     */
    GizLoginUser = 1,
    
    /**
     匿名登录
     */
    GizLoginAnonymous = 2,
    
    /**
     尝试匿名登录中
     */
    GizLoginAnonymousProcess = 3,
    
    /**
     匿名登录中断
     */
    GizLoginAnonymousCancel = 4,
};

//#import "GizDeviceListViewController.h"

@class GizWifiDevice;
typedef void (^GosControlBlock)(GizWifiDevice *device, UIViewController *deviceListController);
typedef void (^WXApiOnRespBlock)(BaseResp *resp);

@interface GosCommon : NSObject

+ (instancetype)sharedInstance;

- (id)init NS_UNAVAILABLE;

+ (BOOL)isMobileNumber:(NSString *)mobileNum;

- (void)saveUserDefaults:(NSString *)username password:(NSString *)password uid:(NSString *)uid token:(NSString *)token;
- (void)removeUserDefaults;

@property (strong) NSString *ssid;

@property (assign) id delegate;

@property (strong) NSString *uid;
@property (strong) NSString *token;
@property (assign) GizLoginStatus currentLoginStatus;
@property (strong) GosControlBlock controlHandler;
@property (strong) WXApiOnRespBlock WXApiOnRespHandler;

@property (nonatomic, strong) NSArray *configModuleValueArray;
@property (nonatomic, strong) NSArray *configModuleTextArray;
@property (assign) GizWifiGAgentType airlinkConfigType;

@property (nonatomic, strong) UIAlertView *cancelAlertView;

@property (nonatomic, strong) NSString *cid;
/********************* 初始化参数 *********************/
@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *appSecret;
@property (nonatomic, strong) NSArray *productKey;
@property (nonatomic, assign) BOOL moduleSelectOn;
@property (nonatomic, strong) NSString *tencentAppID;
@property (nonatomic, strong) NSString *wechatAppID;
@property (nonatomic, strong) NSString *wechatAppSecret;
@property (nonatomic, assign) NSInteger pushType;
@property (nonatomic, strong) NSString *jpushAppKey;
@property (nonatomic, strong) NSString *bpushAppKey;

//@property (nonatomic, strong) NSString *openAPIDomain;
//@property (nonatomic, assign) NSInteger openAPIPort;
//@property (nonatomic, strong) NSString *siteDomain;
//@property (nonatomic, assign) NSInteger sitePort;
//@property (nonatomic, strong) NSString *pushDomain;
//@property (nonatomic, assign) NSInteger pushPort;

@property (nonatomic, strong) NSMutableDictionary *cloudDomainDict;

/******************** 定制界面样式 ********************/
@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, strong) UIColor *buttonTextColor;
@property (nonatomic, strong) UIColor *configProgressViewColor;
@property (nonatomic, strong) UIColor *navigationBarColor;
@property (nonatomic, strong) UIColor *navigationBarTextColor;
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong) NSString *addDeviceTitle;

//[UIColor purpleColor]
//#define BUTTON_COLOR [UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1]
#define BUTTON_TEXT_COLOR [UIColor colorWithRed:0.322 green:0.244 blue:0.747 alpha:1]

//@property (assign) BOOL isLogin;
//@property (assign) BOOL hasBeenLoggedIn;

//@property (strong) GizDeviceListViewController *deviceList;

/*
 * ssid 缓存
 */
- (void)saveSSID:(NSString *)ssid key:(NSString *)key;
- (NSString *)getPasswrodFromSSID:(NSString *)ssid;

/*
 * 判断错误码
 */
- (NSString *)checkErrorCode:(GizWifiErrorCode)errorCode;

/*
 * UIAlertView
 */
- (void)showAlert:(NSString *)message disappear:(BOOL)disappear;

/*
 * 回到主页
 */
- (void)onCancel;
- (void)onSucceed:(GizWifiDevice *)device;
- (void)showAlertCancelConfig:(id)delegate;
- (void)cancelAlertViewDismiss;

@end

#define SSID_PREFIX     @"XPG-GAgent"
#import <SystemConfiguration/CaptiveNetwork.h>

static inline NSString *GetCurrentSSID() {
    NSArray *interfaces = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    for (NSString *interface in interfaces) {
        NSDictionary *ssidInfo = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)interface);
        NSString *ssid = ssidInfo[(__bridge_transfer NSString *)kCNNetworkInfoKeySSID];
        if (ssid.length > 0) {
            return ssid;
        }
    }
    return @"";
}

id GetControllerWithClass(Class class, UITableView *tableView, NSString *reuseIndentifer);

#define ALERT_TAG_CANCEL_CONFIG     1001
#define ALERT_TAG_EMPTY_PASSWORD    1002

static inline void SHOW_ALERT_CANCEL_CONFIG(id delegate) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Discard your configuration?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.tag = ALERT_TAG_CANCEL_CONFIG;
    [alertView show];
}

static inline void SHOW_ALERT_EMPTY_PASSWORD(id delegate) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Password is empty?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.tag = ALERT_TAG_EMPTY_PASSWORD;
    [alertView show];
}

#define CUSTOM_YELLOW_COLOR() \
[UIColor colorWithRed:249/255.0 green:220/255.0 blue:39/255.0 alpha:1]

#define CUSTOM_GOKIT_COLOR() \
[UIColor colorWithRed:0.255 green:0.557 blue:0.796 alpha:1]