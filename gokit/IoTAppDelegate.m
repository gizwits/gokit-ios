//
//  AppDelegate.m
//  Gokit-demo
//
//  Created by xpg on 14/10/21.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTAppDelegate.h"
#import "IoTCheckConnection.h"

@interface IoTAppDelegate ()

@end

static NSString * const IOT_APPKEY = @"7ac10dec7dba436785ac23949536a6eb";
static NSString * const IOT_PRODUCT = @"6f3074fe43894547a4f1314bd7e3ae0b";//@"be606a7b34d441b59d7eba2c080ff805";

@implementation IoTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 网络状态跟踪
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];

    // 初始化 Wifi SDK
    [XPGWifiSDK startWithAppID:IOT_APPKEY];
    
    // 是否过滤指定 PRODUCT_KEY 的设备，NO 表示不过滤，会列出所有发现到的设备。如果 enableProductFilter 设置为 YES，且注册 ProductKeys，那么系统会从服务器自动下载一次配置。下载后，系统将通过 XPGWifiSDK:didUpdateProduct:result: 进行回调。
    [XPGWifiSDK enableProductFilter:YES];
    [XPGWifiSDK registerProductKeys:IOT_PRODUCT, nil];//注册并从服务器载入配置

    // 为 Soft AP 模式设置 SSID 名。如果没设置，默认值是 XPG-GAgent, XPG_GAgent
    [XPGWifiSDK registerSSIDs:@"XPG-GAgent", @"XPG_GAgent", nil];
    
    // 以下为调试开关
    [XPGWifiSDK setDebug:YES];
    
    [XPGWifiSDK setLogLevel:XPGWifiLogLevelAll];
    [XPGWifiSDK setLogFile:@"logfile.txt"]; // 日志输出到 App 的 Documents 目录
    [XPGWifiSDK setPrintDataLevel:YES]; // 打印收发包二进制数据

    // 设置 SDK Delegate
    [XPGWifiSDK sharedInstance].delegate = self;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 跳转到检查更新页面
    IoTCheckConnection *controller = [[IoTCheckConnection alloc] init];
    self.navCtrl = [[UINavigationController alloc] initWithRootViewController:controller];
    self.navCtrl.navigationBar.translucent = NO;
    self.window.rootViewController = self.navCtrl;

    [self.window makeKeyAndVisible];

    return YES;
}

#pragma mark - XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUpdateProduct:(NSString *)product result:(int)result
{
    if((result == 0 || result == 1) && [product isEqualToString:IOT_PRODUCT])
        _isLoadedProduct = YES;
    _haveProductResult = YES;
    NSLog(@"didUpdateProduct: %@ result: %i", product, result);
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    // 登录成功，自动设置相关信息
    NSLog(@"-----------------------> UserLogin result:%d", [error intValue]);
    if ([error intValue] || uid.length == 0 || token.length == 0) {
        NSLog(@"-----------------------> UserLogin errorMassage:%@", errorMessage);
    } else {
        NSLog(@"-----------------------> UserLogin uid:%@ token:%@", uid, token);
        AppDelegate.uid = uid;
        AppDelegate.token = token;
    }
}

#pragma mark - Properties
#define DefaultSetValue(key, value) \
[[NSUserDefaults standardUserDefaults] setValue:value forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];

#define DefaultGetValue(key) \
[[NSUserDefaults standardUserDefaults] valueForKey:key];

- (void)setUsername:(NSString *)username
{
    DefaultSetValue(@"username", username);
}

- (void)setPassword:(NSString *)password
{
    DefaultSetValue(@"password", password);
}

- (NSString *)username
{
    return DefaultGetValue(@"username")
}

- (NSString *)password
{
    return DefaultGetValue(@"password")
}

- (void)setUid:(NSString *)uid
{
    DefaultSetValue(@"uid", uid)
}

- (void)setUserType:(IoTUserType)userType
{
    DefaultSetValue(@"userType", @(userType))
}

- (void)setToken:(NSString *)token
{
    DefaultSetValue(@"token", token)
}

- (NSString *)uid
{
    return DefaultGetValue(@"uid")
}

- (NSString *)token
{
    return DefaultGetValue(@"token")
}

- (IoTUserType)userType
{
    NSNumber *nAnymous = DefaultGetValue(@"userType")
    if(nil != nAnymous)
        return (IoTUserType)[nAnymous intValue];
    return IoTUserTypeAnonymous;
}

- (BOOL)isRegisteredUser
{
    return (self.uid.length > 0 && self.token.length > 0);
}

#pragma mark - Other Common Functions
- (MBProgressHUD *)hud
{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.window];
    if(nil == hud)
    {
        hud = [[MBProgressHUD alloc] initWithView:self.window];
        [self.window addSubview:hud];
    }
    return hud;
}

- (void)userLogin
{
    switch (AppDelegate.userType) {
        case IoTUserTypeAnonymous:
            [[XPGWifiSDK sharedInstance] userLoginAnonymous];
            break;
        case IoTUserTypeNormal:
            [[XPGWifiSDK sharedInstance] userLoginWithUserName:AppDelegate.username password:AppDelegate.password];
            break;
        case IoTUserTypeThird:
            NSLog(@"Error: Third account type is not supported");
            break;
        default:
            NSLog(@"Error: invalid configure.");
            break;
    }
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Application Cycle
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.hud hide:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [XPGWifiSDK startWithAppID:IOT_APPKEY];
    [self.navCtrl popToRootViewControllerAnimated:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
