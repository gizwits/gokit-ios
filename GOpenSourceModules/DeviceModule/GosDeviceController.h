//
//  GizDeviceController.h
//  GizOpenSourceKit
//
//  Created by Zono on 16/5/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GizWifiSDK/GizWifiSDK.h>
#import <GizWifiSDK/GizWifiDevice.h>

@interface GosDeviceController : UIViewController

- (id)initWithDevice:(GizWifiDevice *)device;

@end
