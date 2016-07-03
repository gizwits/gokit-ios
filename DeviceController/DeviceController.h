//
//  GizDeviceController.h
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GizWifiSDK/GizWifiSDK.h>
#import <GizWifiSDK/GizWifiDevice.h>
#import "GizDeviceLabelCell.h"
#import "GizDeviceSliderCell.h"
#import "GizDeviceBoolCell.h"
#import "GizDeviceEnumCell.h"

@interface DeviceController : UIViewController<UITableViewDataSource, UITableViewDelegate, GizWifiSDKDelegate, GizWifiDeviceDelegate, GizDeviceSliderCellDelegate, GizDeviceBoolCellDelegate, GizDeviceEnumCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

- (id)initWithDevice:(GizWifiDevice *)device;

@end
