//
//  XPGWifiSDK.h
//  XPGWifiSDK
//
//  Created by xpg on 14-7-8.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XPGWifiSDK/XPGWifiDevice.h>
#import <XPGWifiSDK/XPGWifiSSID.h>
#import <XPGWifiSDK/XPGWifiBinary.h>
#import <XPGWifiSDK/XPGWifiCentralControlDevice.h>
#import <XPGWifiSDK/XPGWifiSubDevice.h>
#import <XPGWifiSDK/XPGWifiGroup.h>

typedef enum
{
    XPGWifiThirdAccountTypeBAIDU = 0,
    XPGWifiThirdAccountTypeSINA,
}XPGWifiThirdAccountType;

typedef enum
{
    XPGWifiLogLevelError = 0,
    XPGWifiLogLevelWarning,
    XPGWifiLogLevelAll,
}XPGWifiLogLevel;

typedef enum _tagXPGWifiErrorCode
{
    XPGWifiError_NONE = 0,
    XPGWifiError_GENERAL = -1,
    XPGWifiError_NOT_IMPLEMENTED = -2,
    XPGWifiError_PACKET_DATALEN = -4,
    XPGWifiError_CONNECTION_ID = -5,
    XPGWifiError_CONNECTION_CLOSED = -7,
    XPGWifiError_PACKET_CHECKSUM = -8,
    XPGWifiError_LOGIN_FAIL = -10,
    XPGWifiError_MQTT_FAIL = -12,
    XPGWifiError_DISCOVERY_MISMATCH = -13,
    XPGWifiError_SET_SOCK_OPT = -14,
    XPGWifiError_THREAD_CREATE = -15,
    XPGWifiError_CONNECTION_POOL_FULLED = -17,
    XPGWifiError_NULL_CLIENT_ID = -18,
    XPGWifiError_CONNECTION_ERROR = -19,
    XPGWifiError_INVALID_PARAM = -20,
    XPGWifiError_CONNECT_TIMEOUT = -21,
    XPGWifiError_INVALID_VERSION = -22,
    XPGWifiError_INSUFFIENT_MEM = -23,
    XPGWifiError_THREAD_BUSY = -24,
    XPGWifiError_HTTP_FAIL = -25,
    XPGWifiError_GET_PASSCODE_FAIL = -26,
    
    // pomia 141104, start: detail the error reason
    XPGWifiError_CONFIGURE_TIMEOUT = -40,
    XPGWifiError_CONFIGURE_SENDFAILED = -41,
    XPGWifiError_NOT_IN_SOFTAPMODE = -42,
    XPGWifiError_UNRECOGNIZED_DATA = -43,
    XPGWifiError_CONNECTION_NO_GATEWAY = -44,
    XPGWifiError_CONNECTION_REFUSED = -45,
    // pomia 141104, end
}XPGWifiErrorCode;

typedef enum _tagXPGWifiLoginErrorCode
{
    XPGWifiLoginError_CONTROL_ENABLED = 0,
    XPGWifiLoginError_LOGINED,
    XPGWifiLoginError_FAILED,
}XPGWifiLoginErrorCode;

typedef enum
{
    XPGWifiSDKSoftAPMode = 1,
    XPGWifiSDKAirLinkMode = 2,
}XPGConfigureMode;

typedef enum _tagXPGCloudService
{
    XPG_PRODUCTION = 0,
    XPG_QA = 1,
    XPG_DEVELOPMENT = 2,
    XPG_TENCENT = 3,
}XPGCloudService;

@class XPGWifiSDK;

@protocol XPGWifiSDKDelegate <NSObject>
@optional

/**
 * @brief 回调接口，返回设备 Soft AP 模式下的 SSID 列表
 * @param ssidList：为 XPGWifiSSID * 的集合
 * @see 触发函数：[XPGWifiSDK getSSIDList]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetSSIDList:(NSArray *)ssidList result:(int)result;

/**
 * @brief 回调接口，返回设备配置的结果
 * @param device：已配置成功的设备
 * @param result：配置结果 成功或失败 如果配置失败，device为nil
 * @see 触发函数：[XPGWifiSDK setDeviceWifi:key:mode:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetDeviceWifi:(XPGWifiDevice *)device result:(int)result;

/**
 * @brief 回调接口，返回发现设备的结果
 * @param deviceList：为 XPGWifiDevice* 的集合
 * @param result：0为成功，其他失败
 * @see 触发函数：[XPGWifiSDK getBoundDevicesWithUid:token:specialProductKeys:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result;

/**
 * @brief 回调接口，返回组列表
 * @param groupList：为 XPGWifiGroup* 的集合
 * @param result：0为成功，其他失败
 * @see 触发函数：[XPGWifiSDK getGroupsWithUid:token:specialProductKeys:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetGroups:(NSArray *)groupList result:(int)result;

/**
 * @brief 回调接口，自定义CRC算法，下发V3数据协议的设备控制命令会触发此回调接口
 * @param data：需要计算的数据
 * @result 返回计算结果
 * @see 触发函数：[XPGWifiDevice write:]
 */
- (NSUInteger)XPGWifiSDK:(XPGWifiSDK *)wifiSDK needsCalculateCRC:(NSData *)data;

/**
 * @brief 回调接口，返回从服务器下载到的配置
 * @param product：下载的ProductKey
 * @param result：下载的结果：-25=网络故障，-1=服务器返回的数据错误，0=成功
 * 自动下载的情况下，下载的结果：1=不更新
 * @see 触发函数：[XPGWifiSDK updateDeviceFromServer:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUpdateProduct:(NSString *)product result:(int)result;

/**
 * @brief 回调接口，返回请求向指定手机发送验证码的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK requestSendVerifyCode:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendVerifyCode:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回注册用户的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @param uid：注册成功后得到的uid（不成功则为nil）
 * @param token：注册成功后得到的token（不成功则为nil）
 * @see 触发函数：[XPGWifiSDK registerUser:password:]、[XPGWifiSDK registerUserByEmail:password:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token;

/**
 * @brief 回调接口，返回用户登录的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @param uid：登录成功后得到的uid（不成功则为nil）
 * @param token：登录成功后得到的token（不成功则为nil）
 * @see 触发函数：[XPGWifiSDK userLoginAnonymous]、[XPGWifiSDK userLoginWithUserName:password:]、[XPGWifiSDK userLoginWithThirdAccountType:uid:token:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token;

/**
 * @brief 回调接口，返回用户注销的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK userLogout:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogout:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回匿名用户转换为普通用户或手机用户的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK transAnonymousUserToNormalUser:passcode:]、[XPGWifiSDK transAnonymousUserToPhoneUser:phone:password:code:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didTransUser:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回修改用户密码结果（对应changeUserPassword、changeUserPasswordByCode）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK changeUserPassword:oldPassword:newPassword:]、[XPGWifiSDK changeUserPasswordByCode:code:newpassword:]、[XPGWifiSDK changeUserPasswordByEmail:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回修改用户邮箱地址结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK changeUserEmail:email:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserEmail:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，修改用户手机号结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK changeUserPhone:phone:code:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPhone:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回绑定结果
 * @param did：设备 did
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK bindDeviceWithUid:token:did:passCode:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 回调接口，返回解绑结果
 * @param did：设备 did
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 * @see 触发函数：[XPGWifiSDK unBindDeviceWithUid:token:did:passCode:]
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUnbindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage;

@end

@interface XPGWifiSDK : NSObject

+ (XPGWifiSDK *)sharedInstance;

/**
 * @brief 启动SDK
 * @param appID：在机智云申请到的应用标识
 * @note 请务必最先调用该接口，为后续接口调用做准备
 */
+ (void)startWithAppID:(NSString *)appID;

@property (nonatomic, assign) id <XPGWifiSDKDelegate>delegate;

/**
 * @brief 读取SDK版本号
 */
- (NSString*)getVersion;

/**
 * @brief 设置Log级别、Log文件路径、Log内二进制输出级别
 *
 * @param logLevel：日志级别。枚举值简介：
 * XPGWifiLogLevelError     只输出错误
 * XPGWifiLogLevelWarning   只输出错误和警告
 * XPGWifiLogLevelAll       输出所有日志内容
 * @note 默认 level=XPGWifiLogLevelAll???
 *
 * logFile：日志文件的相对路径（相对/Documents）(指定Nil则不输出到文件)
 * @note 默认不输出到文件
 *
 * @param printDataLevel：日志内二进制数据输出级别。布尔值简介：
 * isDebug=YES：  输出最多信息
 * isDebug=NO：   输出最少信息
 * @note 默认 bPrintDataInDebug=NO
 *
 * 仅在[XPGWifiSDK sharedInstance]后设置有效
 */
+ (void)setLogLevel:(XPGWifiLogLevel)logLevel logFile:(NSString *)logFile printDataLevel:(BOOL)bPrintDataInDebug;

/**
 * @brief 注册识别 Soft AP 模式的规则
 * @param ssidPrefix：识别SSID的前缀
 * @note 在载入配置文件之前配置有效。默认nil
 */
+ (void)registerSSIDs:(NSString *)ssidPrefix, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_ATTRIBUTE;

#ifdef SWIFT
+ (void)registerSSID:(NSString *)ssid;
+ (void)clearSSIDs;
#endif

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/**
 * @brief 设置服务地址切换，用于切换云端的调试环境和发布环境
 * @param specialService XPGCloudService类型：0=生产环境 1=测试环境 2=开发环境 3=腾讯云
 * @note 默认生产环境
 */
+ (void)setSwitchService:(int)specialService;
#endif

#ifdef __INTERNAL_SUPPORT_SWITCH_SERVICE_AND_LOG_CACHE__
/**
 * @brief 设置SDK缓存日志条数
 * @param count 范围：0-10000
 */
+ (void)setLogCacheCount:(NSInteger)count;

/**
 * @brief 获取日志文本
 * @result 返回日志数组
 */
+ (NSArray *)getLogList;
#endif

#ifdef __INTERNAL_TESTING_API__
#define CURRENT_SERVICE @"CurrentService"
#define OPENAPI_SERVICE @"OpenAPI"
#define CONFIG_SERVICE @"Configure"
#define M2M_SERVICE @"m2mService"

/**
 * @brief 获取当前云端环境域名
 * @param deviceDID 指定设备的Did，用于获取该设备连接的M2M域名
 * @result 服务名称字典 {key, value} = {CURRENT_SERVICE:当前环境}、{OPENAPI_SERVICE:业务域名}、{CONFIG_SERVICE:配置文件服务器域名}、{M2M_SERVICE:M2M域名}
 */
+ (NSDictionary*)getUsingService:(NSString*)deviceDID;
#endif

/**
 * @brief 获取设备的配置
 * @param productKey：设备唯一标识符
 * @result 检查参数是否符合要求
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUpdateProduct:result:]
 */
+ (void)updateDeviceFromServer:(NSString *)productKey;

/**
 * @brief 配置路由的方法
 * @param ssid：需要配置到路由的SSID名
 * @param key：需要配置到路由的密码
 * @param mode：配置方式 SoftAPMode=软AP模式 AirLinkMode=一键配置模式
 * @param timeout: 配置的超时时间 SDK默认执行的最小超时时间为30秒
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didSetDeviceWifi:result:]
 */
- (void)setDeviceWifi:(NSString*)ssid
                  key:(NSString*)key
                 mode:(XPGConfigureMode)mode
              timeout:(int)timeout DEPRECATED_ATTRIBUTE;

/**
 * @brief 配置路由的方法
 * @param ssid：需要配置到路由的SSID名
 * @param key：需要配置到路由的密码
 * @param mode：配置方式 SoftAPMode=软AP模式 AirLinkMode=一键配置模式
 * @param softAPSSIDPrefix：SoftAPMode模式下SoftAP的SSID前缀或全名（XPGWifiSDK以此判断手机当前是否连上了SoftAP，AirLinkMode该参数无意义，传nil即可）
 * @param timeout: 配置的超时时间 SDK默认执行的最小超时时间为30秒
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didSetDeviceWifi:result:]
 */
- (void)setDeviceWifi:(NSString*)ssid
                  key:(NSString*)key
                 mode:(XPGConfigureMode)mode
     softAPSSIDPrefix:(NSString*)softAPSSIDPrefix
              timeout:(int)timeout;

/**
 * @brief 获取设备Wifi在软AP模式下搜索到的SSID列表，SSID列表通过异步回调方式返回
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didGetSSIDList:result:]
 */
- (void)getSSIDList;

/**
 * @brief 请求向指定手机发送验证码
 * @param phone：手机号
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didRequestSendVerifyCode:errorMessage:]
 */
- (void)requestSendVerifyCode:(NSString *)phone;

/**
 * @brief 注册用户（通过用户名跟密码注册）
 * @param userName：注册用户名
 * @param password：注册密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didRegisterUser:errorMessage:uid:token:]
 */
- (void)registerUser:(NSString *)userName password:(NSString *)password;

/**
 * @brief 注册用户（通过手机号、密码跟校验码注册）
 * @param phone：注册手机号
 * @param password：注册密码
 * @param code：注册验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didRegisterUser:errorMessage:uid:token:]
 */
- (void)registerUserByPhoneAndCode:(NSString *)phone password:(NSString *)password code:(NSString *)code;

/**
 * @brief 注册用户（通过邮箱、密码注册）
 * @param email：注册邮箱
 * @param password：注册密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didRegisterUser:errorMessage:uid:token:]
 */
- (void)registerUserByEmail:(NSString *)email password:(NSString *)password;

/**
 * @brief 用户登录（匿名方式）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUserLogin:errorMessage:uid:token:]
 */
- (void)userLoginAnonymous;

/**
 * @brief 用户登录（用户名密码方式）
 * @param szUserName：注册得到的用户名
 * @param szPassword：注册得到的密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUserLogin:errorMessage:uid:token:]
 */
- (void)userLoginWithUserName:(NSString *)szUserName password:(NSString *)szPassword;

/**
 * @brief 用户登录（第三方接口登录）
 * @param szThirdAccountType：第三方账户的类型
 * @param szUid：第三方账户的uid
 * @param szToken：第三方账户的token
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUserLogin:errorMessage:uid:token:]
 */
- (void)userLoginWithThirdAccountType:(XPGWifiThirdAccountType)szThirdAccountType uid:(NSString *)szUid token:(NSString *)szToken;

/**
 * @brief 用户注销
 * @param uid：登录成功后得到的uid
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUserLogout:errorMessage:]
 */
- (void)userLogout:(NSString *)uid;

/**
 * @brief 将匿名用户转换为普通（非手机号）用户
 * @param token：匿名方式登录成功后得到的token
 * @param userName：待转换用户的用户名
 * @param password：待转换用户的密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didTransUser:errorMessage:]
 */
- (void)transAnonymousUserToNormalUser:(NSString *)token userName:(NSString *)userName password:(NSString *)password;

/**
 * @brief 将匿名用户转换为手机号用户
 * @param token：匿名方式登录成功后得到的token
 * @param userName：待转换用户的手机号
 * @param password：待转换用户的密码
 * @param code：待转换用户的验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didTransUser:errorMessage:]
 */
- (void)transAnonymousUserToPhoneUser:(NSString *)token phone:(NSString *)phone password:(NSString *)password code:(NSString *)code;

/**
 * @brief 修改用户密码
 * @param token：登录成功后得到的token
 * @param oldPassword：之前的老密码
 * @param newPassword：需要修改的新密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didChangeUserPassword:errorMessage:]
 */
- (void)changeUserPassword:(NSString *)token oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword;

/**
 * @brief 手机用户通过短信验证码重置密码
 * @param phone：手机号
 * @param code：短信验证码
 * @param newPassword：设置新密码
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didChangeUserPassword:errorMessage:]
 */
- (void)changeUserPasswordByCode:(NSString *)phone code:(NSString *)code newPassword:(NSString *)newPassword;

/**
 * @brief 手机用户通过邮箱重置密码
 * @param email：邮箱地址
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didChangeUserPassword:errorMessage:]
 */
- (void)changeUserPasswordByEmail:(NSString *)email;

/**
 * @brief 修改用户邮箱地址
 * @param token：登录成功后得到的token
 * @param email：指定需要修改成的邮箱地址
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didChangeUserEmail:errorMessage:]
 */
- (void)changeUserEmail:(NSString *)token email:(NSString *)email;

/**
 * @brief 修改用户邮箱地址
 * @param token：登录成功后得到的token
 * @param phone：指定需要修改成的手机号
 * @param code：指定需要修改成的手机号收到验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didChangeUserPhone:errorMessage:]
 */
- (void)changeUserPhone:(NSString *)token phone:(NSString *)phone code:(NSString *)code;

/**
 * @brief 绑定设备到服务器
 * @param token：登录成功后得到的token
 * @param uid：登录成功后得到的uid
 * @param did：待绑定设备的did
 * @param passCode：待绑定设备的passCode（能得到就传，得不到可传Nil，SDK会内部尝试获取PassCode）
 * @param remark：待绑定设备的别名，无别名可传nil
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didBindDevice:error:errorMessage:]
 */
- (void)bindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode remark:(NSString*)remark;

/**
 * @brief 从服务器解绑设备
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param did：待解绑设备的did
 * @param passCode：待解绑设备的passCode（能得到就传，得不到可传Nil，SDK会内部尝试获取PassCode）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didUnbindDevice:error:errorMessage:]
 */
- (void)unbindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode;

/**
 * @brief 获取绑定设备及本地设备列表
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param specialProductKey：指定待筛选设备的产品标识（获取或搜索到未指定设备产品标识的设备将其过滤，指定Nil则不过滤）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didDiscovered:result:]
 */
- (void)getBoundDevicesWithUid:(NSString *)uid token:(NSString *)token specialProductKeys:(NSString *)specialProductKey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * @brief 获取组列表
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param specialProductKey：指定待筛选的组类型标识（获取到未指定类型标识的组将其过滤，指定Nil则不过滤）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didGetGroups:result:]
 */
- (void)getGroupsWithUid:(NSString *)uid token:(NSString *)token specialProductKeys:(NSString *)specialProductKey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * @brief 新建组
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param productKey：指定组类型标识
 * @param groupName：指定组名称
 * @param specialDevices：指定加入组内的设备（成员为字典，依赖键值sdid（子设备标识码）、did（父设备标识码），暂不加入设备则传空）
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didGetGroups:result:]
 */
- (void)addGroup:(NSString *)uid
           token:(NSString *)token
      productKey:(NSString *)productKey
       groupName:(NSString *)groupName
  specialDevices:(NSArray *)specialDevices;

/**
 * @brief 删除组
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param gid：指定组ID
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didGetGroups:result:]
 */
- (void)removeGroup:(NSString *)uid token:(NSString *)token gid:(NSString *)gid;

/**
 * @brief 编辑组
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param gid：指定组ID
 * @param groupName：指定组昵称
 * @param specialDevices：编辑组内的设备（成员为字典，依赖键值sdid（子设备标识码）、did（父设备标识码））
 * @see 对应的回调接口：[XPGWifiSDK XPGWifiSDK:didGetGroups:result:]
 */
- (void)editGroup:(NSString *)uid
            token:(NSString *)token
              gid:(NSString *)gid
        groupName:(NSString*)groupName
   specialDevices:(NSArray *)specialDevices;

#ifdef SWIFT
- (void)getBoundDevice:(NSString *)uid token:(NSString *)token;
- (void)EnableProductFilter:(BOOL)isEnable;
- (void)RegisterProductKey:(NSString *)productKey;
- (void)ClearProductKey;
#endif

@end
