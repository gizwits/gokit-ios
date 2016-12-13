//
//  GosAnonymousLogin.h
//  GOpenSource_AppKit
//
//  Created by Tom on 16/9/12.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GosAnonymousLoginStatus) {
    /*
     初始状态
     */
    GosAnonymousLoginStatusUnknown = 0,
    /*
     正在匿名登录
     */
    GosAnonymousLoginStatusProcessing,
    /*
     匿名登录失败
     */
    GosAnonymousLoginStatusFailed,
    /*
     匿名登录成功
     */
    GosAnonymousLoginStatusSucceed,
    /*
     匿名登录登出
     */
    GosAnonymousLoginStatusLogout
};

typedef void(^GosDidLogin)(NSError *result, NSString *uid, NSString *token);

@interface GosAnonymousLogin : NSObject

/*
 上次的登录状态
 */
+ (GosAnonymousLoginStatus)lastLoginStatus;

/*
 登录，需要手动设置接收sdk回调
 */
+ (void)loginAnonymous:(GosDidLogin)loginHandler;

/*
 登出
 */
+ (void)logout;

/*
 清理，执行普通用户、第三方用户登录
 */
+ (void)cleanup;

/*
 需要把sdk的回调直接调用这个方法，用于记录状态，事件转发
 */
+ (void)didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token;

@end
