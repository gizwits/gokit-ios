/**
 * GizDeviceEnumCell.m
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

#import "GizDeviceEnumCell.h"

@interface GizDeviceEnumCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *valueText;

@end

@implementation GizDeviceEnumCell

@synthesize tag = _tag;

- (void)awakeFromNib {
    self.titleText.text = _title;
    self.index = _index;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.preSelected = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    if (self.preSelected == selected) {
//        return;
//    }
//    self.preSelected = selected;
    if(selected == YES && [_delegate respondsToSelector:@selector(GizDeviceDidSelectedEnum:)])
        [_delegate GizDeviceDidSelectedEnum:self];
    
    [super setSelected:NO animated:animated];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleText.text = title;
}

- (void)setValues:(NSArray *)values {
    _values = values;
}

- (void)setIndex:(NSInteger)index {
    _index = index;
    if(_index >= 0 && _index < _values.count)
        self.valueText.text = [NSString stringWithFormat:@"%@", _values[index]];
    else
        self.valueText.text = @"";
}

@end
