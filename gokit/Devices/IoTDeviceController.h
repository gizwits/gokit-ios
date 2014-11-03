//
//  IoTDeviceController.h
//  Gokit-demo
//
//  Created by xpg on 14/10/22.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XPGWifiSDK/XPGWifiDevice.h>
#import "IoTDeviceLabelCell.h"
#import "IoTDeviceSliderCell.h"
#import "IoTDeviceBoolCell.h"
#import "IoTDeviceEnumCell.h"

@interface IoTDeviceController : UIViewController<UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, XPGWifiSDKDelegate, XPGWifiDeviceDelegate, IoTDeviceSliderCellDelegate, IoTDeviceBoolCellDelegate, IoTDeviceEnumCellDelegate>

- (id)initWithDevice:(XPGWifiDevice *)device;

@end
