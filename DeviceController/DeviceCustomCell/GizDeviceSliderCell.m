/**
 * GizDeviceSliderCell.m
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

#import "GizDeviceSliderCell.h"

@interface GizDeviceSliderCell()

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (weak, nonatomic) IBOutlet UILabel *valueText;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *btnMinute;
@property (weak, nonatomic) IBOutlet UIButton *btnAdd;

@end

@implementation GizDeviceSliderCell

@synthesize tag = _tag;

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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    
}

#pragma mark - Properties
- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleText.text = title;
}

- (void)setMin:(CGFloat)min {
    _min = min;
    self.slider.minimumValue = min;
}

- (void)setMax:(CGFloat)max {
    _max = max;
    self.slider.maximumValue = max;
}

- (void)setValue:(CGFloat)value {
    _value = value;
    self.slider.value = value;
    [self sliderChanging:self.slider];
}

- (void)setStep:(CGFloat)step {
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

- (CGFloat)calculateValidValueFromSlider {
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
    if([_delegate respondsToSelector:@selector(GizDeviceSliderDidUpdateValue:value:)])
        [_delegate GizDeviceSliderDidUpdateValue:self value:_value];
}

- (IBAction)sliderChanging:(id)sender {
    self.valueText.text = [NSString stringWithFormat:@"%@", @([self calculateValidValueFromSlider])];
}

@end
