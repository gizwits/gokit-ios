//
//  XPGWifiBinary.h
//  XPGWifiSDK
//
//  Created by xpg on 14-9-17.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @class XPGWifiBinary
 * @note 用于 P0 部分二进制与字符串的互转
 */
@interface XPGWifiBinary : NSObject

/**
 * @brief 将字符串解码二进制
 */
+ (NSData *)decode:(NSString *)str;

/**
 * @brief 将二进制编码为字符串
 */
+ (NSString *)encode:(NSData *)data;

@end
