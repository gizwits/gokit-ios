//
//  AppDelegate.m
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "AppDelegate.h"
#import "GizLog.h"

#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"

#import "GosPushManager.h"

#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"

#import "GosDeviceController.h"
#import "DeviceController.h"

@interface AppDelegate () <GizWifiSDKDelegate, WXApiDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GosCommon sharedInstance].controlHandler = ^(GizWifiDevice *device, UIViewController *deviceListController) {
        
        // 避免多次点击出现多次跳转到控制界面
        if ([deviceListController.navigationController.topViewController isKindOfClass:[DeviceController class]])
        {
            return;
        }
        DeviceController *devCtrl = [[DeviceController alloc] initWithDevice:device];
        [deviceListController.navigationController pushViewController:devCtrl animated:YES];
    };
    
    if ([APP_ID isEqualToString:@"your_app_id"] || APP_ID.length == 0 || [APP_SECRET isEqualToString:@"your_app_secret"] || APP_SECRET.length == 0) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"请替换 GOpenSourceModules/CommonModule/UIConfig.json 中的参数定义为您申请到的机智云 app id、app secret、product key 等" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
    }
    else {
        // 初始化 推送服务
        [GosPushManager initManager:launchOptions];
        if (!PUSH_TYPE) {
            // ios8 注册推送通知
            if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
                UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
                UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            }
#ifndef __IPHONE_10_0
            else {
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
                 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
            }
#endif
            
            //开发者可自行移除此提示
            NSString *tip = NSLocalizedString(@"tip", @"提示");
            NSString *message = NSLocalizedString(@"Only enterprise developers can apply this feature which is not supported by the current version.", @"推送功能仅限于企业开发者使用，目前版本暂不支持推送");
            NSString *confirm = NSLocalizedString(@"OK", @"确定");
            [[[UIAlertView alloc] initWithTitle:tip message:message delegate:nil cancelButtonTitle:confirm otherButtonTitles:nil] show];
        }
        // 初始化 GizWifiSDK
        [GizWifiSDK sharedInstance].delegate = self;
        if ([GosCommon sharedInstance].cloudDomainDict.count > 0) {
            [GizWifiSDK startWithAppID:APP_ID specialProductKeys:nil cloudServiceInfo:[GosCommon sharedInstance].cloudDomainDict];
        } else {
            //设置服务器
            GosCommon *common = [GosCommon sharedInstance];
            [common setApplicationInfo:[common getApplicationInfo]];
        }
    }
    
    [[UINavigationBar appearance] setBackgroundColor:[GosCommon sharedInstance].navigationBarColor];
    [UINavigationBar appearance].barStyle = (UIBarStyle)[GosCommon sharedInstance].statusBarStyle;
    [[UINavigationBar appearance] setBarTintColor:[GosCommon sharedInstance].navigationBarColor];
    [[UINavigationBar appearance] setTintColor:[GosCommon sharedInstance].navigationBarTextColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[GosCommon sharedInstance].navigationBarTextColor}];
    
    return YES;
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString*)eventMessage {
    GIZ_LOG_DEBUG("eventID: %zi, eventMessage: %s", eventID, eventMessage.description);
    
    if (eventType == GizEventSDK && eventID == GIZ_SDK_START_SUCCESS) {
        //清理代理
        [GizWifiSDK sharedInstance].delegate = nil;
        
        // [GosCommon shareInstance].sdk是否启动
        [GizWifiSDK setLogLevel:GizLogPrintAll];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"GosUser" bundle:nil];
        //导航设置代理
        UINavigationController *newViewController = [storyboard instantiateInitialViewController];
        newViewController.view.alpha = 0;
        self.window.rootViewController = newViewController;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        newViewController.view.alpha = 1;
        [UIView commitAnimations];
    } else {
        if (eventID != GIZ_SDK_EXEC_DAEMON_FAILED) {
            //清理代理，弹出提示
            [GizWifiSDK sharedInstance].delegate = nil;
            [[GosCommon sharedInstance] showAlert:[[GosCommon sharedInstance] checkErrorCode:eventID] disappear:YES];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    GIZ_LOG_BIZ("switch_wifi_notify_click", "success", "wifi switch success notify is clicked");
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url absoluteString] hasPrefix:@"tencent"]) {
        return [TencentOAuth HandleOpenURL:url];
    }
    else {
        return [WXApi handleOpenURL:url delegate:self];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([[url absoluteString] hasPrefix:@"tencent"]) {
        return [TencentOAuth HandleOpenURL:url];
    }
    else {
        return  [WXApi handleOpenURL:url delegate:self];
    }
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    [GosCommon sharedInstance].WXApiOnRespHandler(resp);
}

- (void)onReq:(BaseReq *)req {
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // Required,For systems with less than or equal to iOS6
    [GosPushManager handleRemoteNotification:userInfo];
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    NSString *content = [aps valueForKey:@"alert"];
    NSString *title = [userInfo valueForKey:@"title"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:content delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // IOS 7 Support Required
    [self application:application didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [GosPushManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    _isBackground = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    _isBackground = NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
