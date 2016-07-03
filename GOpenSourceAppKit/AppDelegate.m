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
#import "DeviceController.h"

#import <TencentOpenAPI/TencentOAuth.h>

#import "GosPushManager.h"

@interface AppDelegate () <GizWifiSDKDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [GosCommon sharedInstance].controlHandler = ^(GizWifiDevice *device, UIViewController *deviceListController) {
        DeviceController *devCtrl = [[DeviceController alloc] initWithDevice:device];
        [deviceListController.navigationController pushViewController:devCtrl animated:YES];
    };
    
    [GizWifiSDK sharedInstance].delegate = self;
    
    // 初始化 GizWifiSDK
    
    [GizWifiSDK startWithAppID:APP_ID];
    [GizWifiSDK setLogLevel:GizLogPrintAll];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    self.window.backgroundColor = [UIColor whiteColor];
    
    // 初始化 推送服务
    [GosPushManager initManager:launchOptions];
    
#if (!defined __JPush) && (!defined __BPush)
    // ios8 注册推送通知
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
#endif

    [[UIApplication sharedApplication] setStatusBarStyle:[GosCommon sharedInstance].statusBarStyle];
    [[UINavigationBar appearance] setBackgroundColor:[GosCommon sharedInstance].navigationBarColor];
    [UINavigationBar appearance].barStyle = UIStatusBarStyleDefault;
    [[UINavigationBar appearance] setBarTintColor:[GosCommon sharedInstance].navigationBarColor];
    [[UINavigationBar appearance] setTintColor:[GosCommon sharedInstance].navigationBarTextColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[GosCommon sharedInstance].navigationBarTextColor}];
    
    // 设置生成设备控制页面的委托
//    [GizDeviceControllerInstance sharedInstance].delegate = self;
    
    return YES;
}

//- (void)deviceListController:(GizDeviceListViewController *)controller device:(GizWifiDevice *)device {
//    DeviceViewController *devVC = [[DeviceViewController alloc] init];
//    devVC.device = device;
//    [controller.navigationController pushViewController:devVC animated:YES];
//}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    GIZ_LOG_BIZ("switch_wifi_notify_click", "success", "wifi switch success notify is clicked");
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString*)eventMessage {
    
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [TencentOAuth HandleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [TencentOAuth HandleOpenURL:url];
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
