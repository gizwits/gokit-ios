//
//  XPGWifiCentralControlDevice.h
//  XPGWifiSDK
//
//  Created by xpg on 15-2-3.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XPGWifiSDK/XPGWifiDevice.h>

@class XPGWifiCentralControlDevice;

@protocol XPGWifiCentralControlDeviceDelegate <XPGWifiDeviceDelegate>
@optional

/**
 * @brief 回调接口，返回发现子设备设备的结果
 * @param subDeviceList：为 XPGWifiSubDevice* 的集合
 * @param result：0为成功，其他失败
 * @see 触发函数：[XPGWifiCentralControlDevice getSubDevices]
 */
- (void)XPGWifiCentralControlDevice:(XPGWifiCentralControlDevice *)wifiCentralControlDevice
                      didDiscovered:(NSArray *)subDeviceList
                             result:(int)result;

@end

@interface XPGWifiCentralControlDevice : XPGWifiDevice

@property (nonatomic, assign) id <XPGWifiCentralControlDeviceDelegate>delegate;

/**
 * @brief 获取子设备列表，只有设备登录后才能获取到
 * @see 对应的回调接口：[XPGWifiCentralControlDevice XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)getSubDevices;

/**
 * @brief 添加子设备，只有设备登录后才能添加
 * @see 对应的回调接口：[XPGWifiCentralControlDevice XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)addSubDevice;

/**
 * @brief 删除子设备，只有设备登录后才能删除
 * @param subDid：为待删除的子设备id
 * @see 对应的回调接口：[XPGWifiCentralControlDevice XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)deleteSubDevice:(NSString*)subDid;

@end