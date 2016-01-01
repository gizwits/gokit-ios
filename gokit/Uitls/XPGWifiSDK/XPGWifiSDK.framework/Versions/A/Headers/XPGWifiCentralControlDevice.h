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

/**
 XPGWifiCentralControlDeviceDelegate是XPGWifiCentralControlDevice类的委托协议，为APP开发者处理中控子设备的添加、删除、获取提供委托函数
 */
@protocol XPGWifiCentralControlDeviceDelegate <XPGWifiDeviceDelegate>
@optional

/**
 子设备列表的回调接口，返回发现子设备设备的结果
 @param wifiCentralControlDevice 返回触发回调的中控设备实例
 @param subDeviceList 为 XPGWifiSubDevice* 实例数组
 @param result 0为成功，其他失败
 @see 触发函数：[XPGWifiCentralControlDevice getSubDevices]
 */
- (void)XPGWifiCentralControlDevice:(XPGWifiCentralControlDevice *)wifiCentralControlDevice
                      didDiscovered:(NSArray *)subDeviceList
                             result:(int)result;

@end

/**
 XPGWifiCentralControlDevice类为APP开发者提供中控设备的操作函数，如添加子设备、删除子设备、获取子设备列表
 */
@interface XPGWifiCentralControlDevice : XPGWifiDevice

/**
 使用委托获取对应事件。XPGWifiCentralControlDevice 对应的回调接口在 XPGWifiDeviceDelegate 定义，需要用到哪个接口，实现对应的回调即可
 */
@property (nonatomic, assign) id <XPGWifiCentralControlDeviceDelegate>delegate;

/**
 获取子设备列表，只有中控设备登录后才能获取到
 @see 对应的回调接口：[XPGWifiCentralControlDeviceDelegate XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)getSubDevices;

/**
 添加子设备，只有中控设备登录后才能添加
 @see 对应的回调接口：[XPGWifiCentralControlDeviceDelegate XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)addSubDevice;

/**
 删除子设备，只有中控设备登录后才能删除
 @param subDid 为待删除的子设备id
 @see 对应的回调接口：[XPGWifiCentralControlDeviceDelegate XPGWifiCentralControlDevice:didDiscovered:result:]
 */
- (void)deleteSubDevice:(NSString*)subDid;

@end