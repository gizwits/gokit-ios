//
//  IoTAddDeviceViewController.h
//  WiFiDemo
//
//  Created by xpg on 14-6-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiDevice.h>

@interface IoTAddDeviceViewController : UIViewController<XPGWifiDeviceDelegate, UIActionSheetDelegate, XPGWifiSDKDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

//device 优先
@property (nonatomic, assign) XPGWifiDevice *device;    //设备对象

//device is nil 才读取这里的值
@property (strong, nonatomic) NSString *did;            //设备 id
@property (strong, nonatomic) NSString *passcode;       //设备密码
@property (strong, nonatomic) NSString *productkey;     //设备产品标识

@end
