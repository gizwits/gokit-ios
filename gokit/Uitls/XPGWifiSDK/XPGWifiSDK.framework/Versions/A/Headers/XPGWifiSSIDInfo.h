//
//  IoTSSIDInfo.h
//  XPGWifiSSIDInfo
//
//  Created by xpg on 14-7-1.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XPGWifiSSIDInfo : NSObject

/**
 * @brief 获取当前连接的热点信息
 * @result @{@"SSID": [value]}
 */
+ (NSDictionary *)SSIDInfo;

/**
 * @brief 判断是否是软AP模式
 */
+ (BOOL)isSoftAPMode;

/**
 * @brief 判断是否已连上Wifi
 */
+ (BOOL)isConnectedWifi;

@end
