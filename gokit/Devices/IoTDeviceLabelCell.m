//
//  IoTDeviceLabelCell.m
//  Gokit-demo
//
//  Created by xpg on 14/10/22.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDeviceLabelCell.h"

@interface IoTDeviceLabelCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *valueText;

@end

@implementation IoTDeviceLabelCell

- (void)awakeFromNib {
    self.titleText.text = _title;
    self.valueText.text = _value;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:animated];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleText.text = title;
}

- (void)setValue:(NSString *)value
{
    _value = value;
    self.valueText.text = value;
}

@end
