//
//  IoTRegisterProcessModel.m
//  WiFiDemo
//
//  Created by ChaoSo on 15/9/17.
//  Copyright (c) 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTRegisterProcessModel.h"

@implementation IoTRegisterProcessModel
static IoTRegisterProcessModel *sharedModel = nil;
+ (IoTRegisterProcessModel *)sharedModel
{
    if(nil == sharedModel)
    {
        sharedModel = [[IoTRegisterProcessModel alloc] init];
    }
    return sharedModel;
}

-(void)removeAllData
{
    self.validateCaptchaId = @"";
    self.validateSendPhone = @"";
    self.validateToken = @"";
    self.verifyCode = @"";
    self.isForget = NO;
}
@end
