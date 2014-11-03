//
//  IoTDeviceSliderCell.m
//  Gokit-demo
//
//  Created by xpg on 14/10/22.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDeviceSliderCell.h"

@interface IoTDeviceSliderCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *valueText;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *btnMinute;
@property (weak, nonatomic) IBOutlet UIButton *btnAdd;

@end

@implementation IoTDeviceSliderCell

- (void)awakeFromNib {
    self.title = self.title;
    self.min = self.min;
    self.max = self.max;
    self.value = self.value;
    [self sliderChanging:self.slider];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:NO animated:animated];
}

#pragma mark - Properties
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleText.text = title;
}

- (void)setMin:(CGFloat)min
{
    _min = min;
    self.slider.minimumValue = min;
}

- (void)setMax:(CGFloat)max
{
    _max = max;
    self.slider.maximumValue = max;
}

- (void)setValue:(CGFloat)value
{
    _value = value;
    self.slider.value = value;
    [self sliderChanging:self.slider];
}

- (void)setStep:(CGFloat)step
{
    _step = step;
}

#pragma mark - Button Actions
- (IBAction)minute:(id)sender {
    self.slider.value -= _step;
    [self sliderChanging:self.slider];
    [self sliderChanged:self.slider];
}

- (IBAction)add:(id)sender {
    self.slider.value += _step;
    [self sliderChanging:self.slider];
    [self sliderChanged:self.slider];
}

- (CGFloat)calculateValidValueFromSlider
{
    if(!self.slider)
        return _value;
    
    if(_step == 0)
        return self.slider.value;
    
    if(self.slider.value == _max)
        return self.slider.value;
    
    float a = 0.f;
    float b = modff((self.slider.value - _min) / _step, &a);
    if(b > 0.5f)
        a += 1.f;
    return (a * _step) + _min;
}

- (IBAction)sliderChanged:(id)sender {
    _value = [self calculateValidValueFromSlider];
    self.slider.value = _value;
    if([_delegate respondsToSelector:@selector(IoTDeviceSliderDidUpdateValue:value:)])
        [_delegate IoTDeviceSliderDidUpdateValue:self value:_value];
}

- (IBAction)sliderChanging:(id)sender {
    self.valueText.text = [NSString stringWithFormat:@"%@", @([self calculateValidValueFromSlider])];
}

@end
