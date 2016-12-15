//
//  GosAnonymousLogin.m
//  GOpenSource_AppKit
//
//  Created by Tom on 16/9/12.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosAnonymousLogin.h"
#import <GizWifiSDK/GizWifiSDK.h>

static __strong GosDidLogin _loginHandler = nil;
static GosAnonymousLoginStatus _lastLoginStatus = GosAnonymousLoginStatusUnknown;

@implementation GosAnonymousLogin

+ (id)sharedInstance {
    static GosAnonymousLogin *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[GosAnonymousLogin alloc] init];
    });
    return singleton;
}

+ (GosAnonymousLoginStatus)lastLoginStatus {
    return _lastLoginStatus;
}

+ (void)loginAnonymous:(GosDidLogin)loginHandler {
    if (_lastLoginStatus == GosAnonymousLoginStatusProcessing) {
        return;
    }
    _loginHandler = loginHandler;
    [[GizWifiSDK sharedInstance] userLoginAnonymous];
    _lastLoginStatus = GosAnonymousLoginStatusProcessing;
}

+ (void)logout {
    _lastLoginStatus = GosAnonymousLoginStatusLogout;
}

+ (void)cleanup {
    _lastLoginStatus = GosAnonymousLoginStatusUnknown;
}

+ (void)didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    if (_lastLoginStatus != GosAnonymousLoginStatusProcessing) {
        return;
    }
    GosDidLogin loginHandler = _loginHandler;
    if (loginHandler) {
        loginHandler(result, uid, token);
    }
    if (result.code == GIZ_SDK_SUCCESS) {
        _lastLoginStatus = GosAnonymousLoginStatusSucceed;
    } else {
        _lastLoginStatus = GosAnonymousLoginStatusFailed;
    }
}

@end
