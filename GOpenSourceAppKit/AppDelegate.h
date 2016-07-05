//
//  AppDelegate.h
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

#warning - please replace your app info

#define APP_ID  @"please_replace_your_app_id"
#define APP_SECRET  @"please_replace_your_app_secret"
#define PRODUCT_KEY @"please_replace_your_device_product_key"

#define TENCENT_APP_ID @"please_replace_your_tencent_app_id"
#define JPUSH_APP_KEY @"please_replace_your_jpush_app_key"
#define BPUSH_API_KEY @"please_replace_your_bpush_api_key"

/******************** 推送开关 ********************/
// 只能同时支持其中一种
//#define __JPush     // 极光推送
//#define __BPush     // 百度推送


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end