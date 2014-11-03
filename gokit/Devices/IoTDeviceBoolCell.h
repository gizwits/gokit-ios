//
//  IoTDeviceBoolCell.h
//  Gokit-demo
//
//  Created by xpg on 14/10/27.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IoTDeviceBoolCell;

@protocol IoTDeviceBoolCellDelegate <NSObject>

- (void)IoTDeviceSwitchDidUpdateValue:(IoTDeviceBoolCell *)cell value:(BOOL)value;

@end

@interface IoTDeviceBoolCell : UITableViewCell

@property (nonatomic, assign) id <IoTDeviceBoolCellDelegate>delegate;
@property (nonatomic, assign) NSInteger tag;    //标识

@property (nonatomic, strong) NSString *title;  //标题
@property (nonatomic, assign) BOOL value;       //值

@end
