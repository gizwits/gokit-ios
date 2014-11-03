//
//  XPGWifiDevice.h
//  XPGWifiSDK
//
//  Created by xpg on 14-7-8.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XPG_WIFI_GUESTUSER          @"__guest_user"

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

@protocol XPGWifiDeviceDelegate <NSObject>
@optional

/**
 * @brief 设备已连接
 */
- (void)XPGWifiDeviceDidConnected:(XPGWifiDevice *)device;

/**
 * @brief 设备连接失败
 */
- (void)XPGWifiDeviceDidConnectFailed:(XPGWifiDevice *)device;

/**
 * @brief 设备已断开
 */
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device;

/**
 * @brief 从设备获取 passcode 成功
 * @param result：0=成功 否则失败
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didGetPasscode:(int)result;

/**
 * @brief 本地登录
 * @param result：2=获取控制权
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didLogin:(int)result;

/**
 * @brief 云端登录
 * @param result：2=获取控制权
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didLoginWithMQTT:(int)result;

/**
 * @brief 接收数据
 * @param data：格式参考 write 方法
 */
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data;

/**
 * @brief 判断设备是否大循环在线
 * @param isOnline：YES=在线，NO=不在线
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didDeviceIsOnline:(BOOL)isOnline;

/*
 * @brief 设置设备的开关结果
 * @param result：0 成功，其他失败
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didSetSwitcher:(int)result;

/**
 * @brief 更新UI
 */
- (void)XPGWifiDeviceDidUpdateUI:(XPGWifiDevice *)device;

/**
 * @brief 设备推送日志信息
 * @param logInfo 日志信息
 * 键值定义：XPGWifiDeviceLog*Key
 */

- (void)XPGWifiDevice:(XPGWifiDevice *)device didUpdateDeviceLog:(NSDictionary *)logInfo;

/**
 * @brief 获取硬件信息
 * @param hwInfo 硬件信息
 * 键值定义：XPGWifiDeviceHardware*Key
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didQueryHardwareInfo:(NSDictionary *)hwInfo;

/**
 * @brief 警告和错误
 * @param recvInfo
 */
- (void)XPGWifiDevice:(XPGWifiDevice *)device didReceiveAlertsAndFaults:(NSDictionary *)recvInfo;

@end

@interface XPGWifiDevice : NSObject

@property (nonatomic, assign) id <XPGWifiDeviceDelegate>delegate;

/**
 * @brief 判断设备是否合法
 */
- (BOOL)isValidDevice;

/**
 * @brief 判断设备是否相同
 */
- (BOOL)isEqualToDevice:(XPGWifiDevice *)device;

/**
 * Properties
 */
@property (nonatomic, strong, readonly) NSString *macAddress;   //设备的MAC地址
@property (nonatomic, strong, readonly) NSString *did;          //设备的云端身份标识DID
@property (nonatomic, strong, readonly) NSString *passcode;     //用于控制设备的秘钥
@property (nonatomic, strong, readonly) NSString *ipAddress;    //设备的小循环IP地址
@property (nonatomic, strong, readonly) NSString *productKey;   //设备的产品唯一标识符
@property (nonatomic, strong, readonly) NSString *productName;  //设备名称
@property (nonatomic, strong, readonly) NSDictionary *ui;       //IoTDeviceController 界面

@property (nonatomic, assign, readonly) BOOL isConnected;       //是否连接
@property (nonatomic, assign, readonly) BOOL isLAN;             //是否是小循环设备
@property (nonatomic, assign, readonly) BOOL isOnline;          //云端判断设备是否在线

/**
 * @brief 获取硬件信息
 */
- (void)getHardwareInfo;

/**
 * @brief 设置硬件日志参数
 * bit0: error 日志级别的开与关，0 为关，1 为开；
 * bit1: warning 日志级别的开与关，0 为关，1 为开；
 * bit2: info 日志级别的开与关，0 为关，1 为开；
 * bit3: WiFi 模组所有指示灯的总开关，0 为关，1 为开；
 */
- (void)setLogParam:(NSInteger)nLogLevel totalOnOff:(BOOL)totalOnOff;

/**
 * @brief 获取PASSCODE。
 * @note 设备的绑定、控制需要先获取PASSCODE。
 * @note 部分设备需要按下获取密码按钮后，调用此方法才有效
 */
- (BOOL)getPasscodeFromDevice;

/**
 * @brief 设备使用大循环连接
 */
- (BOOL)connectToMQTT;

/**
 * @brief 自动匹配模式连接
 * @note 连接遵循小循环优先原则：
 * 这个设备既支持小循环，又支持大循环，则优先连接小循环
 */
- (BOOL)connect;

/**
 * @brief 断开当前的连接
 */
- (BOOL)disconnect;

/**
 * @brief 登录
 * @param uid：用户id
 * @param token：密码token
 * @note 设备连接后，如果需要绑定或控制，需要使用登录获取权限。
 * 小循环登录，传入的参数均为NULL
 * 大循环登录，传入的参数必须是注册过的合法的用户信息
 */
- (void)login:(NSString *)uid token:(NSString *)token;

/**
 * @brief 本地判断此设备是否绑定
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
 */
- (NSInteger)write:(NSDictionary *)data;

@end
