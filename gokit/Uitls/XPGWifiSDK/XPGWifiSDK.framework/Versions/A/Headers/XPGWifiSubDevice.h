//
//  XPGWifiSubDevice.h
//  XPGWifiSDK
//
//  Created by xpg on 15-2-3.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XPGWifiSDK/XPGWifiDevice.h>

@class XPGWifiSubDevice;

/**
 XPGWifiSubDevice类为APP开发者提供中控子设备的操作函数
 */
@interface XPGWifiSubDevice : XPGWifiDevice

/**
 子设备的身份标识DID
 */
@property (strong, nonatomic, readonly) NSString *subDid;

/**
 子设备的产品类型唯一标识
 */
@property (nonatomic, strong, readonly) NSString *subProductKey;

/**
 子设备的产品类型名称
 */
@property (nonatomic, strong, readonly) NSString *subProductName;

/**
 控制设备
 @param data 控制指令，格式与[XPGWifiDevice write:]相同
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDevice:didReceiveData:result:]
 */
- (void)write:(NSDictionary *)data;

@end