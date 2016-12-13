//
//  GosTipView.h
//  SmartSocket
//
//  Created by danly on 16/7/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  纯提示框类
 */
@interface GosTipView : NSObject

+(instancetype)sharedInstance;

/**
 *  显示加载框  带加载图
 *
 *  @param message    消息
 *  @param delay      延时
 *  @param completion 加载框消失后调用的代码块
 */
- (void)showLoadTipWithMessage:(NSString *)message delay:(int)delay completion:(void (^)(void))completion;

/**
 *  显示加载框  带加载图
 *
 *  @param message 消息
 */
- (void)showLoadTipWithMessage:(NSString *)message;

/**
 *  隐藏提示框
 */
- (void)hideTipView;

/**
 *  显示只有文字的提示框
 *
 *  @param message    消息
 *  @param delay      延时
 *  @param completion 提示框消失后调用的代码块
 */
- (void)showTipMessage:(NSString *)message delay:(int)delay completion:(void (^)(void))completion;

@end
