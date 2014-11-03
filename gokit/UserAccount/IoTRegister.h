//
//  IoTRegister.h
//  WiFiDemo-Debug
//
//  Created by xpg on 14-9-12.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiSDK.h>

@interface IoTRegister : UIViewController<UITextFieldDelegate, XPGWifiSDKDelegate>

//忘记密码模式，默认是注册模式
- (id)initWithForgetMode;

@end
