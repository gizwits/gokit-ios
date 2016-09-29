//
//  GizConfigSoftAPHelp.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPHelp.h"
#import "GosSoftAPDetection.h"
#import "GosCommon.h"

@interface GosConfigSoftAPHelp ()

@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIImageView *imgSoftap;

@end

@implementation GosConfigSoftAPHelp

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.btnNext setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.btnNext.layer setCornerRadius:19.0];
    self.imgSoftap.gifPath = [[NSBundle mainBundle] pathForResource:@"04-softap" ofType:@"gif"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.imgSoftap startGIF];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.imgSoftap stopGIF];
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

- (IBAction)onOpenConfig:(id)sender {
    [self onBack:sender];
}

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
            sender.selected = YES;
            self.btnNext.enabled = YES;
//            self.btnNext.backgroundColor = CUSTOM_YELLOW_COLOR();
            self.btnNext.backgroundColor = [GosCommon sharedInstance].buttonColor;
        }
    }
}

@end
