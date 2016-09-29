//
//  GizConfigSoftAPFailed.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPFailed.h"
#import "GosCommon.h"

@interface GosConfigSoftAPFailed () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *retryBtn;

@end

@implementation GosConfigSoftAPFailed

- (void)viewDidLoad {
    [super viewDidLoad];
    self.retryBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.retryBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.retryBtn.layer setCornerRadius:19.0];
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

- (IBAction)onCancel:(id)sender {
    SHOW_ALERT_CANCEL_CONFIG(self);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 1:
            [[GosCommon sharedInstance] onCancel];
            break;
        default:
            break;
    }
}

@end
