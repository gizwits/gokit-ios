//
//  GizWifiSDK.h
//  GizWifiSDK
//
//  Created by GeHaitong on 15/7/9.
//  Copyright (c) 2015年 gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GizWifiSDK/GizWifiDefinitions.h>
#import <GizWifiSDK/GizWifiCentralControlDevice.h>
#import <GizWifiSDK/GizWifiSubDevice.h>
#import <GizWifiSDK/GizWifiGroup.h>
#import <GizWifiSDK/GizWifiSSID.h>
#import <GizWifiSDK/GizUserInfo.h>
#import <GizWifiSDK/GizWifiBinary.h>

@class GizWifiSDK;

/*
 GizWifiSDKDelegate 是 GizWifiSDK 类的委托协议，为APP开发者处理设备配置和发现、设备分组、用户登录和注册提供委托函数。
 */
@protocol GizWifiSDKDelegate <NSObject>
@optional

/*
 设备配置结果的回调接口
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 配置成功或失败。如果配置失败，其他参数为nil
 @param mac 设备 mac 地址
 @param did 设备 did。配置成功时，did的值取决于设备是否有上报
 @param productKey 设备的产品类型标识
 @note 注意：如果调用getBoundDevices接口时指定了待筛选的 productKey 集合，如果设备被成功配置到路由上了，会返回配置成功，但不会出现在设备列表中
 @see 触发函数：[GizWifiSDK setDeviceOnboarding:key:configMode:softAPSSIDPrefix:timeout:wifiGAgentType:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceOnboarding:(NSError *)result mac:(NSString *)mac did:(NSString *)did productKey:(NSString *)productKey;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didSetDeviceOnboarding:device:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceWifi:(GizWifiDevice *)device result:(int)result DEPRECATED_ATTRIBUTE;

/*
 获取设备周围Wi-Fi热点列表的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，ssidList为 nil
 @param ssidList 为若干 GizWifiSSID 实例组成的 SSID 信号列表
 @see 触发函数：[GizWifiSDK getSSIDList]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetSSIDList:(NSError *)result ssidList:(NSArray *)ssidList;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didGetSSIDList:ssidList:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didGetSSIDList:(NSArray *)ssidList result:(int)result DEPRECATED_ATTRIBUTE;

/*
 设备列表上报的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义，result.code 为 GIZ_SDK_SUCCESS 表示成功。result.code 为失败的错误码时，deviceList 为非 nil 集合
 @param deviceList GizWifiDevice 实例组成的数组，该参数将只返回根据指定productKey筛选过的设备集合。productKey在 getBoundDevices接口调用时指定
 @note 该回调接口，在不调用getBoundDevices时也可能会由SDK主动触发，主动触发是由于SDK发现设备列表发生了变化，此时错误码GIZ_SDK_SUCCESS；
 getBoundDevices接口调用时会触发该回调，错误码代表云端请求状态，设备列表是绑定设备与局域网设备合并之后的集合；
 @see 触发函数：[GizWifiSDK getBoundDevices:token:specialProductKeys:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSError *)result deviceList:(NSArray *)deviceList;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didDiscovered:deviceList:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result DEPRECATED_ATTRIBUTE;

/*
 设备配置文件上报的回调接口
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param productKey 下载数据点的产品类型唯一标识
 @param productUI 下载的 Json 格式的产品 UI 信息
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUpdateProduct:(NSError *)result producKey:(NSString *)productKey productUI:(NSString *)productUI;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didUpdateProduct:producKey:productName:productUI:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didUpdateProduct:(NSString *)product result:(int)result DEPRECATED_ATTRIBUTE;

/*
 设备绑定结果的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败
 @param did 绑定成功的设备 did
 @see 触发函数：[GizWifiSDK bindRemoteDevice:token:mac:productKey:productSecret:], [GizWifiSDK bindDeviceByQRCode:token:QRContent:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK*)wifiSDK didBindDevice:(NSError*)result did:(NSString *)did;

/*
 @deprecated 此接口功能已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didBindDevice:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage DEPRECATED_ATTRIBUTE;

/*
 设备解除绑定结果的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param did 已解绑的设备 did
 @see 触发函数：[GizWifiSDK unbindDevice:token:did:]
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSError *)result did:(NSString *)did;

/*
 @deprecated 此接口功能已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didUnbindDevice:did]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage DEPRECATED_ATTRIBUTE;

/*
 获取图片验证码的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param token 图片验证码 token。图片验证码token在1小时后过期
 @param captchaId 图片验证码 id。图片验证码5分钟后过期
 @param captchaURL 图片验证码网址。图片验证码 url 在使用后过期
 @see 触发函数：[GizWifiSDK getCaptchaCode:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetCaptchaCode:(NSError *)result token:(NSString *)token captchaId:(NSString *)captchaId captchaURL:(NSString *)captchaURL;

/*
 请求手机短信验证码的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param token 请求短信验证码时得到的 token
 @see 触发函数：[GizWifiSDK requestSendPhoneSMSCode:phone:]、[GizWifiSDK requestSendPhoneSMSCode:captchaId:captchaCode:phone:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result token:(NSString *)token;

/*
 @deprecated 此接口功能已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didRequestSendPhoneSMSCode:token:]
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError*)result DEPRECATED_ATTRIBUTE;

/*
 验证手机短信验证码的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @see 触发函数：[GizWifiSDK verifyPhoneSMSCode:verifyCode:phone:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didVerifyPhoneSMSCode:(NSError *)result;

/*
 用户注册结果的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param uid 注册成功后得到的 uid
 @param token 注册成功后得到的 token
 @see 触发函数：[GizWifiSDK registerUser:password:verificationCode:accountType:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRegisterUser:(NSError *)result uid:(NSString *)uid token:(NSString *)token;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didRegisterUser:uid:token:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token DEPRECATED_ATTRIBUTE;

/*
 用户登录结果的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param uid 注册成功后得到的 uid
 @param token 注册成功后得到的 token
 @see 触发函数：[GizWifiSDK userLoginAnonymous], [GizWifiSDK userLogin:password:], [GizWifiSDK userLoginWithThirdAccount:uid:token:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didUserLogin:uid:token:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供支持，无替代接口
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didUserLogout:(NSNumber *)error errorMessage:(NSString *)errorMessage DEPRECATED_ATTRIBUTE;

/*
 更换用户密码结果的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @see 触发函数：[GizWifiSDK changeUserPassword:oldPassword:newPassword:]、[GizWifiSDK resetPassword:verificationCode:newPassword:accountType:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChangeUserPassword:(NSError *)result;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didChangeUserPassword:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage DEPRECATED_ATTRIBUTE;

/*
 修改用户信息结果的回调接口
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败
 @see 触发函数：[GizWifiSDK changeUserInfo:username:SMSVerifyCode:accountType:additionalInfo:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChangeUserInfo:(NSError *)result;

/*
 获取用户信息的回调接口，返回用户的信息结果
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败
 @param userInfo 用户信息，详细见 GizUserInfo类
 @see 触发函数：[GizWifiSDK getUserInfo:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetUserInfo:(NSError *)result userInfo:(GizUserInfo*)userInfo;

/*
 匿名用户转换的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败
 @see 触发函数：[GizWifiSDK transAnonymousUser:username:password:verifyCode:accountType:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didTransAnonymousUser:(NSError *)result;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didTransAnonymousUser:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didTransUser:(NSNumber *)error errorMessage:(NSString *)errorMessage DEPRECATED_ATTRIBUTE;

/*
 获取用户设备分组列表的回调接口
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败
 @param groupList 为 GizWifiGroup 实例组成的数组
 @see 触发函数：[GizWifiSDK getGroups:specialProductKeys:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetGroups:(NSError *)result groupList:(NSArray *)groupList;

/*
 @deprecated 此接口已废弃，不再提供支持。请使用替代接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)XPGWifiSDK:(GizWifiSDK *)wifiSDK didGetGroups:(NSArray *)groupList result:(int)result DEPRECATED_ATTRIBUTE;

/*
 SDK系统事件通知
 @param wifiSDK 回调的 GizWifiSDK 单例
 @param eventType 事件类型。指明发生了哪一类的事件，详细见 GizEventType 枚举定义
 @param eventSource 事件源，指是谁触发的事件。
 
 如果eventType是GizEventSDK，eventSource为nil；
 如果是GizEventDevice，eventSource需要强制转换为GizWifiDevice类型再使用；
 如果是GizEventM2Mservice或者GizEventToken，eventSource需要强制转换为NSString类型再使用
 
 @param eventID 事件ID。代表事件编号，详细见 GizWifiErrorCode 枚举定义。该参数指出 eventSource 发生了什么事
 @param eventMessage 事件ID的消息描述
 @see GizEventType
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString *)eventMessage;

/*
 切换服务的结果
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @param cloudServiceInfo 云服务的信息，格式为：
 
 {
    "openAPIDomain" : "xxx",
    "openAPIPort" : xxx,
    "siteDomain" : "xxx",
    "sitePort" : xxx,
    "pushDomain": xxx,
    "pushPort": xxx
 }

 @see 触发函数：[GizWifiSDK setCloudService:]
 @see GizWifiErrorCode
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetCurrentCloudService:(NSError *)result cloudServiceInfo:(NSDictionary *)cloudServiceInfo;

/*
 绑定推送id结果（此接口待发布）
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @see 触发函数：[GizWifiSDK channelIDBind:channelID:alias:pushType:]
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDBind:(NSError *)result;

/*
 解绑推送id结果（此接口待发布）
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @see 触发函数：[GizWifiSDK channelIDUnBind:channelID:]
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDUnBind:(NSError *)result;

/*
 禁用/启用小循环的结果
 @param wifiSDK 为回调的 GizWifiSDK 单例
 @param result 详细见 GizWifiErrorCode 枚举定义。result.code 为 GIZ_SDK_SUCCESS 表示成功，其他为失败。失败时，其他回调参数为 nil
 @see 触发函数：[GizWifiSDK disableLAN:]
 */
- (void)wifiSDK:(GizWifiSDK*)wifiSDK didDisableLAN:(NSError*)result;

@end

/*
 GizWifiSDK类为APP开发者提供设备配置和发现、设备分组、用户登录和注册函数
 */
@interface GizWifiSDK : NSObject

- (instancetype)init NS_UNAVAILABLE;

/*
 获取 GizWifiSDK 单例的实例
 @return 返回初始化后 SDK 唯一的实例。SDK 不管有没有初始化，都会返回一个有效的值。
 */
+ (instancetype)sharedInstance;

/*
 初始化 SDK。该接口执行后，其他接口功能才能正常执行。并且如果app设置了delegate，SDK可能会立即通过didDisconverd上报发现的设备。
 @param 在 site.gizwits.com 中，每个注册的设备在“产品信息”中，都能够查到对应的 appID。
 */
+ (void)startWithAppID:(NSString *)appID;

/*
 获取 SDK 版本号
 @return 返回当前 SDK 的版本号码
 */
+ (NSString *)getVersion;

/*
 使用委托获取对应事件。GizWifiSDK 对应的回调接口在 GizWifiSDKDelegate 定义。需要用到哪个接口，回调即可
 */
@property (weak, nonatomic) id <GizWifiSDKDelegate>delegate;

/*
 设置日志输出级别。该级别指日志在调试终端的输出级别，默认是全部输出的
 @param logPrintLevel 日志输出级别，参考 GizLogPrintLevel 定义
 @see GizWifiLogLevel
 */
+ (void)setLogLevel:(GizLogPrintLevel)logPrintLevel;

/*
 @deprecated 此接口已废弃，不再提供支持，无替代接口。其对应的信息通过回调给出：[GizWifiSDKDelegate wifiSDK:didUpdateProduct:producKey:productName:productUI:]
 */
+ (void)updateDeviceFromServer:(NSString *)productKey DEPRECATED_ATTRIBUTE;

/*
 把设备配置到局域网 wifi 上。设备处于 softap 模式时，模组会产生一个热点名称，手机 wifi 连接此热点后就可以配置了。如果是机智云提供的固件，模组热点名称前缀为"XPG-GAgent-"，密码为"123456789"。设备处于 airlink 模式时，手机随时都可以开始配置。但无论哪种配置方式，设备上线时，手机要连接到配置的局域网 wifi 上，才能够确认设备已配置成功。
 设备配置成功时，在回调中会返回设备 mac 地址。如果设备重置了，设备did可能要在设备搜索回调中才能获取。
 
 @param ssid 待配置的路由 SSID 名
 @param key 待配置的路由密码
 @param mode 配置模式，详细见 GizWifiConfigureMode 枚举定义
 @param softAPSSIDPrefix SoftAPMode 模式下 SoftAP 的 SSID 前缀或全名。默认前缀为：XPG-GAgent-，SDK 以此判断手机当前是否连上了设备的 SoftAP 热点。AirLink 模式时传 nil 即可
 @param timeout 配置的超时时间。SDK 默认执行的最小超时时间为30秒
 @param types 待配置的模组类型，是一个GizWifiGAgentType 枚举数组。若不指定则默认配置乐鑫模组。GizWifiGAgentType定义了 SDK 支持的所有模组类型
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didSetDeviceOnboarding:device:]
 @see GizConfigureMode
 @see GizWifiGAgentType
 */
- (void)setDeviceOnboarding:(NSString *)ssid
                        key:(NSString *)key
                 configMode:(GizWifiConfigureMode)mode
           softAPSSIDPrefix:(NSString *)softAPSSIDPrefix
                    timeout:(int)timeout
             wifiGAgentType:(NSArray *)types;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[setDeviceOnboarding:key:configMode:softAPSSIDPrefix:timeout:wifiGAgentType:]
 */
- (void)setDeviceWifi:(NSString *)ssid key:(NSString *)key mode:(XPGConfigureMode)mode softAPSSIDPrefix:(NSString *)softAPSSIDPrefix timeout:(int)timeout wifiGAgentType:(NSArray *)types DEPRECATED_ATTRIBUTE;

/*
 在 Soft-AP 模式时，获得设备的 SSID 列表。SSID列表通过异步回调方式返回
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetSSIDList:ssidList:]
 */
- (void)getSSIDList;

/*
 NSArray类型，为 GizWifiDevice 对象数组。设备列表缓存，APP 访问该变量即可得到当前 GizWifiSDK 发现的设备列表
 */
@property (strong, nonatomic, readonly) NSArray *deviceList;

/*
 获取绑定设备列表。在不同的网络环境下，有不同的处理：
 当手机能访问外网时，该接口会向云端发起获取绑定设备列表请求；
 当手机不能访问外网时，局域网设备是实时发现的，但会保留之前已经获取过的绑定设备；
 手机处于无网模式时，局域网未绑定设备会消失，但会保留之前已经获取过的绑定设备；
 
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param specialProductKey 指定要搜索的产品类型，为 NSString 数组。可以指定一个或多个产品类型，如果不指定则返回所有设备
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didDiscovered:deviceList:]
 */
- (void)getBoundDevices:(NSString *)uid token:(NSString *)token specialProductKeys:(NSArray *)specialProductKeys;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[GizWifiSDK bindRemoteDevice:token:mac:productKey:productSecret:]
 */
- (void)bindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode remark:(NSString *)remark DEPRECATED_ATTRIBUTE;

/*
 绑定远端设备到服务器
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param mac 待绑定设备的mac
 @param productKey 待绑定设备的productKey
 @param productSecret 待绑定设备的productSecret
 @param appSecret 在 site 上的应用管理得到的 appSecret
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didBindDevice:did:]
 */
- (void)bindRemoteDevice:(NSString *)uid token:(NSString *)token mac:(NSString *)mac productKey:(NSString *)productKey productSecret:(NSString *)productSecret;

/*
 根据二维码绑定设备到服务器（此接口待发布）
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param QRContent 二维码内容
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didBindDevice:did:]
 */
- (void)bindDeviceByQRCode:(NSString*)uid token:(NSString *)token QRContent:(NSString *)QRContent;

/*
 从服务器解绑设备
 @param 用户登录或注册时得到的uid
 @param 用户登录或注册时得到的token
 @param 待解绑设备的did
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didUnbindDevice:did:]
 */
- (void)unbindDevice:(NSString *)uid token:(NSString *)token did:(NSString *)did;

/*
 @deprecated 此接口功能已废弃，不再提供支持。替代接口：[unbindDevice:token:did:]
 */
- (void)unbindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode DEPRECATED_ATTRIBUTE;

/*
 获取图片验证码。开发者登录 site.gizwits.com，在自己账户下的应用管理中可以得到 App Secret，通过应用的 App Secret 才能获取到图片验证码
 @param appSecret 应用的 secret 信息，从 site.gizwits.com 中可以看到
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetCaptchaCode:token:captchaId:captchaURL:]
 */
- (void)getCaptchaCode:(NSString *)appSecret;

/*
 通过图形验证码获取手机短信验证码
 @param token 通过 getCaptchaCode 获取到的 token
 @param captchaId 通过 getCaptchaCode 获取到的 captchaId
 @param captchaCode 图片验证码的内容
 @param phone 手机号
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didRequestSendPhoneSMSCode:]
 */
- (void)requestSendPhoneSMSCode:(NSString *)token captchaId:(NSString *)captchaId captchaCode:(NSString *)captchaCode phone:(NSString *)phone;

/*
 通过手机号请求短信验证码
 @param 应用的 secret 信息，从 site.gizwits.com 中可以看到
 @param phone 手机号
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didRequestSendPhoneSMSCode:token:]
 */
- (void)requestSendPhoneSMSCode:(NSString *)appSecret phone:(NSString *)phone;

/*
 验证手机短信验证码。注意，验证短信验证码后，验证码就失效了，无法再用于手机号注册
 @param token 验证码的 token，通过 getCaptchaCode 获取
 @param phoneCode 手机短信验证码
 @param phone 手机号
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didVerifyPhoneSMSCode:]
 */
- (void)verifyPhoneSMSCode:(NSString *)token verifyCode:(NSString *)code phone:(NSString *)phone;

/*
 用户注册。需指定用户类型注册。手机用户的用户名是手机号，邮箱用户的用户名是邮箱、普通用户的用户名可以是普通用户名
 @param username 注册用户名（可以是手机号、邮箱或普通用户名）
 @param password 注册密码
 @param code 手机短信验证码。短信验证码注册后就失效了，不能被再次使用
 @param accountType 用户类型，详细见 GizUserAccountType 枚举定义。注册手机号时，此参数指定为手机用户，注册邮箱时，此参数指定为邮箱用户，注册普通用户名时，此参数指定为普通用户
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didRegisterUser:uid:token:]
 @see GizUserAccountType
 */
- (void)registerUser:(NSString *)username
            password:(NSString *)password
          verifyCode:(NSString *)code
         accountType:(GizUserAccountType)accountType;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[registerUser:password:verifyCode:accountType:]
 */
- (void)registerUser:(NSString *)userName password:(NSString *)password DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[registerUser:password:verifyCode:accountType:]
 */
- (void)registerUserByPhoneAndCode:(NSString *)phone password:(NSString *)password code:(NSString *)code DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[registerUser:password:verifyCode:accountType:]
 */
- (void)registerUserByEmail:(NSString *)email password:(NSString *)password DEPRECATED_ATTRIBUTE;

/*
 匿名登录。匿名方式登录，不需要注册用户账号
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didUserLogin:uid:token:]
 */
- (void)userLoginAnonymous;

/*
 用户登录。需使用注册成功的用户名、密码进行登录，可以是手机用户名、邮箱用户名或普通用户名
 @param username 注册成功的用户名
 @param password 注册成功的用户密码
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didUserLogin:uid:token:]
 */
- (void)userLogin:(NSString *)username password:(NSString *)password;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[userLogin:password:]
 */
- (void)userLoginWithUserName:(NSString *)szUserName password:(NSString *)szPassword DEPRECATED_ATTRIBUTE;

/*
 第三方账号登录（第三方接口登录方式）
 @param thirdAccountType 第三方账号类型，详细见 GizThirdAccountType 枚举定义
 @param uid 通过第三方平台 api 方式登录后得到的 uid
 @param token 通过第三方平台api方式 登录后得到的 token
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didUserLogin:uid:token:]
 @see GizThirdAccountType
 */
- (void)userLoginWithThirdAccount:(GizThirdAccountType)thirdAccountType uid:(NSString *)uid token:(NSString *)token;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[userLoginWithThirdAccount:uid:token:]
 */
- (void)userLoginWithThirdAccountType:(XPGWifiThirdAccountType)thirdAccountType uid:(NSString *)uid token:(NSString *)token DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供功能支持，无替代接口。
 */
- (void)userLogout:(NSString *)uid DEPRECATED_ATTRIBUTE;

/*
 修改用户密码
 @param token 用户登录或注册时得到的 token
 @param oldPassword 旧密码
 @param newPassword 新密码
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didChangeUserPassword:]
 */
- (void)changeUserPassword:(NSString *)token
               oldPassword:(NSString *)oldPassword
               newPassword:(NSString *)newPassword;

/*
 重置密码
 @param username 待重置密码的手机号或邮箱
 @param code 重置手机用户密码时需要使用手机短信验证码（通过 requestSendPhoneSMSCode 方法获取）
 @param newPassword 新密码
 @param accountType 用户类型，详细见 GizThirdAccountType 枚举定义。待重置密码的用户名是手机号时，此参数指定为手机用户，待重置密码的用户名是邮箱时，此参数指定为邮箱用户
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didChangeUserPassword:errorMessage:]
 @see GizUserAccountType
 */
- (void)resetPassword:(NSString *)username
           verifyCode:(NSString *)code
          newPassword:(NSString *)newPassword
          accountType:(GizUserAccountType)accountType;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[resetPassword:verifyCode:newPassword:accountType:]
 */
- (void)changeUserPasswordByCode:(NSString *)phone code:(NSString *)code newPassword:(NSString *)newPassword DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[resetPassword:verifyCode:newPassword:accountType:]
 */
- (void)changeUserPasswordByEmail:(NSString *)email DEPRECATED_ATTRIBUTE;

/*
 修改用户信息，包括用户名和个人信息。用户名只支持修改手机号或邮箱，并且手机号或邮箱必须是已经注册过的。该接口用于以下场景：
 只修改手机号、只修改邮箱、只修改普通用户的个人信息、同时修改手机号和补充信息、同时修改邮箱和补充信息。
 只修改个人信息时，accountType可以指定为GizUserNormal；修改手机号要指定为GizUserPhone；修改邮箱要指定为GizUserEmail
 
 @param token 用户登录或注册时得到的 token
 @param username 待修改的手机号或邮箱
 @param code 修改手机号时要使用的手机短信验证码
 @param accountType 用户类型，详细见 GizThirdAccountType 枚举定义。修改手机号时，accountType传GizUserPhone；修改普通用户名时，accountType传GizUserEmail；只修改个人信息时，accountType传GizUserNormal；同时修改用户名和个人信息时，可根据待修改的是手机号还是邮箱来指定
 @param additionalInfo 待修改的个人信息，详细见 GizUserInfo 类定义。如果只修改个人信息，需要指定token，username、code填null
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didChangeUserInfo:]
 @see GizUserAccountType
 @see GizUserInfo
 */
- (void)changeUserInfo:(NSString *)token username:(NSString *)username SMSVerifyCode:(NSString *)code accountType:(GizUserAccountType)accountType additionalInfo:(GizUserInfo *)additionalInfo;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[changeUserInfo:username:SMSVerifyCode:accountType:additionalInfo:]
 */
- (void)changeUserInfo:(NSString *)token username:(NSString *)username verifyCode:(NSString *)code accountType:(XPGUserAccountType)accountType additionalInfo:(GizUserInfo *)additionalInfo DEPRECATED_ATTRIBUTE;

/*
 获取用户信息
 @param token 用户登录或注册时得到的 token
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetUserInfo:]
 */
- (void)getUserInfo:(NSString *)token;

/*
 匿名用户转换，可转换为手机用户或者普通用户。注意，待转换的帐号必须是还未注册过的
 @param token 用户登录或注册时得到的 token
 @param username 待转换用户的普通账号或手机号
 @param password 待转换用户的密码
 @param code 转换为手机用户时需要使用手机短信验证码
 @param accountType 用户类型，详细见 GizThirdAccountType 枚举定义。待转换的用户名是手机号时，此参数指定为GizUserPhone，待转换用户名是普通账号时，此参数指定为GizUserNormal
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didTransAnonymousUser:]
 @see GizUserAccountType
 */
- (void)transAnonymousUser:(NSString *)token
                  username:(NSString *)username
                  password:(NSString *)password
                verifyCode:(NSString *)code
               accountType:(GizUserAccountType)accountType;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[transAnonymousUser:username:password:verifyCode:accountType:]
 */
- (void)transAnonymousUserToNormalUser:(NSString *)token userName:(NSString *)userName password:(NSString *)password DEPRECATED_ATTRIBUTE;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[transAnonymousUser:username:password:verifyCode:accountType:]
 */
- (void)transAnonymousUserToPhoneUser:(NSString *)token phone:(NSString *)phone password:(NSString *)password code:(NSString *)code DEPRECATED_ATTRIBUTE;

/*
 获取分组列表
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param specialProductKeys 待筛选的组类型标识，NSString数组。不指定则不筛选
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)getGroups:(NSString *)uid token:(NSString *)token specialProductKeys:(NSArray *)specialProductKeys;

/*
 添加分组。添加分组时，必须指定组类型，组类型应该是一个有效的设备产品类型标识。默认分配的组名称为“Default”，组设备亦可以在创建组之后再添加。但如果添加的组设备是SDK无法识别的，也无法被添加到分组中
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param productKey 指定组类型标识
 @param groupName 指定组名称
 @param specialDevices 指定加入组内的设备（成员为字典，依赖键值 sdid（子设备标识码）、did（父设备标识码），暂不加入设备则传空）
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)addGroup:(NSString *)uid
           token:(NSString *)token
      productKey:(NSString *)productKey
       groupName:(NSString *)groupName
  specialDevices:(NSArray *)specialDevices;

/*
 删除设备分组
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param gid 待删除的组id
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)removeGroup:(NSString *)uid token:(NSString *)token gid:(NSString *)gid;

/*
 编辑分组，可以修改组名称和组设备。但如果要编辑的组设备，与组类型不匹配时，或是SDK无法识别的，设备是不能更新到分组里的
 @param uid 用户登录或注册时得到的 uid
 @param token 用户登录或注册时得到的 token
 @param gid 编辑组时需要指定组id
 @param groupName 待修改的组名称
 @param specialDevices 要编辑的组内设备。字典数组，依赖键值 sdid（子设备标识码）、did（父设备标识码）。不指定设备则传 null
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetGroups:groupList:]
 */
- (void)editGroup:(NSString *)uid
            token:(NSString *)token
              gid:(NSString *)gid
        groupName:(NSString *)groupName
   specialDevices:(NSArray *)specialDevices;

/*
 切换服务器
 @param cloudServiceInfo 服务器信息。格式： {
 "openAPIDomain": xxx,
 "openAPIPort": xxx,
 "siteDomain": xxx,
 "sitePort": xxx,
 "pushDomain": xxx.
 "pushPort": xxx
 }
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetCurrentCloudService:cloudServiceInfo:]
 */
+ (void)setCloudService:(NSDictionary *)cloudServiceInfo;

/*
 @deprecated 此接口已废弃，不再提供支持。替代接口：[setCloudService:]
 */
+ (void)setCloudService:(NSString *)openAPIDomain openAPIPort:(int)port siteDomain:(NSString *)domain sitePort:(int)sitePort DEPRECATED_ATTRIBUTE;

/*
 获取当前的服务器
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didGetCurrentCloudService:cloudServiceInfo:]
 */
+ (void)getCurrentCloudService;

/*
 绑定推送的id（此接口待发布）
 @param token 用户登录或注册时得到的 token
 @param channelID 推送ID
 @param alias 别名
 @param pushType 推送类型，详细见 GizPushType 枚举定义
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didChannelIDBind:]
 */
- (void)channelIDBind:(NSString *)token channelID:(NSString *)channelID alias:(NSString *)alias pushType:(GizPushType)pushType;

/*
 解绑推送的id（此接口待发布）
 @param token 用户登录或注册时得到的 token
 @param channelID 推送ID
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didChannelIDUnBind:]
 */
- (void)channelIDUnBind:(NSString *)token channelID:(NSString *)channelID;

/*
 禁用/启用小循环
 @param disabled YES=禁用小循环，NO=启用小循环
 @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didDisableLAN:]
 */
+ (void)disableLAN:(BOOL)disabled;

@end
