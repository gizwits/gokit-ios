//
//  XPGWifiDevice.h
//  XPGWifiSDK
//
//  Created by xpg on 14-7-8.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define __INTERNAL_TESTING_API__
//#ifndef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
//#define __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
//#endif

@class XPGWifiDevice;

extern NSString *XPGWifiDeviceLogLevelKey;
extern NSString *XPGWifiDeviceLogTagKey;
extern NSString *XPGWifiDeviceLogSourceKey;
extern NSString *XPGWifiDeviceLogContentKey;

extern NSString *XPGWifiDeviceHardwareWifiHardVerKey;
extern NSString *XPGWifiDeviceHardwareWifiSoftVerKey;
extern NSString *XPGWifiDeviceHardwareMCUHardVerKey;
extern NSString *XPGWifiDeviceHardwareMCUSoftVerKey;
extern NSString *XPGWifiDeviceHardwareFirmwareIdKey;
extern NSString *XPGWifiDeviceHardwareFirmwareVerKey;
extern NSString *XPGWifiDeviceHardwareProductKey;

/**
 XPGWifiDeviceType枚举，描述SDK支持的设备分类
 */
typedef NS_ENUM (NSInteger, XPGWifiDeviceType)
{
    /**
     普通设备
     */
    XPGWifiDeviceTypeNormal = 0,
    
    /**
     中控设备
     */
    XPGWifiDeviceTypeCenterControl,
};

/**
 XPGWifiDeviceDelegate是XPGWifiDevice类的委托协议，为APP开发者处理设备登录、设备控制、设备在线状态提供委托函数
 */
@protocol XPGWifiDeviceDelegate <NSObject>
@optional

/**
 设备断开连接的回调接口，返回设备断开连接的接口。当设备主动或被动断开以及异常断开时，也会触发此接口的回调
 @param device 返回触发回调的设备实例
 @see 触发函数：[XPGWifiDevice disconnect]
 */
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device DEPRECATED_ATTRIBUTE;

/**
 设备断开连接的回调接口，返回设备断开连接的接口。当设备主动或被动断开以及异常断开时，也会触发此接口的回调
 @param device 返回触发回调的设备实例
 @param result 设备断开成功或失败
 @see 触发函数：[XPGWifiDevice disconnect]
 */
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device result:(int)result;

/**
 设备登录的回调接口，返回设备登录结果
 @param device 返回触发回调的设备实例
 @param result 设备登录成功或失败
 @see 枚举XPGWifiLoginErrorCode
 @see 触发函数：[XPGWifiDevice login:token:]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didLogin:(int)result;

/**
 设备状态变化的回调接口，返回设备上报的数据内容，包括设备控制命令的应答、设备运行状态的上报、设备报警、设备故障信息
 @param device 返回触发回调的设备实例
 @param result 回调成功或失败
 @param data 设备上报的数据内容
 @note 代码示例
 
    {
        "data": "value", //字符串类型，上报的数据内容
        "alerts": "value", //NSArray类型，报警列表
        "faults": "value", //NSArray类型，故障列表
        "binary": "value", //NSData类型，二进制透传数据
    }
 
 @see 触发函数：[XPGWifiDevice write:]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result;

/**
 设备在线状态变化的回调接口，当设备在线状态发生变化时会被触发
 @param device 触发回调的设备实例
 @param isOnline YES=在线，NO=不在线
 @note 触发条件：设备在线状态变化
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didDeviceIsOnline:(BOOL)isOnline;

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/*
 回调接口，返回设置设备调试模式的结果
 @param result：0 成功，其他失败
 @see 触发函数：[XPGWifiSDK setSwitchService:]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didSetSwitcher:(int)result;
#endif

/**
 设备日志上报的回调接口，设备推送日志信息时会被触发
 @param device 触发回调的设备实例
 @param logInfo 日志信息
 @note 触发条件：设备登录后主动上报
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didUpdateDeviceLog:(NSDictionary *)logInfo;

/**
 获取设备硬件信息的回调接口，需要在局域网与设备建立连接后获取。返回获取到的硬件信息
 @param device 触发回调的设备实例
 @param hwInfo 硬件信息
 
     @{
         "XPGWifiDeviceHardwareWifiHardVerKey": "value",
         "XPGWifiDeviceHardwareWifiSoftVerKey": "value",
         "XPGWifiDeviceHardwareMCUHardVerKey": "value",
         "XPGWifiDeviceHardwareMCUSoftVerKey": "value",
         "XPGWifiDeviceHardwareFirmwareIdKey": "value",
         "XPGWifiDeviceHardwareFirmwareVerKey": "value",
         "XPGWifiDeviceHardwareProductKey": "value"
     }
 
 @see 触发函数：[XPGWifiDevice getHardwareInfo]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didQueryHardwareInfo:(NSDictionary *)hwInfo;

#ifdef __INTERNAL_TESTING_API__
/*
 从设备获取 passcode 成功
 @param result 0=成功 否则失败
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didGetPasscode:(int)result;

/*
 获取模块日志
 @param wifilog wifi模块日志
 @see 触发函数 设备绑定或登录
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didShowWifiLog:(NSString *)wifilog;

/*
 显示接收到的二进制数据
 @param data 接收到的二进制数据
 @see 触发函数：设备操作或设备上报
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didShowRevieveData:(NSString *)data;
#endif

@end

/**
 XPGWifiDevice类为APP开发者提供设备登录、设备控制等函数
 */
@interface XPGWifiDevice : NSObject

/**
 使用委托获取对应事件。XPGWifiDevice 对应的回调接口在 XPGWifiDeviceDelegate 定义，需要用到哪个接口，实现对应的回调即可
 */
@property (nonatomic, assign) id <XPGWifiDeviceDelegate>delegate;

/**
 设备的MAC地址
 */
@property (nonatomic, strong, readonly) NSString *macAddress;

/**
 设备的云端身份标识DID
 */
@property (nonatomic, strong, readonly) NSString *did;

/**
 用于控制设备的秘钥
 */
@property (nonatomic, strong, readonly) NSString *passcode;

/**
 设备的小循环IP地址
 */
@property (nonatomic, strong, readonly) NSString *ipAddress;

/**
 设备的产品类型唯一标识
 */
@property (nonatomic, strong, readonly) NSString *productKey;

/**
 设备的产品类型名称
 */
@property (nonatomic, strong, readonly) NSString *productName;

/**
 设备别名
 */
@property (nonatomic, strong, readonly) NSString *remark;

/**
 设备是否已登录
 */
@property (nonatomic, assign, readonly) BOOL isConnected;

/**
 设备是否是小循环
 */
@property (nonatomic, assign, readonly) BOOL isLAN;

/**
 设备是否在线
 */
@property (nonatomic, assign, readonly) BOOL isOnline;

/**
 设备是否已注销
 */
@property (nonatomic, assign, readonly) BOOL isDisabled;

/**
 设备分类
 */
@property (nonatomic, assign, readonly) XPGWifiDeviceType type;

/**
 获取硬件信息。只有设备登录后才能获取到
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDevice:didQueryHardwareInfo:]
 */
- (void)getHardwareInfo;

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/*
 设置硬件日志参数
 @param nLogLevel 设备日志参数
 
     bit0: error 日志级别的开与关，0 为关，1 为开；
     bit1: warning 日志级别的开与关，0 为关，1 为开；
     bit2: info 日志级别的开与关，0 为关，1 为开；
     bit3: WiFi 模组所有指示灯的总开关，0 为关，1 为开；
 
 @param bSwitchAll LED总开关
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDevice:didUpdateDeviceLog:]
 */
- (void)setLogParam:(NSInteger)nLogLevel switchAll:(BOOL)bSwitchAll;
#endif

/**
 断开当前的设备连接
 @return 是否成功断开连接
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDeviceDidDisconnected:]
 */
- (void)disconnect;

#ifdef __INTERNAL_TESTING_API__
/*
 获取设备passcode
 */
- (void)getPasscodeFromDevice;
#endif

/**
 设备登录
 @param uid 用户id
 @param token 用户token
 @note 设备绑定后，要先使用登录获取权限，才能控制设备。小循环设备登录时，传入的参数均为nil，大循环设备登录，传入的参数必须是注册过的合法的用户信息
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDevice:didLogin:]
 */
- (void)login:(NSString *)uid token:(NSString *)token;

/**
 判断此设备是否已绑定
 @param uid 用户id
 @return 设备是否已经绑定
 */
- (BOOL)isBind:(NSString *)uid;

/**
 控制设备
 @param data 控制指令。输入的内容需参考 WifiDemo 项目中的“协议解析.json”
 
 基础格式：
 
    @{
        [command] : [value],
        ......
    }
 
 =================== 旧版协议格式(v3.1)： ===================
 
    @{
        [serviceName] : {
            [key]: [value],
            ......
        }
    }
 
 动态数据对应协议解析如下：
 
     @{
          "devices": [{
              "services": [{
                  "name": [serviceName],//这里对应上面的[serviceName]值
                  "characteristics": {
                      "request": [{
                          "name": [key],//这里对应上面的[key]值
                          "type": "word"
                      }]
                  }
              }]
          }]
     }
 
 =================== 新版协议格式(v3.2)： ===================
 
     @{
         "cmd": 3,
         "qos": 1,
         "seq": 1234,
         [entityName/serviceName] : {
             [attributeName] : [attributeValue],
             ......
         }
         ......
     }
 
 固定属性介绍：
 
 cmd：不填默认=3，可以是1、3、5
 
 =1 手机请求读取设备的属性(手机->设备主控MCU)
 
 =3 手机更改设备的属性(或手机控制设备)-QoS=0(手机->设备主控MCU)
 
 =5 设备主控MCU推送状态到手机-QoS=0(状态推送/Pushnotification)(设备主控MCU->手机)
 
 
 qos：指定的请求是否有回复。默认qos=0，发送请求后不回复
 
 当qos=1时，就必须传seq（自增索引）值。seq的范围是0-65535。

 动态数据对应协议解析如下：
 
     @{
          "devices": [{
              "services": [{
                  "name": [serviceName],//这里对应上面的[serviceName]值
                  "characteristics": {
                      "write": [{
                          "QoS": 0,//这里如果定义了，则自动填写，手动填写无效
                          “attributes”: [
                              "default.onOff",//这里对应上面的[attribute*]值
                              ......
                          ]
                      }]
                  }
              }],
              "entities": [
                  "name": [entityName],//这里对应上面的[entityName]值
                  "attributes":[{
                      "name": [attributeName],//这里对应上面的[attributeName]值
                      ......
                  }]
              ]
          }]
     }

 =================== 新版协议格式(v4.0)： ===================
 
 http://site.gizwits.com/zh-cn/document/m2m/i_02_datapoint/

 =================== 无格式的数据透传： ======================
 
 当设备没有在云端定义数据点时，可通过数据透传方式向设备发送数据。该数据应先转换为base64字符串后，再按如下方式写入：
 
    @{
        "binary" : "xxxxxxxxxxxx"
    }
 
 @see 对应的回调接口：[XPGWifiDeviceDelegate XPGWifiDevice:didReceiveData:result:]
 */
- (void)write:(NSDictionary *)data;

@end
