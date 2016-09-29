//
//  GizConfigAirlinkTips.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigAirlinkTips.h"
#import "GosCommon.h"

@interface GosConfigAirlinkTips ()

@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIImageView *imgAirlink;

@end

@implementation GosConfigAirlinkTips

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.btnNext setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.btnNext.layer setCornerRadius:19.0];
    self.imgAirlink.gifPath = [[NSBundle mainBundle] pathForResource:@"02-airlink" ofType:@"gif"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.imgAirlink startGIF];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.imgAirlink stopGIF];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onRadioButtonTouched:(UIButton *)sender {
    if (sender.isSelected) {
        if (self.btnNext.enabled) {
            sender.selected = NO;
            self.btnNext.enabled = NO;
            self.btnNext.backgroundColor = [UIColor lightGrayColor];
        } else {
            self.btnNext.enabled = YES;
            self.btnNext.backgroundColor = [GosCommon sharedInstance].buttonColor;
//            self.btnNext.backgroundColor = CUSTOM_YELLOW_COLOR();
        }
    }
}

@end
