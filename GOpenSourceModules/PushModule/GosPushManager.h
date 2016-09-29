//
//  GosPushManager.h
//  GOpenSourceAppKit
//
//  Created by Zono on 16/6/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GizWifiSDK/GizWifiSDK.h>

@interface GosPushManager : NSObject

+ (void)initManager:(NSDictionary *)launchOptions;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)handleRemoteNotification:(NSDictionary *)remoteInfo;
+ (void)bindToGDMS;
+ (void)unbindToGDMS:(BOOL)isLogout;
+ (void)didBind:(NSError *)result;
+ (void)didUnbind:(NSError *)result;
@end
