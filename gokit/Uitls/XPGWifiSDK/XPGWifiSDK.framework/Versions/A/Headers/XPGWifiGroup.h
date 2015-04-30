//
//  XPGWifiGroup.h
//  XPGWifiSDK
//
//  Created by rosefish on 15-2-6.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XPGWifiGroup;
@protocol XPGWifiGroupDelegate <NSObject>
@optional

/**
 * @brief 回调接口，返回组内的设备列表
 * @param deviceList：为设备信息的字典集合
 * [key: sdid value: 子设备标识码]
 * [key: did value: 父设备标识码]
 * @param result：0为成功，其他失败
 * @see 触发函数：[XPGWifiGroup getDevices]、[XPGWifiGroup addDevice:withSubDevice]、[XPGWifiGroup removeDevice:withSubDevice]
 */
- (void)XPGWifiGroup:(XPGWifiGroup *)group didGetDevices:(NSArray *)deviceList result:(int)result;

@end


@interface XPGWifiGroup : NSObject

@property (nonatomic, strong, readonly) NSString *gid;          //组标识DID
@property (nonatomic, strong, readonly) NSString *productKey;   //组类型（根据产品标识来区别）
@property (nonatomic, strong, readonly) NSString *groupName;    //组名称
@property (nonatomic, assign) id <XPGWifiGroupDelegate> delegate;   //组的委托者

/**
 * @brief 获取组内的设备列表
 * @see 对应的回调接口：[XPGWifiGroup XPGWifiGroup:didGetDevices:result:]
 */
- (void)getDevices;

/**
 * @brief 往组内添加设备
 * @param did：父设备的设备标识
 * @param sdid：子设备的设备标识
 * @see 对应的回调接口：[XPGWifiGroup XPGWifiGroup:didGetDevices:result:]
 */
- (void)addDevice:(NSString*)did withSubDevice:(NSString*)sdid;

/**
 * @brief 从组内删除设备
 * @param did：父设备的设备标识
 * @param sdid：子设备的设备标识
 * @see 对应的回调接口：[XPGWifiGroup XPGWifiGroup:didGetDevices:result:]
 */
- (void)removeDevice:(NSString*)did withSubDevice:(NSString*)sdid;

@end
