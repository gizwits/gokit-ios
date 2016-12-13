//
//  GosTipView.m
//  SmartSocket
//
//  Created by danly on 16/7/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosTipView.h"
#import "MBProgressHUD.h"

@interface GosTipView ()

@property (nonatomic, assign, readonly)  MBProgressHUD *hud;

@end

@implementation GosTipView

+(instancetype)sharedInstance
{
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

// 显示加载框  带加载图
- (void)showLoadTipWithMessage:(NSString *)message delay:(int)delay completion:(void (^)(void))completion
{
    self.hud.mode = MBProgressHUDModeIndeterminate;
    [self showLoadTipWithMessage:message];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideTipView];
        
        if (completion)
        {
            completion();
        }
    });
}

// 显示加载框  带加载图
- (void)showLoadTipWithMessage:(NSString *)message
{
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.label.text = message;
    [self.hud showAnimated:YES];
}

// 隐藏提示框
- (void)hideTipView
{
    if (self.hud.hidden == NO)
    {
        [self.hud hideAnimated:NO];
    }
}

// 显示只有文字的提示框
- (void)showTipMessage:(NSString *)message delay:(int)delay completion:(void (^)(void))completion
{
    self.hud.mode = MBProgressHUDModeText;
    self.hud.label.text = message;
    [self.hud showAnimated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideTipView];
        
        if (completion)
        {
            completion();
        }
    });
    
}

#pragma mark - Properity
- (MBProgressHUD *)hud
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    MBProgressHUD *hud = [MBProgressHUD HUDForView:window];
    hud.label.numberOfLines = 0;
    if(nil == hud)
    {
        hud = [[MBProgressHUD alloc] initWithWindow:window];
        [window addSubview:hud];
    }
    return hud;
}

@end
