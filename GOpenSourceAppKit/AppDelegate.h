//
//  AppDelegate.h
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

#define APP_ID  [GosCommon sharedInstance].appID
#define APP_SECRET  [GosCommon sharedInstance].appSecret

#define TENCENT_APP_ID [GosCommon sharedInstance].tencentAppID

#define WECHAT_APP_ID [GosCommon sharedInstance].wechatAppID
#define WECHAT_APP_SECRET [GosCommon sharedInstance].wechatAppSecret

#define PUSH_TYPE [GosCommon sharedInstance].pushType
#define JPUSH_APP_KEY [GosCommon sharedInstance].jpushAppKey
#define BPUSH_API_KEY [GosCommon sharedInstance].bpushAppKey

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic, readonly) BOOL isBackground;

@end

