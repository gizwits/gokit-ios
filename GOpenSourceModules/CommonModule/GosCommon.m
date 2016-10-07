//
//  Common.m
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosCommon.h"
#import "GosConfigStart.h"
#import <CommonCrypto/CommonCrypto.h>

#define UIColorFromHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s &0xFF00) >>8))/255.0 blue:((s &0xFF))/255.0 alpha:1.0]

static NSString *ssidCacheKey = @"ssidKeyValuePairs";
static NSString *encryptKey = @"com.gizwits.gizwifisdk.commondata";

static NSData *AES256EncryptWithKey(NSString *key, NSData *data) {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

static NSData *AES256DecryptWithKey(NSString *key, NSData *data) {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

static NSString *makeEncryptKey(Class class, NSString *ssid) {
    NSString *tmpEncryptKey = NSStringFromClass(class);
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:@"_"];
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:ssid];
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:@"_"];
    
    unsigned char result[16] = { 0 };
    CC_MD5(tmpEncryptKey.UTF8String, (CC_LONG)tmpEncryptKey.length, result);
    NSString *ret = @"";
    
    for (int i=0; i<16; i++) {
        ret = [ret stringByAppendingFormat:@"%02X", result[i]];
    }
    
    return ret;
}

@implementation GosCommon

+ (instancetype)sharedInstance {
    static GosCommon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GosCommon alloc] __init];
    });
    return instance;
}

- (id)__init {
    self = [super init];
    if (self) {
        self.ssid = @"";
        self.uid = @"";
        self.token = @"";
        self.currentLoginStatus = GizLoginNone;
        self.airlinkConfigType = GizGAgentESP;
        self.cid = @"";
        self.configModuleValueArray = [[NSArray alloc] initWithObjects:@(0), @(1), @(2), @(3), @(4), @(5), @(6), @(7), @(8), @(9), nil];
        self.configModuleTextArray = [[NSArray alloc] initWithObjects:NSLocalizedString(@"MXCHIP", nil), NSLocalizedString(@"HF", nil), NSLocalizedString(@"RTK", nil), NSLocalizedString(@"WM", nil), NSLocalizedString(@"ESP", nil), NSLocalizedString(@"QCA", nil), NSLocalizedString(@"TI", nil), NSLocalizedString(@"FSK", nil), NSLocalizedString(@"MXCHIP3", nil), NSLocalizedString(@"BL", nil), nil];
        self.cloudDomainDict = [[NSMutableDictionary alloc] init];
        [self parseConfig];
    }
    return self;
}

- (NSMutableDictionary *)ssidKeyPairs {
    id obj = [[NSUserDefaults standardUserDefaults] valueForKey:ssidCacheKey];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionary];
    }
    return [obj mutableCopy];
}

- (void)setSsidKeyPairs:(NSDictionary *)dict {
    if ([dict isKindOfClass:[NSDictionary class]]) {
        [[NSUserDefaults standardUserDefaults] setValue:dict forKey:ssidCacheKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)saveSSID:(NSString *)ssid key:(NSString *)key {
    if (nil == ssid)  return;
    if (nil == key) {
        key = @"";
    }
    
    NSMutableDictionary *dict = [self ssidKeyPairs];
    NSString *tmpEncryptKey = makeEncryptKey([self class], ssid);
    NSData *encrypted = AES256EncryptWithKey(tmpEncryptKey, [key dataUsingEncoding:NSUTF8StringEncoding]);
    [dict setValue:encrypted forKey:ssid];
    [self setSsidKeyPairs:dict];
}

- (NSString *)getPasswrodFromSSID:(NSString *)ssid {
    if (nil == ssid) return @"";
    
    NSMutableDictionary *dict = [self ssidKeyPairs];
    NSData *encrypted = dict[ssid];
    if ([encrypted isKindOfClass:[NSData class]]) {
        NSString *tmpEncryptKey = makeEncryptKey([self class], ssid);
        NSData *data = AES256DecryptWithKey(tmpEncryptKey, encrypted);
        if (data) {
            NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([ret isKindOfClass:[NSString class]]) {
                return ret;
            }
        }
    }
    return @"";
}

- (void)onCancel {
    id <GizConfigStartDelegate>__delegate = self.delegate;
    [__delegate gizConfigDidFinished];
}

- (void)onSucceed:(GizWifiDevice *)device {
    id <GizConfigStartDelegate>__delegate = self.delegate;
    [__delegate gizConfigDidSuccedd:device];
}

- (void)showAlertCancelConfig:(id)delegate {
    self.cancelAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Discard your configuration?", nil) delegate:delegate cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [self.cancelAlertView show];
}

- (void)cancelAlertViewDismiss {
    [self.cancelAlertView dismissWithClickedButtonIndex:self.cancelAlertView.cancelButtonIndex animated:YES];
}

+ (BOOL)isMobileNumber:(NSString *)mobileNum
{
    if (mobileNum.length < 1) {
        return NO;
    }
    return YES;

    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
//    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\\\d{8}$";
//    NSString * MOBILE = @"^(13[0-9]|15[012356789]|17[0678]|18[0-9]|14[57])[0-9]{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188
     12         */
//    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\\\d)\\\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186
     17         */
//    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189
     22         */
//    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\\\d{3})\\\\d{7,8}$";
    
//    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
//    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
//    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
//    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
//    
//    if (([regextestmobile evaluateWithObject:mobileNum] == YES)
//        || ([regextestcm evaluateWithObject:mobileNum] == YES)
//        || ([regextestct evaluateWithObject:mobileNum] == YES)
//        || ([regextestcu evaluateWithObject:mobileNum] == YES))
//    {
//        return YES;
//    }
//    else
//    {
//        return NO;
//    }
}

- (void)saveUserDefaults:(NSString *)username password:(NSString *)password uid:(NSString *)uid token:(NSString *)token {
    if (username) [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
    if (password) [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
//    if (uid) [[NSUserDefaults standardUserDefaults] setObject:uid forKey:@"uid"];
//    if (token) [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
    if (uid) self.uid = uid;
    if (token) self.token = token;
    [[NSUserDefaults standardUserDefaults] synchronize];
//    self.isLogin = YES;
}

- (void)removeUserDefaults {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    self.uid = @"";
    self.token = @"";
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"uid"];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"token"];
    [[NSUserDefaults standardUserDefaults] synchronize];
//    self.isLogin = NO;
}

- (void)parseConfig {
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"UIConfig" ofType:@"json"];
    if (jsonPath) {
        NSData *configContent = [NSData dataWithContentsOfFile:jsonPath];
//        NSString *configContent = [NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
//        NSLog(@"string1 ========= %@", configContent);
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:configContent options:NSJSONReadingMutableContainers error:nil];
        if (jsonObject) {
            self.appID = [jsonObject objectForKey:@"app_id"];
            self.appSecret = [jsonObject objectForKey:@"app_secret"];
//            self.productKey = ([[jsonObject objectForKey:@"product_key"] count] > 0 ? [jsonObject objectForKey:@"product_key"] : nil);
            self.productKey = nil;
            if ([[jsonObject objectForKey:@"product_key"] count] > 0) {
                NSString *pk = [[jsonObject objectForKey:@"product_key"] objectAtIndex:0];
                if (pk.length > 0 && ![pk isEqualToString:@"your_product_key"]) self.productKey = [jsonObject objectForKey:@"product_key"];
            }
            self.moduleSelectOn = [[jsonObject objectForKey:@"wifi_type_select"] boolValue];
            self.tencentAppID = [jsonObject objectForKey:@"tencent_app_id"];
            self.wechatAppID = [jsonObject objectForKey:@"wechat_app_id"];
            self.wechatAppSecret = [jsonObject objectForKey:@"wechat_app_secret"];
            self.pushType = [[jsonObject objectForKey:@"push_type"] integerValue];
            self.jpushAppKey = [jsonObject objectForKey:@"jpush_app_key"];
            self.bpushAppKey = [jsonObject objectForKey:@"bpush_app_key"];
            
            [self parseCloudDomain:[jsonObject objectForKey:@"openAPI_URL"] domainKey:@"openAPIDomain" portKey:@"openAPIPort"];
            [self parseCloudDomain:[jsonObject objectForKey:@"site_URL"] domainKey:@"siteDomain" portKey:@"sitePort"];
            [self parseCloudDomain:[jsonObject objectForKey:@"push_URL"] domainKey:@"pushDomain" portKey:@"pushPort"];
            
//            unsigned long red = strtoul([@"0x6587" UTF8String],0,0);
            self.buttonColor = UIColorFromHex(strtoul([[jsonObject objectForKey:@"buttonColor"] UTF8String],0,16));
            self.buttonTextColor = UIColorFromHex(strtoul([[jsonObject objectForKey:@"buttonTextColor"] UTF8String],0,16));
            self.navigationBarColor = UIColorFromHex(strtoul([[jsonObject objectForKey:@"navigationBarColor"] UTF8String],0,16));
            self.navigationBarTextColor = UIColorFromHex(strtoul([[jsonObject objectForKey:@"navigationBarTextColor"] UTF8String],0,16));
            self.configProgressViewColor = UIColorFromHex(strtoul([[jsonObject objectForKey:@"configProgressViewColor"] UTF8String],0,16));
            self.statusBarStyle = [[jsonObject objectForKey:@"statusBarStyle"] integerValue];
            self.addDeviceTitle = [jsonObject objectForKey:@"addDeviceTitle"];
            
//            self.buttonColor = [UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1];
//            self.buttonTextColor = [UIColor blackColor];
//            self.navigationBarColor = [UIColor blackColor];
//            self.navigationBarTextColor = [UIColor whiteColor];
//            self.configProgressViewColor = [UIColor colorWithRed:243/255.0 green:212/255.0 blue:29/255.0 alpha:1];
//            self.statusBarStyle = UIStatusBarStyleLightContent;
//            self.addDeviceTitle = @"添加设备";
            
        }
        else {
            [[GosCommon sharedInstance] showAlert:@"配置文件解析失败" disappear:YES];
            [self loadDefaultConfig];
        }
    }
    else {
        [[GosCommon sharedInstance] showAlert:@"配置文件不存在" disappear:YES];
        [self loadDefaultConfig];
    }
    
//    self.buttonColor = [UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1];
//    self.buttonTextColor = [UIColor blackColor];
//    self.configProgressViewColor = [UIColor colorWithRed:243/255.0 green:212/255.0 blue:29/255.0 alpha:1];
//    self.navigationBarColor = [UIColor blackColor];
//    self.navigationBarTextColor = [UIColor whiteColor];
//    self.statusBarStyle = UIStatusBarStyleLightContent;
//    self.addDeviceTitle = @"添加gokit";
}

- (void)parseCloudDomain:(NSString *)url domainKey:(NSString *)domainKey portKey:(NSString *)portKey {
    if (url) {
        if (url.length > 0) {
            NSArray *arr = [url componentsSeparatedByString:@":"];
            NSString *domain = @"";
            NSString *port = @"80";
            if ([arr count] == 2) {
                domain = [arr objectAtIndex:0];
                port = [arr objectAtIndex:1];
            }
            else if ([arr count] == 1) {
                domain = [arr objectAtIndex:0];
            }
            else {
                return;
            }
            [self.cloudDomainDict setObject:domain forKey:domainKey];
            [self.cloudDomainDict setObject:port forKey:portKey];
        }
    }
}

- (void)loadDefaultConfig {
    self.buttonColor = [UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1];
    self.buttonTextColor = [UIColor blackColor];
    self.navigationBarColor = [UIColor whiteColor];
    self.navigationBarTextColor = [UIColor blackColor];
    self.configProgressViewColor = [UIColor colorWithRed:243/255.0 green:212/255.0 blue:29/255.0 alpha:1];
    self.statusBarStyle = UIStatusBarStyleDefault;
    self.addDeviceTitle = @"添加设备";
}

- (NSString *)checkErrorCode:(GizWifiErrorCode)errorCode {
    switch (errorCode) {
        case GIZ_SDK_PARAM_FORM_INVALID:
            return NSLocalizedString(@"GIZ_SDK_PARAM_FORM_INVALID", nil);
            break;
        case GIZ_SDK_CLIENT_NOT_AUTHEN:
            return NSLocalizedString(@"GIZ_SDK_CLIENT_NOT_AUTHEN", nil);
            break;
        case GIZ_SDK_CLIENT_VERSION_INVALID:
            return NSLocalizedString(@"GIZ_SDK_CLIENT_VERSION_INVALID", nil);
            break;
        case GIZ_SDK_UDP_PORT_BIND_FAILED:
            return NSLocalizedString(@"GIZ_SDK_UDP_PORT_BIND_FAILED", nil);
            break;
        case GIZ_SDK_DAEMON_EXCEPTION:
            return NSLocalizedString(@"GIZ_SDK_DAEMON_EXCEPTION", nil);
            break;
        case GIZ_SDK_PARAM_INVALID:
            return NSLocalizedString(@"GIZ_SDK_PARAM_INVALID", nil);
            break;
        case GIZ_SDK_APPID_LENGTH_ERROR:
            return NSLocalizedString(@"GIZ_SDK_APPID_LENGTH_ERROR", nil);
            break;
        case GIZ_SDK_LOG_PATH_INVALID:
            return NSLocalizedString(@"GIZ_SDK_LOG_PATH_INVALID", nil);
            break;
        case GIZ_SDK_LOG_LEVEL_INVALID:
            return NSLocalizedString(@"GIZ_SDK_LOG_LEVEL_INVALID", nil);
            break;
        case GIZ_SDK_DEVICE_CONFIG_SEND_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_SEND_FAILED", nil);
            break;
        case GIZ_SDK_DEVICE_CONFIG_IS_RUNNING:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_IS_RUNNING", nil);
            break;
        case GIZ_SDK_DEVICE_CONFIG_TIMEOUT:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_TIMEOUT", nil);
            break;
        case GIZ_SDK_DEVICE_DID_INVALID:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_DID_INVALID", nil);
            break;
        case GIZ_SDK_DEVICE_MAC_INVALID:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_MAC_INVALID", nil);
            break;
        case GIZ_SDK_SUBDEVICE_DID_INVALID:
            return NSLocalizedString(@"GIZ_SDK_SUBDEVICE_DID_INVALID", nil);
            break;
        case GIZ_SDK_DEVICE_PASSCODE_INVALID:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_PASSCODE_INVALID", nil);
            break;
        case GIZ_SDK_DEVICE_NOT_SUBSCRIBED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_SUBSCRIBED", nil);
            break;
        case GIZ_SDK_DEVICE_NO_RESPONSE:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_NO_RESPONSE", nil);
            break;
        case GIZ_SDK_DEVICE_NOT_READY:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_READY", nil);
            break;
        case GIZ_SDK_DEVICE_NOT_BINDED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_BINDED", nil);
            break;
        case GIZ_SDK_DEVICE_CONTROL_WITH_INVALID_COMMAND:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_WITH_INVALID_COMMAND", nil);
            break;
        case GIZ_SDK_DEVICE_CONTROL_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_FAILED", nil);
            break;
        case GIZ_SDK_DEVICE_GET_STATUS_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_GET_STATUS_FAILED", nil);
            break;
        case GIZ_SDK_DEVICE_CONTROL_VALUE_TYPE_ERROR:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_VALUE_TYPE_ERROR", nil);
            break;
        case GIZ_SDK_DEVICE_CONTROL_VALUE_OUT_OF_RANGE:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_VALUE_OUT_OF_RANGE", nil);
            break;
        case GIZ_SDK_DEVICE_CONTROL_NOT_WRITABLE_COMMAND:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_NOT_WRITABLE_COMMAND", nil);
            break;
        case GIZ_SDK_BIND_DEVICE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_BIND_DEVICE_FAILED", nil);
            break;
        case GIZ_SDK_UNBIND_DEVICE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_UNBIND_DEVICE_FAILED", nil);
            break;
        case GIZ_SDK_DNS_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DNS_FAILED", nil);
            break;
        case GIZ_SDK_M2M_CONNECTION_SUCCESS:
            return NSLocalizedString(@"GIZ_SDK_M2M_CONNECTION_SUCCESS", nil);
            break;
        case GIZ_SDK_SET_SOCKET_NON_BLOCK_FAILED:
            return NSLocalizedString(@"GIZ_SDK_SET_SOCKET_NON_BLOCK_FAILED", nil);
            break;
        case GIZ_SDK_CONNECTION_TIMEOUT:
            return NSLocalizedString(@"GIZ_SDK_CONNECTION_TIMEOUT", nil);
            break;
        case GIZ_SDK_CONNECTION_REFUSED:
            return NSLocalizedString(@"GIZ_SDK_CONNECTION_REFUSED", nil);
            break;
        case GIZ_SDK_CONNECTION_ERROR:
            return NSLocalizedString(@"GIZ_SDK_CONNECTION_ERROR", nil);
            break;
        case GIZ_SDK_CONNECTION_CLOSED:
            return NSLocalizedString(@"GIZ_SDK_CONNECTION_CLOSED", nil);
            break;
        case GIZ_SDK_SSL_HANDSHAKE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_SSL_HANDSHAKE_FAILED", nil);
            break;
        case GIZ_SDK_DEVICE_LOGIN_VERIFY_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_LOGIN_VERIFY_FAILED", nil);
            break;
        case GIZ_SDK_INTERNET_NOT_REACHABLE:
            return NSLocalizedString(@"GIZ_SDK_INTERNET_NOT_REACHABLE", nil);
            break;
        case GIZ_SDK_HTTP_ANSWER_FORMAT_ERROR:
            return NSLocalizedString(@"GIZ_SDK_HTTP_ANSWER_FORMAT_ERROR", nil);
            break;
        case GIZ_SDK_HTTP_ANSWER_PARAM_ERROR:
            return NSLocalizedString(@"GIZ_SDK_HTTP_ANSWER_PARAM_ERROR", nil);
            break;
        case GIZ_SDK_HTTP_SERVER_NO_ANSWER:
            return NSLocalizedString(@"GIZ_SDK_HTTP_SERVER_NO_ANSWER", nil);
            break;
        case GIZ_SDK_HTTP_REQUEST_FAILED:
            return NSLocalizedString(@"GIZ_SDK_HTTP_REQUEST_FAILED", nil);
            break;
        case GIZ_SDK_OTHERWISE:
            return NSLocalizedString(@"GIZ_SDK_OTHERWISE", nil);
            break;
        case GIZ_SDK_MEMORY_MALLOC_FAILED:
            return NSLocalizedString(@"GIZ_SDK_MEMORY_MALLOC_FAILED", nil);
            break;
        case GIZ_SDK_THREAD_CREATE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_THREAD_CREATE_FAILED", nil);
            break;
        case GIZ_SDK_USER_ID_INVALID:
            return NSLocalizedString(@"GIZ_SDK_USER_ID_INVALID", nil);
            break;
        case GIZ_SDK_TOKEN_INVALID:
            return NSLocalizedString(@"GIZ_SDK_TOKEN_INVALID", nil);
            break;
        case GIZ_SDK_GROUP_ID_INVALID:
            return NSLocalizedString(@"GIZ_SDK_GROUP_ID_INVALID", nil);
            break;
        case GIZ_SDK_GROUPNAME_INVALID:
            return NSLocalizedString(@"GIZ_SDK_GROUPNAME_INVALID", nil);
            break;
        case GIZ_SDK_GROUP_PRODUCTKEY_INVALID:
            return NSLocalizedString(@"GIZ_SDK_GROUP_PRODUCTKEY_INVALID", nil);
            break;
        case GIZ_SDK_GROUP_FAILED_DELETE_DEVICE:
            return NSLocalizedString(@"GIZ_SDK_GROUP_FAILED_DELETE_DEVICE", nil);
            break;
        case GIZ_SDK_GROUP_FAILED_ADD_DEVICE:
            return NSLocalizedString(@"GIZ_SDK_GROUP_FAILED_ADD_DEVICE", nil);
            break;
        case GIZ_SDK_GROUP_GET_DEVICE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_GROUP_GET_DEVICE_FAILED", nil);
            break;
        case GIZ_SDK_DATAPOINT_NOT_DOWNLOAD:
            return NSLocalizedString(@"GIZ_SDK_DATAPOINT_NOT_DOWNLOAD", nil);
            break;
        case GIZ_SDK_DATAPOINT_SERVICE_UNAVAILABLE:
            return NSLocalizedString(@"GIZ_SDK_DATAPOINT_SERVICE_UNAVAILABLE", nil);
            break;
        case GIZ_SDK_DATAPOINT_PARSE_FAILED:
            return NSLocalizedString(@"GIZ_SDK_DATAPOINT_PARSE_FAILED", nil);
            break;
        case GIZ_SDK_NOT_INITIALIZED:
            return NSLocalizedString(@"GIZ_SDK_SDK_NOT_INITIALIZED", nil);
            break;
//        case GIZ_SDK_APK_CONTEXT_IS_NULL:
//            return NSLocalizedString(@"GIZ_SDK_APK_CONTEXT_IS_NULL", nil);
//            break;
//        case GIZ_SDK_APK_PERMISSION_NOT_SET:
//            return NSLocalizedString(@"GIZ_SDK_APK_PERMISSION_NOT_SET", nil);
//            break;
//        case GIZ_SDK_CHMOD_DAEMON_REFUSED:
//            return NSLocalizedString(@"GIZ_SDK_CHMOD_DAEMON_REFUSED", nil);
//            break;
        case GIZ_SDK_EXEC_DAEMON_FAILED:
            return NSLocalizedString(@"GIZ_SDK_EXEC_DAEMON_FAILED", nil);
            break;
        case GIZ_SDK_EXEC_CATCH_EXCEPTION:
            return NSLocalizedString(@"GIZ_SDK_EXEC_CATCH_EXCEPTION", nil);
            break;
        case GIZ_SDK_APPID_IS_EMPTY:
            return NSLocalizedString(@"GIZ_SDK_APPID_IS_EMPTY", nil);
            break;
        case GIZ_SDK_UNSUPPORTED_API:
            return NSLocalizedString(@"GIZ_SDK_UNSUPPORTED_API", nil);
            break;
        case GIZ_SDK_REQUEST_TIMEOUT:
            return NSLocalizedString(@"GIZ_SDK_REQUEST_TIMEOUT", nil);
            break;
        case GIZ_SDK_DAEMON_VERSION_INVALID:
            return NSLocalizedString(@"GIZ_SDK_DAEMON_VERSION_INVALID", nil);
            break;
        case GIZ_SDK_PHONE_NOT_CONNECT_TO_SOFTAP_SSID:
            return NSLocalizedString(@"GIZ_SDK_PHONE_NOT_CONNECT_TO_SOFTAP_SSID", nil);
            break;
        case GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED:
            return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED", nil);
            break;
        case GIZ_SDK_NOT_IN_SOFTAPMODE:
            return NSLocalizedString(@"GIZ_SDK_NOT_IN_SOFTAPMODE", nil);
            break;
        case GIZ_SDK_PHONE_WIFI_IS_UNAVAILABLE:
            return NSLocalizedString(@"GIZ_SDK_PHONE_WIFI_IS_UNAVAILABLE", nil);
            break;
        case GIZ_SDK_RAW_DATA_TRANSMIT:
            return NSLocalizedString(@"GIZ_SDK_RAW_DATA_TRANSMIT", nil);
            break;
        case GIZ_SDK_PRODUCT_IS_DOWNLOADING:
            return NSLocalizedString(@"GIZ_SDK_PRODUCT_IS_DOWNLOADING", nil);
            break;
        case GIZ_SDK_START_SUCCESS:
            return NSLocalizedString(@"GIZ_SDK_START_SUCCESS", nil);
            break;
        case GIZ_SITE_PRODUCTKEY_INVALID:
            return NSLocalizedString(@"GIZ_SITE_PRODUCTKEY_INVALID", nil);
            break;
        case GIZ_SITE_DATAPOINTS_NOT_DEFINED:
            return NSLocalizedString(@"GIZ_SITE_DATAPOINTS_NOT_DEFINED", nil);
            break;
        case GIZ_SITE_DATAPOINTS_NOT_MALFORME:
            return NSLocalizedString(@"GIZ_SITE_DATAPOINTS_NOT_MALFORME", nil);
            break;
        case GIZ_OPENAPI_MAC_ALREADY_REGISTERED:
            return NSLocalizedString(@"GIZ_OPENAPI_MAC_ALREADY_REGISTERED", nil);
            break;
        case GIZ_OPENAPI_PRODUCT_KEY_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_PRODUCT_KEY_INVALID", nil);
            break;
        case GIZ_OPENAPI_APPID_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_APPID_INVALID", nil);
            break;
        case GIZ_OPENAPI_TOKEN_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_TOKEN_INVALID", nil);
            break;
        case GIZ_OPENAPI_USER_NOT_EXIST:
            return NSLocalizedString(@"GIZ_OPENAPI_USER_NOT_EXIST", nil);
            break;
        case GIZ_OPENAPI_TOKEN_EXPIRED:
            return NSLocalizedString(@"GIZ_OPENAPI_TOKEN_EXPIRED", nil);
            break;
        case GIZ_OPENAPI_M2M_ID_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_M2M_ID_INVALID", nil);
            break;
        case GIZ_OPENAPI_SERVER_ERROR:
            return NSLocalizedString(@"GIZ_OPENAPI_SERVER_ERROR", nil);
            break;
        case GIZ_OPENAPI_CODE_EXPIRED:
            return NSLocalizedString(@"GIZ_OPENAPI_CODE_EXPIRED", nil);
            break;
        case GIZ_OPENAPI_CODE_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_CODE_INVALID", nil);
            break;
        case GIZ_OPENAPI_SANDBOX_SCALE_QUOTA_EXHAUSTED:
            return NSLocalizedString(@"GIZ_OPENAPI_SANDBOX_SCALE_QUOTA_EXHAUSTED", nil);
            break;
        case GIZ_OPENAPI_PRODUCTION_SCALE_QUOTA_EXHAUSTED:
            return NSLocalizedString(@"GIZ_OPENAPI_PRODUCTION_SCALE_QUOTA_EXHAUSTED", nil);
            break;
        case GIZ_OPENAPI_PRODUCT_HAS_NO_REQUEST_SCALE:
            return NSLocalizedString(@"GIZ_OPENAPI_PRODUCT_HAS_NO_REQUEST_SCALE", nil);
            break;
        case GIZ_OPENAPI_DEVICE_NOT_FOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_NOT_FOUND", nil);
            break;
        case GIZ_OPENAPI_FORM_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_FORM_INVALID", nil);
            break;
        case GIZ_OPENAPI_DID_PASSCODE_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_DID_PASSCODE_INVALID", nil);
            break;
        case GIZ_OPENAPI_DEVICE_NOT_BOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_NOT_BOUND", nil);
            break;
        case GIZ_OPENAPI_PHONE_UNAVALIABLE:
            return NSLocalizedString(@"GIZ_OPENAPI_PHONE_UNAVALIABLE", nil);
            break;
        case GIZ_OPENAPI_USERNAME_UNAVALIABLE:
            return NSLocalizedString(@"GIZ_OPENAPI_USERNAME_UNAVALIABLE", nil);
            break;
        case GIZ_OPENAPI_USERNAME_PASSWORD_ERROR:
            return NSLocalizedString(@"GIZ_OPENAPI_USERNAME_PASSWORD_ERROR", nil);
            break;
        case GIZ_OPENAPI_SEND_COMMAND_FAILED:
            return NSLocalizedString(@"GIZ_OPENAPI_SEND_COMMAND_FAILED", nil);
            break;
        case GIZ_OPENAPI_EMAIL_UNAVALIABLE:
            return NSLocalizedString(@"GIZ_OPENAPI_EMAIL_UNAVALIABLE", nil);
            break;
        case GIZ_OPENAPI_DEVICE_DISABLED:
            return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_DISABLED", nil);
            break;
        case GIZ_OPENAPI_FAILED_NOTIFY_M2M:
            return NSLocalizedString(@"GIZ_OPENAPI_FAILED_NOTIFY_M2M", nil);
            break;
        case GIZ_OPENAPI_ATTR_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_ATTR_INVALID", nil);
            break;
        case GIZ_OPENAPI_USER_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_USER_INVALID", nil);
            break;
        case GIZ_OPENAPI_FIRMWARE_NOT_FOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_FIRMWARE_NOT_FOUND", nil);
            break;
        case GIZ_OPENAPI_JD_PRODUCT_NOT_FOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_JD_PRODUCT_NOT_FOUND", nil);
            break;
        case GIZ_OPENAPI_DATAPOINT_DATA_NOT_FOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_DATAPOINT_DATA_NOT_FOUND", nil);
            break;
        case GIZ_OPENAPI_SCHEDULER_NOT_FOUND:
            return NSLocalizedString(@"GIZ_OPENAPI_SCHEDULER_NOT_FOUND", nil);
            break;
        case GIZ_OPENAPI_QQ_OAUTH_KEY_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_QQ_OAUTH_KEY_INVALID", nil);
            break;
        case GIZ_OPENAPI_OTA_SERVICE_OK_BUT_IN_IDLE:
            return NSLocalizedString(@"GIZ_OPENAPI_OTA_SERVICE_OK_BUT_IN_IDLE", nil);
            break;
        case GIZ_OPENAPI_BT_FIRMWARE_UNVERIFIED:
            return NSLocalizedString(@"GIZ_OPENAPI_BT_FIRMWARE_UNVERIFIED", nil);
            break;
        case GIZ_OPENAPI_BT_FIRMWARE_NOTHING_TO_UPGRADE:
            return NSLocalizedString(@"GIZ_OPENAPI_SAVE_KAIROSDB_ERROR", nil);
            break;
        case GIZ_OPENAPI_SAVE_KAIROSDB_ERROR:
            return NSLocalizedString(@"GIZ_OPENAPI_SAVE_KAIROSDB_ERROR", nil);
            break;
        case GIZ_OPENAPI_EVENT_NOT_DEFINED:
            return NSLocalizedString(@"GIZ_OPENAPI_EVENT_NOT_DEFINED", nil);
            break;
        case GIZ_OPENAPI_SEND_SMS_FAILED:
            return NSLocalizedString(@"GIZ_OPENAPI_SEND_SMS_FAILED", nil);
            break;
        case GIZ_OPENAPI_APPLICATION_AUTH_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_APPLICATION_AUTH_INVALID", nil);
            break;
        case GIZ_OPENAPI_NOT_ALLOWED_CALL_API:
            return NSLocalizedString(@"GIZ_OPENAPI_NOT_ALLOWED_CALL_API", nil);
            break;
        case GIZ_OPENAPI_BAD_QRCODE_CONTENT:
            return NSLocalizedString(@"GIZ_OPENAPI_BAD_QRCODE_CONTENT", nil);
            break;
        case GIZ_OPENAPI_REQUEST_THROTTLED:
            return NSLocalizedString(@"GIZ_OPENAPI_REQUEST_THROTTLED", nil);
            break;
        case GIZ_OPENAPI_DEVICE_OFFLINE:
            return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_OFFLINE", nil);
            break;
        case GIZ_OPENAPI_TIMESTAMP_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_TIMESTAMP_INVALID", nil);
            break;
        case GIZ_OPENAPI_SIGNATURE_INVALID:
            return NSLocalizedString(@"GIZ_OPENAPI_SIGNATURE_INVALID", nil);
            break;
        case GIZ_OPENAPI_DEPRECATED_API:
            return NSLocalizedString(@"GIZ_OPENAPI_DEPRECATED_API", nil);
            break;
        case GIZ_OPENAPI_RESERVED:
            return NSLocalizedString(@"GIZ_OPENAPI_RESERVED", nil);
            break;
        case GIZ_PUSHAPI_BODY_JSON_INVALID:
            return NSLocalizedString(@"GIZ_PUSHAPI_BODY_JSON_INVALID", nil);
            break;
        case GIZ_PUSHAPI_DATA_NOT_EXIST:
            return NSLocalizedString(@"GIZ_PUSHAPI_DATA_NOT_EXIST", nil);
            break;
        case GIZ_PUSHAPI_NO_CLIENT_CONFIG:
            return NSLocalizedString(@"GIZ_PUSHAPI_NO_CLIENT_CONFIG", nil);
            break;
        case GIZ_PUSHAPI_NO_SERVER_DATA:
            return NSLocalizedString(@"GIZ_PUSHAPI_NO_SERVER_DATA", nil);
            break;
        case GIZ_PUSHAPI_GIZWITS_APPID_EXIST:
            return NSLocalizedString(@"GIZ_PUSHAPI_GIZWITS_APPID_EXIST", nil);
            break;
        case GIZ_PUSHAPI_PARAM_ERROR:
            return NSLocalizedString(@"GIZ_PUSHAPI_PARAM_ERROR", nil);
            break;
        case GIZ_PUSHAPI_AUTH_KEY_INVALID:
            return NSLocalizedString(@"GIZ_PUSHAPI_AUTH_KEY_INVALID", nil);
            break;
        case GIZ_PUSHAPI_APPID_OR_TOKEN_ERROR:
            return NSLocalizedString(@"GIZ_PUSHAPI_APPID_OR_TOKEN_ERROR", nil);
            break;
        case GIZ_PUSHAPI_TYPE_PARAM_ERROR:
            return NSLocalizedString(@"GIZ_PUSHAPI_TYPE_PARAM_ERROR", nil);
            break;
        case GIZ_PUSHAPI_ID_PARAM_ERROR:
            return NSLocalizedString(@"GIZ_PUSHAPI_ID_PARAM_ERROR", nil);
            break;
        case GIZ_PUSHAPI_APPKEY_SECRETKEY_INVALID:
            return NSLocalizedString(@"GIZ_PUSHAPI_APPKEY_SECRETKEY_INVALID", nil);
            break;
        case GIZ_PUSHAPI_CHANNELID_ERROR_INVALID:
            return NSLocalizedString(@"GIZ_PUSHAPI_CHANNELID_ERROR_INVALID", nil);
            break;
        case GIZ_PUSHAPI_PUSH_ERROR:
            return NSLocalizedString(@"GIZ_PUSHAPI_PUSH_ERROR", nil);
            break;
        default:
            return NSLocalizedString(@"UNKNOWN_ERROR", nil);
            break;
    }
}

- (void)showAlert:(NSString *)message disappear:(BOOL)disappear {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:!disappear?NSLocalizedString(@"OK", nil):nil otherButtonTitles:nil, nil];
    [alert show];
    if (disappear) {
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
        });
    }
}

//- (GizLoginStatus)currentLoginStatus {
//    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
//    if (self.uid && self.uid.length > 0) {
//        if (username && username.length > 0) {
//            return GizLoginUser;
//        }
//        else {
//            return GizLoginAnonymous;
//        }
//    }
//    return GizLoginNone;
//}

/*
- (void)showHUD:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:YES];
    [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 75.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.mode = MBProgressHUDModeCustomView;
//            UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//            hud.customView = [[UIImageView alloc] initWithImage:image];
            hud.square = YES;
            hud.label.text = NSLocalizedString(@"操作超时", @"HUD done title");
            [hud hideAnimated:YES afterDelay:2.f];
        });
        
    });
 
}

- (void)hideHUD:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:YES];
}
*/
@end

id GetControllerWithClass(Class class, UITableView *tableView, NSString *reuseIndentifer) {
    if ([class isSubclassOfClass:[UITableViewCell class]]) {
        UINib *nib = [UINib nibWithNibName:NSStringFromClass(class) bundle:nil];
        if(nib) {
            [tableView registerNib:nib forCellReuseIdentifier:reuseIndentifer];
            return [tableView dequeueReusableCellWithIdentifier:reuseIndentifer];
        }
    }
    return nil;
}