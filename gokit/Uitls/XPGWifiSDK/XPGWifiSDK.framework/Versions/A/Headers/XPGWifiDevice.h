//
//  XPGWifiDevice.h
//  XPGWifiSDK
//
//  Created by xpg on 14-7-8.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XPG_WIFI_GUESTUSER          @"__guest_user"

//#define __INTERNAL_TESTING_API__
#ifndef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
#define __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
#endif

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

typedef enum
{
    XPGWifiDeviceTypeNormal = 0,
    XPGWifiDeviceTypeCenterControl,
    XPGWifiDeviceTypeSub,
} XPGWifiDeviceType;

@protocol XPGWifiDeviceDelegate <NSObject>
@optional

/**
 * @brief 回调接口，触发时机为设备主动或被动断开以及异常断开
 * @see 触发函数：[XPGWifiDevice disconnect]
 */
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device;

/**
 * @brief 回调接口，返回设备登录结果
 * @param result：2=获取控制权
 * @see 触发函数：[XPGWifiDevice login:token:]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didLogin:(int)result;

/**
 * @brief 回调接口，返回设备上发的数据内容，包括设备控制命令的应答、设备运行状态的上报、设备报警、设备故障信息
 * @param data：[key: data value: 数据内容，格式见write方法说明]
                [key: alerts value: NSArray 报警列表]
                [key: faults value: NSArray 故障列表]
 * @see 触发函数：[XPGWifiDevice write:]
 */
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result;

/**
 * @brief 回调接口，当设备在线状态发生变化时会被触发
 * @param isOnline：YES=在线，NO=不在线
 * @note 触发条件：设备离线
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didDeviceIsOnline:(BOOL)isOnline;

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/**
 * @brief 回调接口，返回设置设备调试模式的结果
 * @param result：0 成功，其他失败
 * @see 触发函数：[XPGWifiSDK setSwitchService:]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didSetSwitcher:(int)result;
#endif

/**
 * @brief 回调接口，设备推送日志信息时会被触发
 * @param logInfo 日志信息
 * 键值定义：XPGWifiDeviceLog*Key
 * @note 触发条件：设备登录后主动上报
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didUpdateDeviceLog:(NSDictionary *)logInfo;

/**
 * @brief 回调接口，返回获取到的硬件信息
 * @param hwInfo 硬件信息
 * 键值定义：XPGWifiDeviceHardware*Key
 * @see 触发函数：[XPGWifiDevice getHardwareInfo]
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didQueryHardwareInfo:(NSDictionary *)hwInfo;

#ifdef __INTERNAL_TESTING_API__
/**
 * @brief 从设备获取 passcode 成功
 * @param result：0=成功 否则失败
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didGetPasscode:(int)result;

/**
 * @brief 获取模块日志
 * @param wifilog：wifi模块日志
 * @see 触发函数：设备绑定或登录
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didShowWifiLog:(NSString *)wifilog;

/**
 * @brief 显示接收到的二进制数据
 * @param data：接收到的二进制数据
 * @see 触发函数：设备操作或设备上报
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didShowRevieveData:(NSString *)data;
#endif

@end

@interface XPGWifiDevice : NSObject

@property (nonatomic, assign) id <XPGWifiDeviceDelegate>delegate;

/**
 * Properties
 */
@property (nonatomic, strong, readonly) NSString *macAddress;   //设备的MAC地址
@property (nonatomic, strong, readonly) NSString *did;          //设备的云端身份标识DID
@property (nonatomic, strong, readonly) NSString *passcode;     //用于控制设备的秘钥
@property (nonatomic, strong, readonly) NSString *ipAddress;    //设备的小循环IP地址
@property (nonatomic, strong, readonly) NSString *productKey;   //设备的产品唯一标识符
@property (nonatomic, strong, readonly) NSString *productName;  //设备名称
@property (nonatomic, strong, readonly) NSDictionary *ui;       //IoTDeviceController QuickDialog 界面字典
@property (nonatomic, strong, readonly) NSString *remark;       //设备别名

@property (nonatomic, assign, readonly) BOOL isConnected;       //是否连接
@property (nonatomic, assign, readonly) BOOL isLAN;             //是否是小循环设备
@property (nonatomic, assign, readonly) BOOL isOnline;          //云端判断设备是否在线
@property (nonatomic, assign, readonly) BOOL isDisabled;        //云端判断设备是否已注销

@property (nonatomic, assign, readonly) XPGWifiDeviceType type; //设备类型

/**
 * @brief 获取硬件信息。只有设备登录后才能获取到
 * @see 对应的回调接口：[XPGWifiDevice XPGWifiDevice:didQueryHardwareInfo:]
 */
- (void)getHardwareInfo;

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/**
 * @brief 设置硬件日志参数
 * bit0: error 日志级别的开与关，0 为关，1 为开；
 * bit1: warning 日志级别的开与关，0 为关，1 为开；
 * bit2: info 日志级别的开与关，0 为关，1 为开；
 * bit3: WiFi 模组所有指示灯的总开关，0 为关，1 为开；
 * @see 对应的回调接口：[XPGWifiDevice XPGWifiDevice:didUpdateDeviceLog:]
 */
- (void)setLogParam:(NSInteger)nLogLevel switchAll:(BOOL)bSwitchAll;
#endif

/**
 * @brief 断开当前的设备连接
 * @see 对应的回调接口：[XPGWifiDevice XPGWifiDeviceDidDisconnected:]
 */
- (BOOL)disconnect;

#ifdef __INTERNAL_TESTING_API__
/**
 * @brief 获取设备passcode
 */
- (void)getPasscodeFromDevice;
#endif

/**
 * @brief 设备登录
 * @param uid：用户id
 * @param token：密码token
 * @note 设备连接后，如果需要绑定或控制，需要使用登录获取权限。
 * 小循环登录，传入的参数均为NULL
 * 大循环登录，传入的参数必须是注册过的合法的用户信息
 * @see 对应的回调接口：[XPGWifiDevice XPGWifiDevice:didLogin:]
 */
- (void)login:(NSString *)uid token:(NSString *)token;

/**
 * @brief 判断此设备是否绑定
 * @param uid：用户id（长度限定255字节，下同）
 */
- (BOOL)isBind:(NSString *)uid;

/**
 * @brief 控制设备
 * @param data：控制指令
 * @note 输入的内容需参考 WifiDemo 项目中的“协议解析.json”
 * 基础格式：
 * @{
 *     [command] : [value],
 *     ......
 * }
 *
 * =================== 旧版协议格式(v3.1)： ===================
 * @{
 *     [serviceName] : @{
 *         [key]: [value],
 *         ......
 *     }
 * }
 * 动态数据对应协议解析如下：
 * {
 *      "devices": [
 *      {
 *          "services": [
 *          {
 *              "name": [serviceName],//这里对应上面的[serviceName]值
 *              "characteristics": {
 *              "request": [
 *              {
 *                  "name": [key],//这里对应上面的[key]值
 *                  "type": "word"
 *              }
 *              ]
 *              }
 *          }
 *          ]
 *      }
 *      ]
 * }
 *
 * =================== 新版协议格式(v3.2)： ===================
 * @{
 *     @"cmd": 3,
 *     @"qos": 1,
 *     @"seq": 1234,
 *     [entityName/serviceName] : @{
 *         [attributeName] : [attributeValue],
 *         ......
 *     }
 *     ......
 * }
 * 固定属性介绍：
 * cmd：不填默认=3，可以是1、3、5
 * 1. 手机请求读取设备的属性(手机->设备主控MCU)
 * 3. 手机更改设备的属性(或手机控制设备)-QoS=0(手机->设备主控MCU)
 * 5. 设备主控MCU推送状态到手机-QoS=0(状态推送/Pushnotification)(设备主控MCU->手机)
 *
 * qos：指定的请求是否有回复。默认qos=0，发送请求后不回复
 * 当qos=1时，就必须传seq（自增索引）值。seq的范围是0-65535。
 *
 * 动态数据对应协议解析如下：
 * {
 *      "devices": [
 *      {
 *          "services": [
 *          {
 *              "name": [serviceName],//这里对应上面的[serviceName]值
 *              "characteristics": {
 *              "write": [
 *              {
 *                  "QoS": 0,//这里如果定义了，则自动填写，手动填写无效
 *                  “attributes”: [
 *                      "default.onOff",//这里对应上面的[attribute*]值
 *                      ......
 *                  ]
 *              }
 *              ]
 *              }
 *          }
 *          ],
 *          "entities": [
 *              "name": [entityName],//这里对应上面的[entityName]值
 *              "attributes":[
 *              {
 *                  "name": [attributeName],//这里对应上面的[attributeName]值
 *                  ......
 *              }
 *              ]
 *          ]
 *      }
 *      ]
 * }
 *
 * =================== 新版协议格式(v4.0)： ===================
 * http://site.gizwits.com/document/m2m/datapoint/
 * @see 对应的回调接口：[XPGWifiDevice XPGWifiDevice:didReceiveData:result:]
 */
- (NSInteger)write:(NSDictionary *)data;

@end
