//
//  IoTRegisterProcessModel.h
//  WiFiDemo
//
//  Created by ChaoSo on 15/9/17.
//  Copyright (c) 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IoTRegisterProcessModel : NSObject
+ (IoTRegisterProcessModel *)sharedModel;
-(void)removeAllData;

@property (strong, nonatomic) NSString *validateToken;
@property (strong, nonatomic) NSString *validateSendPhone;
@property (strong, nonatomic) NSString *verifyCode;
@property (strong, nonatomic) NSString *validateCaptchaId;
@property (assign, nonatomic) BOOL isForget;
@end
