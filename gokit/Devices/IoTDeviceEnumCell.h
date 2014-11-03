//
//  IoTDeviceEnumCell.h
//  Gokit-demo
//
//  Created by xpg on 14/10/27.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IoTDeviceEnumSelection.h"

@class IoTDeviceEnumCell;

@protocol IoTDeviceEnumCellDelegate <NSObject>

- (void)IoTDeviceDidSelectedEnum:(IoTDeviceEnumCell *)cell;
- (void)IoTDeviceEnumDidSelectedValue:(IoTDeviceEnumCell *)cell index:(NSInteger)index;

@end

@interface IoTDeviceEnumCell : UITableViewCell

@property (nonatomic, assign) id <IoTDeviceEnumCellDelegate>delegate;
@property (nonatomic, assign) NSInteger tag;    //标识

@property (nonatomic, strong) NSString *title;  //标题
@property (nonatomic, strong) NSArray *values;  //值
@property (nonatomic, assign) NSInteger index;  //选中的值

@end
