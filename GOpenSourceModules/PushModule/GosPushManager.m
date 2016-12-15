//
//  GosPushManager.m
//  GOpenSourceAppKit
//
//  Created by Zono on 16/6/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//
// @note 推送功能仅限于企业开发者使用，目前版本暂不支持推送

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
    switch (PUSH_TYPE) {
        case 1:
        {
            if ([JPUSH_APP_KEY isEqualToString:@"your_jpush_app_key"] || JPUSH_APP_KEY.length == 0) {
                [[[UIAlertView alloc] initWithTitle:nil message:@"请替换 GOpenSourceModules/CommonModule/UIConfig.json 中的参数定义为您申请到的极光推送 app id" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                return;
            }
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
            }
#ifndef __IPHONE_10_0
            else {
                //categories 必须为nil
                [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                  UIRemoteNotificationTypeSound |
                                                                UIRemoteNotificationTypeAlert)
                                                      categories:nil];
            }
#endif
        }
            break;
        case 2:
        {
            if ([BPUSH_API_KEY isEqualToString:@"your_bpush_app_key"] || BPUSH_API_KEY.length == 0) {
                [[[UIAlertView alloc] initWithTitle:nil message:@"请替换 GOpenSourceModules/CommonModule/UIConfig.json 中的参数定义为您申请到的百度推送 app id" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
                return;
            }
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                UIUserNotificationType myTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
                
                UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:myTypes categories:nil];
                [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            }
#ifndef __IPHONE_10_0
            else {
                UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert;
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
            }
#endif
            [BPush registerChannel:launchOptions apiKey:BPUSH_API_KEY pushMode:BPushModeProduction withFirstAction:nil withSecondAction:nil withCategory:nil useBehaviorTextInput:NO isDebug:NO];
            
            // App 是用户点击推送消息启动
            NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (userInfo) {
                NSLog(@"从消息启动:%@",userInfo);
                [BPush handleNotification:userInfo];
            }
        }
            break;
        default:
            break;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    switch (PUSH_TYPE) {
        case 1:
        {
            [JPUSHService registerDeviceToken:deviceToken];
        }
            break;
        case 2:
        {
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
        }
            break;
        default:
            break;
    }
}

+ (void)handleRemoteNotification:(NSDictionary *)remoteInfo {
    switch (PUSH_TYPE) {
        case 1:
        {
            [JPUSHService handleRemoteNotification:remoteInfo];
        }
            break;
        case 2:
        {
            [BPush handleNotification:remoteInfo];
        }
            break;
        default:
            break;
    }
}

+ (void)bindToGDMS {
    if (!PUSH_TYPE) return;
    if ([GosCommon sharedInstance].token && [GosCommon sharedInstance].token.length > 0) {
        NSString *cid = [GosPushManager getCid];
        if (cid == nil) {
            NSLog(@"bindToGDMS cid == nil");
        }
        else {
            switch (PUSH_TYPE) {
                case 1:
                {
                    NSLog(@"绑定极光推送cid：%@", cid);
                    [[GizWifiSDK sharedInstance] channelIDBind:[GosCommon sharedInstance].token channelID:cid alias:nil pushType:GizPushJiGuang];
                    NSLog(@"[GosCommon sharedInstance].token & [JPUSHService registrationID]: %@", [GosCommon sharedInstance].token);
                }
                    break;
                case 2:
                {
                    NSLog(@"绑定百度推送cid：%@", cid);
                    [[GizWifiSDK sharedInstance] channelIDBind:[GosCommon sharedInstance].token channelID:cid alias:nil pushType:GizPushBaiDu];
                    NSLog(@"[GosCommon sharedInstance].token & [BPush getChannelId]: %@", [GosCommon sharedInstance].token);
                }
                    break;
                default:
                    break;
            }
        }
    }
}

+ (void)unbindToGDMS:(BOOL)isLogout {
    if ([GosCommon sharedInstance].token && [GosCommon sharedInstance].token.length > 0) {
        NSString *jpushCID = [[NSUserDefaults standardUserDefaults] objectForKey:@"JPushCID"];
        NSString *bpushCID = [[NSUserDefaults standardUserDefaults] objectForKey:@"BPushCID"];
        if (isLogout) {
            if (jpushCID && jpushCID.length > 0) {
                NSLog(@"解绑极光推送cid：%@", jpushCID);
                [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:jpushCID];
            }
            if (bpushCID && bpushCID.length > 0) {
                NSLog(@"解绑百度推送cid：%@", bpushCID);
                [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:bpushCID];
            }
        }
        else {
            switch (PUSH_TYPE) {
                case 0:
                    if (jpushCID && jpushCID.length > 0) {
                        NSLog(@"解绑极光推送cid：%@", jpushCID);
                        [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:jpushCID];
                    }
                    if (bpushCID && bpushCID.length > 0) {
                        NSLog(@"解绑百度推送cid：%@", bpushCID);
                        [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:bpushCID];
                    }
                    break;
                case 1:
                    if (bpushCID && bpushCID.length > 0) {
                        NSLog(@"解绑百度推送cid：%@", bpushCID);
                        [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:bpushCID];
                    }
                    break;
                case 2:
                    if (jpushCID && jpushCID.length > 0) {
                        NSLog(@"解绑极光推送cid：%@", jpushCID);
                        [[GizWifiSDK sharedInstance] channelIDUnBind:[GosCommon sharedInstance].token channelID:jpushCID];
                    }
                    break;
                    
                default:
                    break;
            }
        }
    }
}

+ (void)didBind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didBind cid == nil");
    }
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        NSLog(@"绑定失败 didBind: %@", info);
        [[GosCommon sharedInstance] showAlert:info disappear:YES];
    }
    else {
        if (PUSH_TYPE == 1) {
            [[NSUserDefaults standardUserDefaults] setObject:cid forKey:@"JPushCID"];
            NSLog(@"JPushCID 缓存成功: %@", cid);
        }
        else if (PUSH_TYPE == 2) {
            [[NSUserDefaults standardUserDefaults] setObject:cid forKey:@"BPushCID"];
            NSLog(@"BPushCID 缓存成功: %@", cid);
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"绑定成功");
    }
}


+ (void)didUnbind:(NSError *)result {
    NSString *cid = [GosPushManager getCid];
    if (cid == nil) {
        NSLog(@"didUnbind cid == nil");
    }
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [[GosCommon sharedInstance] showAlert:info disappear:YES];
        NSLog(@"解绑失败 didUnbind: %@", info);
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JPushCID"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BPushCID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"解绑成功，缓存清除成功");
    }
}

+ (NSString *)getCid {
    NSString* cid = nil;
    for (int i = 0; i < 10; i++) {
        switch (PUSH_TYPE) {
            case 1:
            {
                cid = [JPUSHService registrationID];
            }
                break;
            case 2:
            {
                cid = [BPush getChannelId];
            }
                break;
            default:
                break;
        }
        if (cid && cid.length > 0) {
            return cid;
        }
        else {
            NSLog(@"获取cid失败");
        }
    }
    return nil;
}

@end
