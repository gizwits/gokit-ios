//
//  XPGWifiSSID.h
//  WiFiDemo
//
//  Created by xpg on 14-7-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XPGWifiSSID : NSObject

@property (nonatomic, strong, readonly) NSString *name;     //SSID名
@property (nonatomic, assign, readonly) NSInteger rssi;     //信号强度0-100

@end
