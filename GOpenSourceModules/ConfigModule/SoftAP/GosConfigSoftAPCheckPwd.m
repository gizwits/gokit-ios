//
//  GizConfigSoftAPCheckPwd.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/14.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigSoftAPCheckPwd.h"
#import "GosSSIDCell.h"
#import "GosWifiPasswordCell.h"
#import "GosCommon.h"
#import "GosConfigSoftAPStart.h"

@interface GosConfigSoftAPCheckPwd () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) GosSSIDCell *ssidCell;
@property (strong, nonatomic) GosWifiPasswordCell *passwordCell;

@property (assign, nonatomic) CGFloat top;
@property (assign) BOOL isFirstRun;//检查密码有区分是第一次还是其他，第一次一定显示的是上次配置的ssid和密码

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@end

@implementation GosConfigSoftAPCheckPwd

- (void)willEnterForeground {
    NSString *ssid = @"";
    
    if (self.isFirstRun) {
        self.isFirstRun = NO;
        ssid = [GosCommon sharedInstance].ssid;
    } else {
        ssid = GetCurrentSSID();
    }
    
    self.ssidCell.textSSID.text = ssid;
    self.passwordCell.textPassword.text = [[GosCommon sharedInstance] getPasswrodFromSSID:ssid];
    [self.passwordCell.textPassword becomeFirstResponder];
    [self setShowText:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nextBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.nextBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.nextBtn.layer setCornerRadius:19.0];
    self.tableView.scrollEnabled = NO;
    self.top = self.navigationController.navigationBar.translucent ? 0 : 64;
    self.isFirstRun = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    GIZ_LOG_BIZ("check_wifi_password_page_show", "success", "check wifi password page is shown");
    
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    GIZ_LOG_BIZ("check_wifi_password_page_hide", "success", "check wifi password page is hiden");
    
    [super viewWillDisappear:animated];
    [self onTap];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self.passwordCell.textPassword resignFirstResponder];
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

#pragma mark - table view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            if (nil == self.ssidCell) {
                self.ssidCell = GetControllerWithClass([GosSSIDCell class], tableView, @"ssidCell");
                self.ssidCell.textSSID.delegate = self;
                self.ssidCell.textSSID.returnKeyType = UIReturnKeyNext;
                self.ssidCell.textSSID.enabled = NO;
            }
            return self.ssidCell;
        case 1:
            if (nil == self.passwordCell) {
                self.passwordCell = GetControllerWithClass([GosWifiPasswordCell class], tableView, @"passwordCell");
                self.passwordCell.textPassword.delegate = self;
                self.passwordCell.textPassword.returnKeyType = UIReturnKeyDone;
//                [self.passwordCell.btnClearPassword addTarget:self action:@selector(onClearPassword) forControlEvents:UIControlEventTouchUpInside];
                [self.passwordCell.btnShowText addTarget:self action:@selector(onShowText) forControlEvents:UIControlEventTouchUpInside];
                
                //加载初始化的信息
                [self willEnterForeground];
            }
            return self.passwordCell;
        default:
            break;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - text field
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.ssidCell.textSSID) {
        [self setViewY:self.top];
    } else {
        [self setViewY:self.top];
    }
    
    NSString *textPassword = self.passwordCell.textPassword.text;
    self.passwordCell.textPassword.text = @"";
    self.passwordCell.textPassword.text = textPassword;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.ssidCell.textSSID) {
        [self.passwordCell.textPassword becomeFirstResponder];
    } else {
        [self.passwordCell.textPassword resignFirstResponder];
        [self setViewY:self.top];
    }
    return NO;
}

#pragma mark - alert
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        [self onPushToSoftAPStart];
    }
}

#pragma mark - view animation
- (void)setViewY:(CGFloat)y {
    //4s 可能出现问题，先屏蔽
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationsEnabled:YES];
//    CGRect rc = self.view.frame;
//    rc.origin.y = y;
//    self.view.frame = rc;
//    [UIView commitAnimations];
}

- (void)setShowText:(BOOL)isShow {
    UITextField *textPassword = self.passwordCell.textPassword;
    textPassword.secureTextEntry = !isShow;
    self.passwordCell.btnShowText.selected = isShow;
}

#pragma mark - Event
- (void)onClearPassword {
    self.passwordCell.textPassword.text = @"";
}

- (void)onShowText {
    [self onTap];
    [self setShowText:self.passwordCell.textPassword.secureTextEntry];
}

- (IBAction)onTap {
    [self setViewY:self.top];
    [self.passwordCell.textPassword resignFirstResponder];
}

- (void)onPushToSoftAPStart {
    if (self.navigationController.viewControllers.lastObject != self) {
        return;
    }
    
    NSMutableArray *mCtrls = [self.navigationController.viewControllers mutableCopy];
    for (NSInteger i = mCtrls.count; i > 0; i--) {
        UIViewController *viewController = mCtrls[i-1];
        if ([viewController isMemberOfClass:[GosConfigSoftAPStart class]]) {
            break;
        }
        [mCtrls removeObject:viewController];
    }
    
    GosCommon *dataCommon = [GosCommon sharedInstance];
    dataCommon.ssid = self.ssidCell.textSSID.text;
    if (nil == dataCommon.ssid) {
        dataCommon.ssid = @"";
    }
    
    [dataCommon saveSSID:dataCommon.ssid key:self.passwordCell.textPassword.text];
    
    [self.navigationController setViewControllers:mCtrls animated:YES];
}

- (IBAction)onNext:(id)sender {
    if (0 == self.passwordCell.textPassword.text.length) {
        SHOW_ALERT_EMPTY_PASSWORD(self);
    } else {
        [self onPushToSoftAPStart];
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
