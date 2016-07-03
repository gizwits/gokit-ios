//
//  GizSoftAPDetection.h
//  DeviceConfigDemo
//
//  Created by GeHaitong on 16/1/12.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GizSoftAPDetectionDelegate <NSObject>
@required

- (BOOL)didSoftAPModeDetected:(NSString *)ssid;

@end

@interface GosSoftAPDetection : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSoftAPSSID:(NSString *)ssidPrefix delegate:(id <GizSoftAPDetectionDelegate>)delegate;

@end
