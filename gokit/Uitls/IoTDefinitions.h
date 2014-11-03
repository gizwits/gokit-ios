//
//  IoTDefinitions.h
//  WiFiDemo
//
//  Created by xpg on 14-6-5.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#ifndef WiFiDemo_ioTDefinitions_h
#define WiFiDemo_ioTDefinitions_h

#import "IoTAppDelegate.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

/**
 * @brief Common Definitions
 */
#define AppDelegate ((IoTAppDelegate *)[UIApplication sharedApplication].delegate)

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define isPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define sysVer [[[UIDevice currentDevice] systemVersion] floatValue]

#define RACDispose(x) [x dispose];x = nil;

#endif
