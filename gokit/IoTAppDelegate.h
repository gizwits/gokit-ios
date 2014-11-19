/**
 * IoTAppDelegate.h
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <MBProgressHUD/MBProgressHUD.h>

typedef enum _IoTUserType
{
    IoTUserTypeAnonymous,       //匿名用户
    IoTUserTypeNormal,          //普通用户
    IoTUserTypeThird,           //第三方用户
}IoTUserType;

extern NSString * const IOT_PRODUCT;

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

// 弹出进度
@property (strong, nonatomic, readonly) MBProgressHUD *hud;

// 自动登录：普通用户优先，没有普通用户才自动登录匿名用户
- (void)userLogin;

// 助手函数：压缩大图片到指定的图片
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end

