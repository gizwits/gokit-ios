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

#ifndef __INTERNAL_LOG_CACHE__
#define __INTERNAL_LOG_CACHE__
#endif

typedef enum
{
    XPGWifiThirdAccountTypeBAIDU = 0,
    XPGWifiThirdAccountTypeSINA,
    XPGWifiThirdAccountTypeQQ,
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
    XPGWifiError_DESCRIPTOR_FAIL = -3,
    XPGWifiError_PACKET_DATALEN = -4,
    XPGWifiError_CONNECTION_ID = -5,
    XPGWifiError_PATH = -6,
    XPGWifiError_CONNECTION_CLOSED = -7,
    XPGWifiError_PACKET_CHECKSUM = -8,
    XPGWifiError_LOGIN_FAIL = -10,
    XPGWifiError_DOMAIN_NAME = -11,
    XPGWifiError_MQTT_FAIL = -12,
    XPGWifiError_DISCOVERY_MISMATCH = -13,
    XPGWifiError_SET_SOCK_OPT = -14,
    XPGWifiError_THREAD_CREATE = -15,
    XPGWifiError_NULL_MAC = -16,
    XPGWifiError_CONNECTION_POOL_FULLED = -17,
    XPGWifiError_NULL_CLIENT_ID = -18,
    XPGWifiError_CONNECTION_ERROR = -19,
    XPGWifiError_INVALID_PARAM = -20,
    XPGWifiError_CONNECT_TIMEOUT = -21,
    XPGWifiError_INVALID_VERSION = -22,
    XPGWifiError_INSUFFIENT_MEM = -23,
    XPGWifiError_THREAD_BUSY = -24,
}XPGWifiErrorCode;

typedef enum _tagXPGWifiLoginErrorCode
{
    XPGWifiLoginError_CONTROL_ENABLED = 0,
    XPGWifiLoginError_LOGINED,
    XPGWifiLoginError_FAILED,
}XPGWifiLoginErrorCode;

@class XPGWifiSDK;

@protocol XPGWifiSDKDelegate <NSObject>
@optional

/**
 * @brief Soft AP 模式得到 SSID 列表
 * @param ssidList：为 XPGWifiSSID * 的集合
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetSSIDList:(NSArray *)ssidList result:(int)result;

/**
 * @brief Air Link 模式成功配置设备
 * @param device：已配置成功的设备
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetAirLink:(XPGWifiDevice *)device;

/**
 * @brief 发现设备的结果
 * @param deviceList：为 XPGWifiDevice* 的集合
 * @param result：0为成功，其他失败
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result;

/**
 * @brief 自定义CRC算法
 * @param data：需要计算的数据
 * @result 返回计算结果
 */
- (NSUInteger)XPGWifiSDK:(XPGWifiSDK *)wifiSDK needsCalculateCRC:(NSData *)data;

/**
 * @brief 从服务器下载到的配置
 * @param product：下载的ProductKey
 * @param result：下载的结果：-25=网络故障，-1=服务器返回的数据错误，0=成功
 * 自动下载的情况下，下载的结果：1=不更新
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUpdateProduct:(NSString *)product result:(int)result;

/**
 * @brief 请求向指定手机发送验证码的结果
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendVerifyCode:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 注册用户的结果（对应registerUser）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @param uid：注册成功后得到的uid（不成功则为nil）
 * @param token：注册成功后得到的token（不成功则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token;

/**
 * @brief 用户登录的结果（对应userLoginAnonymous、userLoginWithUserName、userLoginWithThirdAccountType）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 * @param uid：登录成功后得到的uid（不成功则为nil）
 * @param token：登录成功后得到的token（不成功则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token;

/**
 * @brief 用户注销的结果（对应userLogout）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogout:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 匿名用户转换为普通用户或手机用户的结果（对应transAnonymousUserToNormalUser、transAnonymousUserToPhoneUser）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didTransUser:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 修改用户密码结果（对应changeUserPassword、changeUserPasswordByCode）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 修改用户邮箱地址结果（对应changeUserEmail）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserEmail:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 修改用户手机号结果（对应changeUserPhone）
 * @param error：0为成功，其他失败
 * @param errorMessag：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPhone:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 绑定结果
 * @param did：设备 did
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 解绑结果
 * @param did：设备 did
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUnbindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage;

/**
 * @brief 获取设备详细信息结果（对应getDeviceDetailInfoWithUid）
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 * @param productKey：设备的productKey（有错误则为nil）
 * @param did：设备的uid（有错误则为nil）
 * @param mac：设备的mac（有错误则为nil）
 * @param passCode：设备的passCode（有错误则为nil）
 * @param host：设备的M2M服务器域名（有错误则为nil）
 * @param port：设备的M2M服务器端口（有错误则为0）
 * @param isOnline：设备的在线状态（有错误则为NO）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetDeviceInfo:(NSNumber *)error errorMessage:(NSString *)errorMessage productKey:(NSString *)productKey did:(NSString *)did mac:(NSString *)mac passCode:(NSString *)passCode host:(NSString *)host port:(NSNumber *)port isOnline:(BOOL)isOnline;

/**
 * @brief 获取设备历史数据结果（对应getDeviceHistoryDataWithDid）
 * @param error：0为成功，其他失败
 * @param errorMessage：错误信息（无错误则为nil）
 * @param data：历史数据数组（数组成员类型为字典类型）（有错误则为nil）
 */
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetDeviceHistoryData:(NSNumber *)error errorMessage:(NSString *)errorMessage data:(NSArray *)data;

@end

@interface XPGWifiSDK : NSObject

+ (XPGWifiSDK *)sharedInstance;
+ (void)startWithAppID:(NSString *)appID;

@property (nonatomic, assign) id <XPGWifiSDKDelegate>delegate;

/**
 * @brief 设置输出Log级别
 * @param level 日志级别。枚举值简介：
 * XPGWifiLogLevelNone       输出最多的日志内容
 * XPGWifiLogLevelInfo       输出信息、警告和错误
 * XPGWifiLogLevelWarning    只输出警告和错误
 * XPGWifiLogLevelError      只输出错误
 * @note 默认 level=XPGWifiLogLevelWarning
 * 仅在[XPGWifiSDK sharedInstance]后设置有效
 */
+ (void)setLogLevel:(XPGWifiLogLevel)level;

/**
 * @brief 设置输出Log文件。输出路径为/Documents
 * @param file：能访问到文件的相对路径
 * @note 默认不输出到文件
 * 仅在[XPGWifiSDK sharedInstance]后设置有效
 */
+ (void)setLogFile:(NSString *)file;

/**
 * @brief 设置内置的产品过滤
 * @param isEnabled：是否过滤
 * @note 在载入配置文件之前配置有效。默认Enabled
 */
+ (void)enableProductFilter:(BOOL)isEnabled;

/**
 * @brief 注册内置的产品过滤规则
 * @param productkey：允许的产品标识
 * @note 在载入配置文件之前配置有效。默认nil
 */
+ (void)registerProductKeys:(NSString *)productkey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * @brief 注册识别Soft AP模式的规则
 * @param ssidPrefix：识别SSID的前缀
 * @note 在载入配置文件之前配置有效。默认nil
 */
+ (void)registerSSIDs:(NSString *)ssidPrefix, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * @brief 设置输出二进制级别
 * @param isDebug=YES：  输出最多信息
 * @param isDebug=NO：   输出最少信息
 * @note 默认 isDebug=NO
 * 仅在[XPGWifiSDK sharedInstance]后设置有效
 */
+ (void)setPrintDataLevel:(BOOL)isDebug;

/**
 * @brief 设置配置文件的模式
 * @param isDebug=YES：  DEBUG模式
 * @param isDebug=NO：   RELEASE模式
 * @note 默认 isDebug=NO
 */
+ (void)setDebug:(BOOL)isDebug;

/**
 * @brief 设置服务器地址切换
 * @param isDebug=YES：  DEBUG服务器
 * @param isDebug=NO：   RELEASE服务器
 * @note 默认 isDebug=NO
 */
+ (void)setSwitchService:(BOOL)isDebug;

#ifdef __INTERNAL_LOG_CACHE__
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

/**
 * @brief 获取设备的配置
 * @param productKey：设备唯一标识符
 * @result 检查参数是否符合要求
 */
+ (void)updateDeviceFromServer:(NSString *)productKey;

/**
 * @brief 软AP模式下，配置上路由的方法
 * @param ssid：需要配置到路由的SSID名
 * @param key：需要配置到路由的密码
 */
- (BOOL)setSSID:(NSString *)ssid key:(NSString *)key;

/**
 * @brief 软AP模式下，获取设备搜索到的SSID列表
 */
- (void)getSSIDList;

/**
 * @brief 一键配置路由的方法
 * @param ssid：需要配置到路由的SSID名
 * @param key：需要配置到路由的密码
 */
- (BOOL)setAirLink:(NSString *)ssid key:(NSString *)key;

/**
 * @brief 请求向指定手机发送验证码
 * @param phone：手机号
 */
- (void)requestSendVerifyCode:(NSString *)phone;

/**
 * @brief 注册用户（通过用户名跟密码注册）
 * @param userName：注册用户名
 * @param password：注册密码
 */
- (void)registerUser:(NSString *)userName password:(NSString *)password;

/**
 * @brief 注册用户（通过手机号、密码跟校验码注册）
 * @param phone：注册手机号
 * @param password：注册密码
 * @param code：注册验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 */
- (void)registerUserByPhoneAndCode:(NSString *)phone password:(NSString *)password code:(NSString *)code;

/**
 * @brief 用户登录（匿名方式）
 */
- (void)userLoginAnonymous;

/**
 * @brief 用户登录（用户名密码方式）
 * @param szUserName：注册得到的用户名
 * @param szPassword：注册得到的密码
 */
- (void)userLoginWithUserName:(NSString *)szUserName password:(NSString *)szPassword;

/**
 * @brief 用户登录（第三方接口登录）
 * @param szThirdAccountType：第三方账户的类型
 * @param szUid：第三方账户的uid
 * @param szTocken：第三方账户的tocken
 */
- (void)userLoginWithThirdAccountType:(XPGWifiThirdAccountType)szThirdAccountType uid:(NSString *)szUid tocken:(NSString *)szTocken;

/**
 * @brief 用户注销
 * @param uid：登录成功后得到的uid
 */
- (void)userLogout:(NSString *)uid;

/**
 * @brief 将匿名用户转换为普通（非手机号）用户
 * @param tocken：匿名方式登录成功后得到的token
 * @param userName：待转换用户的用户名
 * @param password：待转换用户的密码
 */
- (void)transAnonymousUserToNormalUser:(NSString *)token userName:(NSString *)userName password:(NSString *)password;

/**
 * @brief 将匿名用户转换为手机号用户
 * @param tocken：匿名方式登录成功后得到的token
 * @param userName：待转换用户的手机号
 * @param password：待转换用户的密码
 * @param code：待转换用户的验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 */
- (void)transAnonymousUserToPhoneUser:(NSString *)token phone:(NSString *)phone password:(NSString *)password code:(NSString *)code;

/**
 * @brief 修改用户密码
 * @param tocken：登录成功后得到的token
 * @param oldPassword：之前的老密码
 * @param newPassword：需要修改的新密码
 */
- (void)changeUserPassword:(NSString *)token oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword;

/**
 * @brief 手机用户通过短信验证码重置密码
 * @param phone：手机号
 * @param code：短信验证码
 * @param newPassword：设置新密码
 */
- (void)changeUserPasswordByCode:(NSString *)phone code:(NSString *)code newPassword:(NSString *)newPassword;

/**
 * @brief 修改用户邮箱地址
 * @param tocken：登录成功后得到的token
 * @param email：指定需要修改成的邮箱地址
 */
- (void)changeUserEmail:(NSString *)token email:(NSString *)email;

/**
 * @brief 修改用户邮箱地址
 * @param tocken：登录成功后得到的token
 * @param phone：指定需要修改成的手机号
 * @param code：指定需要修改成的手机号收到验证码（通过requestSendVerifyCode方法触发指定手机号接收短信内的验证码）
 */
- (void)changeUserPhone:(NSString *)token phone:(NSString *)phone code:(NSString *)code;

/**
 * @brief 绑定设备到服务器
 * @param token：登录成功后得到的token
 * @param uid：登录成功后得到的uid
 * @param did：待绑定设备的did
 * @param passCode：待绑定设备的passCode
 */
- (void)bindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode;

/**
 * @brief 从服务器解绑设备
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param did：待解绑设备的did
 * @param passCode：待解绑设备的passCode
 */
- (void)unbindDeviceWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did passCode:(NSString *)passCode;

/**
 * @brief 获取绑定设备及本地设备列表
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 */
- (void)getBoundDevicesWithUid:(NSString *)uid token:(NSString *)token;

/**
 * @brief 获取指定设备的详细信息
 * @param uid：登录成功后得到的uid
 * @param token：登录成功后得到的token
 * @param did：指定设备的did
 */
- (void)getDeviceDetailInfoWithUid:(NSString *)uid token:(NSString *)token did:(NSString *)did;

/**
 * @brief 获取指定设备的历史数据
 * @param token：登录成功后得到的token
 * @param did：指定设备的did
 * @param startTS：指定开始时间戳
 * @param endTS：指定结束时间戳
 * @param entity：指定entity
 * @param attr：指定attr
 * @param limit：指定limit
 * @param skip：指定skip
 */
- (void)getDeviceHistoryData:(NSString *)token did:(NSString *)did startTS:(int)startTS endTS:(int)endTS entity:(int)entity attr:(int)attr limit:(int)limit skip:(int)skip;

@end
