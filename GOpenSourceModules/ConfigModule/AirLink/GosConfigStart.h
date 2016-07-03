//
//  ViewController.h
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GizWifiDevice;

@protocol GizConfigStartDelegate <NSObject>
@required

- (void)gizConfigDidFinished;
- (void)gizConfigDidSuccedd:(GizWifiDevice *)device;

@end

@interface GosConfigStart : UIViewController

@property (assign, nonatomic) id <GizConfigStartDelegate>delegate;

@end

