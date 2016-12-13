//
//  ViewController.h
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GizWifiDevice;

@protocol GosConfigStartDelegate <NSObject>
@required

- (void)gosConfigDidFinished;
- (void)gosConfigDidSucceed:(GizWifiDevice *)device;

@end

@interface GosConfigStart : UIViewController

@property (assign, nonatomic) id <GosConfigStartDelegate>delegate;

@end

