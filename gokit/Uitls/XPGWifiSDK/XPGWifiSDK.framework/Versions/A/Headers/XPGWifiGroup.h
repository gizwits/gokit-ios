//
//  XPGWifiGroup.h
//  XPGWifiSDK
//
//  Created by rosefish on 15-2-6.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XPGWifiGroup;

/**
 XPGWifiGroupDelegate是XPGWifiGroup类的委托协议，为APP开发者处理子设备添加、子设备删除、获取子设备列表提供委托函数
 */
@protocol XPGWifiGroupDelegate <NSObject>
@optional

/**
 分组设备列表的回调接口，返回组内的设备列表
 @param group 触发回调的组对象
 @param deviceList 分组设备列表，为 XPGWifiSubDevice 实例数组
 
    {
        @"sdid": @"value", //子设备标识码
        @"did": @"value" //父设备标识码
    }
 
 @param result 0为成功，其他失败
 @see 触发函数：[XPGWifiGroup getDevices]、[XPGWifiGroup addDevice:withSubDevice:]、[XPGWifiGroup removeDevice:withSubDevice:]
 */
- (void)XPGWifiGroup:(XPGWifiGroup *)group didGetDevices:(NSArray *)deviceList result:(int)result;

@end


/**
 XPGWifiGroup类为APP开发者提供中控子设备的分组操作，包括获取组内的设备、往组内添加设备、删除组内的设备等功能
 */
@interface XPGWifiGroup : NSObject

/**
 组标识ID
 */
@property (nonatomic, strong, readonly) NSString *gid;

/**
 组类型（根据产品标识来区别）
 */
@property (nonatomic, strong, readonly) NSString *productKey;

/**
 组名称
 */
@property (nonatomic, strong, readonly) NSString *groupName;

/**
 使用委托获取对应事件。XPGWifiGroup 对应的回调接口在 XPGWifiGroupDelegate 定义，需要用到哪个接口，实现对应的回调即可
 */
@property (nonatomic, assign) id <XPGWifiGroupDelegate> delegate;

/**
 获取组内的设备列表
 @see 对应的回调接口：[XPGWifiGroupDelegate XPGWifiGroup:didGetDevices:result:]
 */
- (void)getDevices;

/**
 往组内添加设备
 @param did 父设备的设备标识
 @param sdid 子设备的设备标识
 @see 对应的回调接口：[XPGWifiGroupDelegate XPGWifiGroup:didGetDevices:result:]
 */
- (void)addDevice:(NSString*)did withSubDevice:(NSString*)sdid;

/**
 从组内删除设备
 @param did 父设备的设备标识
 @param sdid 子设备的设备标识
 @see 对应的回调接口：[XPGWifiGroupDelegate XPGWifiGroup:didGetDevices:result:]
 */
- (void)removeDevice:(NSString*)did withSubDevice:(NSString*)sdid;

@end
