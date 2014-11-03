//
//  IoTDeviceEnumCell.m
//  Gokit-demo
//
//  Created by xpg on 14/10/27.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDeviceEnumCell.h"

@interface IoTDeviceEnumCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *valueText;

@end

@implementation IoTDeviceEnumCell

- (void)awakeFromNib {
    self.titleText.text = _title;
    self.index = _index;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if(selected == YES && [_delegate respondsToSelector:@selector(IoTDeviceDidSelectedEnum:)])
        [_delegate IoTDeviceDidSelectedEnum:self];
    
    [super setSelected:NO animated:animated];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleText.text = title;
}

- (void)setValues:(NSArray *)values
{
    _values = values;
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    if(_index >= 0 && _index < _values.count)
        self.valueText.text = [NSString stringWithFormat:@"%@", _values[index]];
    else
        self.valueText.text = @"";
}

@end
