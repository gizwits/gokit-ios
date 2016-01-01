//
//  XPGWifiSSID.h
//  WiFiDemo
//
//  Created by xpg on 14-7-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 XPGWifiSSID类为APP开发者提供获取设备在SoftAP模式下能搜索出的wifi信息
 */
@interface XPGWifiSSID : NSObject

/**
 wifi名字
 */
@property (nonatomic, strong, readonly) NSString *name;     //SSID名

/**
 wifi信号强弱
 */
@property (nonatomic, assign, readonly) NSInteger rssi;     //信号强度0-100

@end
