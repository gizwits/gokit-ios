//
//  IoTDeviceBoolCell.m
//  Gokit-demo
//
//  Created by xpg on 14/10/27.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDeviceBoolCell.h"

@interface IoTDeviceBoolCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UISwitch *valueSwitch;

@end

@implementation IoTDeviceBoolCell

- (void)awakeFromNib {
    self.titleText.text = _title;
    self.valueSwitch.on = _value;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:animated];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleText.text = title;
}

- (void)setValue:(BOOL)value
{
    _value = value;
    self.valueSwitch.on = value;
}

- (IBAction)switchChanged:(id)sender {
    _value = self.valueSwitch.on;
    if([self.delegate respondsToSelector:@selector(IoTDeviceSwitchDidUpdateValue:value:)])
        [_delegate IoTDeviceSwitchDidUpdateValue:self value:_value];
}

@end
