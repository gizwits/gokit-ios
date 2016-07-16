/**
 * GizDeviceEnumCell.h
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import "GizDeviceEnumSelection.h"

@class GizDeviceEnumCell;

@protocol GizDeviceEnumCellDelegate <NSObject>

- (void)GizDeviceDidSelectedEnum:(GizDeviceEnumCell *)cell;
- (void)GizDeviceEnumDidSelectedValue:(GizDeviceEnumCell *)cell index:(NSInteger)index;

@end

@interface GizDeviceEnumCell : UITableViewCell

@property (nonatomic, assign) id <GizDeviceEnumCellDelegate>delegate;
@property (nonatomic, assign) NSInteger tag;    //标识

@property (nonatomic, strong) NSString *title;  //标题
@property (nonatomic, strong) NSArray *values;  //值
@property (nonatomic, assign) NSInteger index;  //选中的值

@property (nonatomic, assign) BOOL preSelected;

@end