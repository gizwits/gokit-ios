//
//  GosPushManager.m
//  GOpenSourceAppKit
//
//  Created by Zono on 16/6/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosPushManager.h"
#import "AppDelegate.h"
#import "GosCommon.h"
#import "JPUSHService.h"
#import "BPush.h"

#ifdef __IPHONE_8_0
#define RNTypeAlert UIUserNotificationTypeAlert
#define RNTypeBadge UIUserNotificationTypeBadge
#define RNTypeSound UIUserNotificationTypeSound
#else
#define RNTypeAlert UIRemoteNotificationTypeAlert
#define RNTypeBadge UIRemoteNotificationTypeBadge
#define RNTypeSound UIRemoteNotificationTypeSound
#endif

@implementation GosPushManager

+ (void)initManager:(NSDictionary *)launchOptions {
#ifdef __JPush
    // 注册通知
    [JPUSHService registerForRemoteNotificationTypes:(RNTypeAlert|RNTypeBadge|RNTypeSound) categories:nil];
    // 初始化 jPush
    [JPUSHService setupWithOption:launchOptions appKey:JPUSH_APP_KEY channel:nil apsForProduction:YES];
    [JPUSHService setBadge:0];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
#endif
#ifdef __BPush
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    [BPush registerChannel:launchOptions apiKey:BPUSH_API_KEY pushMode:BPushModeProduction withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:NO isDebug:NO];
    
    // App 是用户点击推送消息启动
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        NSLog(@"从消息启动:%@",userInfo);
        [BPush handleNotification:userInfo];
    }
#endif
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
#ifdef __JPush
    [JPUSHService registerDeviceToken:deviceToken];
#endif
#ifdef __BPush
    /********** 百度推送 start *********/
    [BPush registerDeviceToken:deviceToken];
    [BPush bindChannelWithCompleteHandler:^(id result, NSError *error) {
        // 需要在绑定成功后进行 settag listtag deletetag unbind 操作否则会失败
        if (result) {
            [BPush setTag:[BPush getChannelId] withCompleteHandler:^(id result, NSError *error) {
                if (result) {
                    NSLog(@"设置Tag成功");
                }
            }];
        }
    }];
    /********** 百度推送 end *********/
#endif
}

+ (void)handleRemoteNotification:(NSDictionary *)remoteInfo {
    [GosPushManager bindToGDMS];
#ifdef __JPush
    [JPUSHService handleRemoteNotification:remoteInfo];
#endif
#ifdef __BPush
    [BPush handleNotification:remoteInfo];
#endif
}

+ (void)bindToGDMS {
    if ([GosCommon sharedInstance].currentLoginStatus == GizLoginUser || [GosCommon sharedInstance].currentLoginStatus == GizLoginAnonymous) {
        NSString *cid = [GosPushManager getCid];
        if (cid == nil) {
            NSLog(@"bindToGDMS cid == nil");
        }
        else {
#ifdef __JPush
            [JPUSHService setAlias:cid callbackSelector:nil object:nil];
            [[GizWifiSDK sharedInstance] channelIDBind:[GosCommon sharedInstance].token channelID:cid pushType:GizPushJiGuang];
            NSLog(@"[GosCommon sharedInstance].token & [JPUSHService registrationID]: %@, %@", [GosCommon sharedInstance].token, cid);
#endif
#ifdef __BPush
            [[GizWifiSDK sharedInstance] channelIDBind:[GosCommon sharedInstance].token channelID:cid pushType:GizPushBaiDu];
            NSLog(@"[GosCommon sharedInstance].token & [BPush getChannelId]: %@, %@", [GosCommon sharedInstance].token, cid);
#endif
        }
    }
}

+ (void)unbindToGDMS {
    if ([GosCommon sharedInstance].currentLoginStatus == GizLoginUser || [GosCommon sharedInstance].currentLoginStatus == GizLoginAnonymous) {
        NSString *cid = [GosPushManager getCid];
        if (cid == nil) {
            NSLog(@"unbindToGDMS cid == nil");
        }
        else {
            [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:cid];
        }
    }
}

+ (void)didBind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didBind cid == nil");
    }
    NSString *info = [NSString stringWithFormat:@"%@\n%@ - %@\n%@", NSLocalizedString(@"channelID Bind", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"], cid];
    if (result.code != GIZ_SDK_SUCCESS) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
    NSLog(@"didBind: %@", info);
}


+ (void)didUnbind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didUnbind cid == nil");
    }
    NSString *info = [NSString stringWithFormat:@"%@\n%@ - %@\n%@", NSLocalizedString(@"channelID UnBind", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"], cid];
    if (result.code != GIZ_SDK_SUCCESS) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
    NSLog(@"didUnbind: %@", info);
}

+ (NSString *)getCid {
    NSString* cid = nil;
    for (int i = 0; i < 10; i++) {
#ifdef __JPush
        cid = [JPUSHService registrationID];
#endif
#ifdef __BPush
        cid = [BPush getChannelId];
#endif
        if (cid && cid.length > 0) {
            return cid;
        }
    }
    return nil;
}

@end
