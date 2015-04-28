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

@interface XPGWifiSubDevice : XPGWifiDevice

@property (strong, nonatomic, readonly) NSString *subDid;           //子设备id
@property (nonatomic, strong, readonly) NSString *subProductKey;    //子设备的产品唯一标识符
@property (nonatomic, strong, readonly) NSString *subProductName;   //子设备名称

- (NSInteger)write:(NSDictionary *)data;

@end