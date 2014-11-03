//
//  IoTAppDelegate.h
//  Gokit-demo
//
//  Created by xpg on 14/10/21.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <MBProgressHUD/MBProgressHUD.h>

typedef enum _IoTUserType
{
    IoTUserTypeAnonymous,       //匿名用户
    IoTUserTypeNormal,          //普通用户
    IoTUserTypeThird,           //第三方用户
}IoTUserType;

@interface IoTAppDelegate : UIResponder <UIApplicationDelegate, XPGWifiSDKDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navCtrl;

// 基本的用户数据
@property (strong, nonatomic) NSString *username;   //用户名
@property (strong, nonatomic) NSString *password;   //密码

// 用户 SESSION
@property (strong, nonatomic) NSString *uid;        //uid
@property (strong, nonatomic) NSString *token;      //token
@property (assign, nonatomic) IoTUserType userType; //用户类型，第三方用户 Demo App 不支持

@property (readonly, nonatomic) BOOL isRegisteredUser;  //匿名用户是否已注册

// 配置载入状态
@property (readonly, nonatomic) BOOL haveProductResult; //下载配置是否回调
@property (readonly, nonatomic) BOOL isLoadedProduct;   //是否已下载产品配置

// 弹出进度
@property (strong, nonatomic, readonly) MBProgressHUD *hud;

// 自动登录：普通用户优先，没有普通用户才自动登录匿名用户
- (void)userLogin;

// 助手函数：压缩大图片到指定的图片
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end

