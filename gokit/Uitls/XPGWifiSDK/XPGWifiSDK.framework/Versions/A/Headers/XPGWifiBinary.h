//
//  XPGWifiBinary.h
//  XPGWifiSDK
//
//  Created by xpg on 14-9-17.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 XPGWifiBinary类为APP开发者提供设备控制命令中的二进制数据与字符串的转换方法
 */
@interface XPGWifiBinary : NSObject

/**
 将字符串解码二进制
 @param str 要转换为二进制数据的字符串
 @return 转换后的二进制数据
 @note 设备上报透传数据（二进制）时，SDK会把收到的透传数据先转换为字符串上报给APP。此时APP需要还原成二进制数据才能使用
 */
+ (NSData *)decode:(NSString *)str;

/**
 将二进制编码为字符串
 @param data 要转换为字符串的二进制数据
 @return 转换后的字符串
 @note 通常APP使用扩展类型数据点发送命令时，需要先将要发送的扩展数据（二进制）转换成字符串，再按照write中约定的json格式下发到设备上
 */
+ (NSString *)encode:(NSData *)data;

@end
