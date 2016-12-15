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

#define DEFAULT_SITE_DOMAIN     @"site.gizwits.com"

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
};

//#import "GizDeviceListViewController.h"

@class GizWifiDevice;


typedef void (^GosRecordPageBlock)(UIViewController *viewController);
typedef void (^GosSettingPageBlock)(UINavigationController *viewController);
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

@property (strong, readonly) NSString *tmpUser;
@property (strong, readonly) NSString *tmpPass;
@property (strong) NSString *uid;
@property (strong) NSString *token;
@property (assign) GizLoginStatus currentLoginStatus;
@property (strong) GosControlBlock controlHandler; //自定义控制页面
@property (strong) GosRecordPageBlock recordPageHandler; //自定义页面统计
@property (strong) GosSettingPageBlock settingPageHandler; //自定义设置页面
@property (strong) WXApiOnRespBlock WXApiOnRespHandler;

@property (nonatomic, strong) NSArray *configModuleValueArray;
@property (nonatomic, strong) NSArray *configModuleTextArray;
@property (assign) GizWifiGAgentType airlinkConfigType;

@property (nonatomic, strong) UIAlertView *cancelAlertView;

@property (nonatomic, strong) NSString *cid;
/********************* 初始化参数 *********************/
@property (nonatomic, strong, readonly) NSString *appID;
@property (nonatomic, strong, readonly) NSString *appSecret;
@property (nonatomic, strong, readonly) NSArray *productKey;
@property (nonatomic, assign, readonly) BOOL moduleSelectOn;
@property (nonatomic, strong, readonly) NSString *tencentAppID;
@property (nonatomic, strong, readonly) NSString *wechatAppID;
@property (nonatomic, strong, readonly) NSString *wechatAppSecret;
@property (nonatomic, assign, readonly) NSInteger pushType;
@property (nonatomic, strong, readonly) NSString *jpushAppKey;
@property (nonatomic, strong, readonly) NSString *bpushAppKey;
@property (nonatomic, assign, readonly) BOOL qqOn;
@property (nonatomic, assign, readonly) BOOL wechatOn;
@property (nonatomic, assign, readonly) BOOL anonymousLoginOn;

@property (nonatomic, strong, readonly) NSMutableDictionary *cloudDomainDict;

/******************** 定制界面样式 ********************/
@property (nonatomic, strong, readonly) UIColor *buttonColor;
@property (nonatomic, strong, readonly) UIColor *buttonTextColor;
@property (nonatomic, strong, readonly) UIColor *configProgressViewColor;
@property (nonatomic, strong, readonly) UIColor *navigationBarColor;
@property (nonatomic, strong, readonly) UIColor *navigationBarTextColor;
@property (nonatomic, assign, readonly) UIStatusBarStyle statusBarStyle;
@property (nonatomic, strong, readonly) NSString *addDeviceTitle;

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

/**
 * appID、appSecret、域名、端口
 * @note {"APPID": xxx, "APPSECRET": xxx, "site": {"domain": xxx, "port": xxx}, "api": {"domain": xxx, "port": xxx}}
 */
- (BOOL)setApplicationInfo:(NSDictionary *)info;
- (NSDictionary *)getApplicationInfo;
- (NSString *)getAppSecret;

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
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Discard your configuration?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.tag = ALERT_TAG_CANCEL_CONFIG;
    [alertView show];
}

static inline void SHOW_ALERT_EMPTY_PASSWORD(id delegate) {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Password is empty?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alertView.tag = ALERT_TAG_EMPTY_PASSWORD;
    [alertView show];
}

#define CUSTOM_YELLOW_COLOR() \
[UIColor colorWithRed:249/255.0 green:220/255.0 blue:39/255.0 alpha:1]

#define CUSTOM_GOKIT_COLOR() \
[UIColor colorWithRed:0.255 green:0.557 blue:0.796 alpha:1]
