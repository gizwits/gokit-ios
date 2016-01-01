//
//  XPGUserInfo.h
//  XPGWifiSDK
//
//  Created by GeHaitong on 15/10/27.
//  Copyright © 2015年 xpg. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 性别类型
 */
typedef NS_ENUM(NSInteger, XPGUserGenderType)
{
    /**
     男性
     */
    Male = 0,
    /**
     女性
     */
    Female = 1,
    /**
     其他或者未设置
     */
    Unknown = 2,
};

@interface XPGUserInfo : NSObject

/**
 用户登录的唯一标识符
 */
@property (strong, nonatomic) NSString *uid;
/**
 用户名
 */
@property (strong, nonatomic) NSString *username;
/**
 邮箱
 */
@property (strong, nonatomic) NSString *email;
/**
 手机号
 */
@property (strong, nonatomic) NSString *phone;
/**
 是否为匿名用户
 */
@property (assign, nonatomic) BOOL isAnonymous;
/**
 用户姓名
 */
@property (strong, nonatomic) NSString *name;
/**
 性别
 */
@property (assign, nonatomic) XPGUserGenderType gender;
/**
 生日
 */
@property (strong, nonatomic) NSDate *birthday;
/**
 家庭住址
 */
@property (strong, nonatomic) NSString *address;
/**
 语言
 */
@property (strong, nonatomic) NSString *lang;
/**
 备注
 */
@property (strong, nonatomic) NSString *remark;

@end
