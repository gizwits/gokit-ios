//
//  IoTDeviceList.h
//  WiFiDemo
//
//  Created by xpg on 14-6-6.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiSDK.h>

@interface IoTDeviceList : UIViewController<UITableViewDataSource, UITableViewDelegate, XPGWifiSDKDelegate, XPGWifiDeviceDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@end
