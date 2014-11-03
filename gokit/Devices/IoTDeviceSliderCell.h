//
//  IoTDeviceSliderCell.h
//  Gokit-demo
//
//  Created by xpg on 14/10/22.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IoTDeviceSliderCell;

@protocol IoTDeviceSliderCellDelegate <NSObject>

- (void)IoTDeviceSliderDidUpdateValue:(IoTDeviceSliderCell *)cell value:(CGFloat)value;

@end

@interface IoTDeviceSliderCell : UITableViewCell

@property (nonatomic, assign) id <IoTDeviceSliderCellDelegate>delegate;
@property (nonatomic, assign) NSInteger tag;    //标识

@property (nonatomic, strong) NSString *title;  //标题

@property (nonatomic, assign) CGFloat min;      //最小值
@property (nonatomic, assign) CGFloat max;      //最大值
@property (nonatomic, assign) CGFloat value;    //当前值
@property (nonatomic, assign) CGFloat step;     //步长

@end
