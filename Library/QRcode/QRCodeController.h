//
//  QRCodeController.h
//  eCarry
//
//  Created by whde on 15/8/14.
//  Copyright (c) 2015年 Joybon. All rights reserved.
//

#import <UIKit/UIKit.h>
#define IS_VAILABLE_IOS8  ([[[UIDevice currentDevice] systemVersion] intValue] >= 8)

@interface QRCodeController : UIViewController
typedef void (^QRCodeDidCancelBlock)();
typedef void (^QRCodeDidReceiveBlock)(NSString *result);
@property (nonatomic, copy, readonly) QRCodeDidCancelBlock didCancelBlock;
@property (nonatomic, copy, readonly) QRCodeDidReceiveBlock didReceiveBlock;
- (void)setDidCancelBlock:(QRCodeDidCancelBlock)didCancelBlock;
- (void)setDidReceiveBlock:(QRCodeDidReceiveBlock)didReceiveBlock;
@end