//
//  ForgetViewController.m
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosForgetViewController.h"
#import "GosPhoneCell.h"
#import "GosVerificationCell.h"
#import "GosPasswordCell.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import "AppDelegate.h"

@interface GosForgetViewController () <GizWifiSDKDelegate>
@property (strong, nonatomic) GosPhoneCell *phoneCell;
@property (strong, nonatomic) GosVerificationCell *verfiyCell;
@property (strong, nonatomic) GosPasswordCell *passwordCell;

@property (assign, nonatomic) NSInteger verifyCodeCounter;
@property (strong, nonatomic) NSTimer *verifyTimer;

@property (weak, nonatomic) IBOutlet UIButton *forgetBtn;

@end

@implementation GosForgetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.forgetBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.forgetBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.forgetBtn.layer setCornerRadius:22.0];
    self.automaticallyAdjustsScrollViewInsets = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setHidden:NO];
    [GizWifiSDK sharedInstance].delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.phoneCell.textInput becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.verifyTimer invalidate];
    self.verifyTimer = nil;
    self.verifyCodeCounter = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - table view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    //
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    //    }
    //    cell.textLabel.text = @"";
    //    return cell;
    
    switch (indexPath.row) {
        case 0:
            if (nil == self.phoneCell) {
                self.phoneCell = GetControllerWithClass([GosPhoneCell class], tableView, @"phoneCell");
                self.phoneCell.textInput.delegate = self;
                self.phoneCell.textInput.returnKeyType = UIReturnKeyNext;
                self.phoneCell.delegate = self;
            }
            return self.phoneCell;
        case 1:
            if (nil == self.verfiyCell) {
                self.verfiyCell = GetControllerWithClass([GosVerificationCell class], tableView, @"verfiyCell");
                self.verfiyCell.textInput.delegate = self;
                self.verfiyCell.textInput.returnKeyType = UIReturnKeyNext;
            }
            return self.verfiyCell;
        case 2:
            if (nil == self.passwordCell) {
                self.passwordCell = GetControllerWithClass([GosPasswordCell class], tableView, @"passwordCell");
                self.passwordCell.textPassword.delegate = self;
                self.passwordCell.textPassword.returnKeyType = UIReturnKeyDone;
                //                [self.passwordCell.btnClearPassword addTarget:self action:@selector(onClearPassword) forControlEvents:UIControlEventTouchUpInside];
                [self.passwordCell.btnShowText addTarget:self action:@selector(onShowText) forControlEvents:UIControlEventTouchUpInside];
                
            }
            return self.passwordCell;
        default:
            break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didSendCodeBtnPressed {
    if([self.phoneCell.textInput.text isEqualToString:@""]) {
        [common showAlert:NSLocalizedString(@"please input cellphone", nil) disappear:YES];
        return;
    }
    else {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[GizWifiSDK sharedInstance] requestSendPhoneSMSCode:APP_SECRET phone:self.phoneCell.textInput.text];
    }
}

- (IBAction)retsetBtnPressed:(id)sender {
    if([self.phoneCell.textInput.text isEqualToString:@""]) {
        [common showAlert:NSLocalizedString(@"please input cellphone", nil) disappear:YES];
        return;
    }
    if (self.verfiyCell.textInput.text.length != 6) {
        [common showAlert:NSLocalizedString(@"Verification code error", nil) disappear:YES];
        return;
    }
    if ([self.passwordCell.textPassword.text isEqualToString:@""]) {
        [common showAlert:NSLocalizedString(@"please input password", nil) disappear:YES];
        return;
    }
    if (self.passwordCell.textPassword.text.length < 6) {
        [common showAlert:NSLocalizedString(@"The password must be at least six characters", nil) disappear:YES];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[GizWifiSDK sharedInstance] resetPassword:self.phoneCell.textInput.text verifyCode:self.verfiyCell.textInput.text newPassword:self.passwordCell.textPassword.text accountType:GizUserPhone];
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result token:(NSString *)token {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [common showAlert:NSLocalizedString(@"Phone verification code sent successfully", nil) disappear:YES];
        [self.phoneCell.textInput setEnabled:NO];
        [self.phoneCell.textInput setTextColor:[UIColor grayColor]];
        [self.verfiyCell.textInput becomeFirstResponder];
        
        self.verifyCodeCounter = 60;
        self.verifyTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateVerifyButton) userInfo:nil repeats:YES];
    }
    else {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [common showAlert:info disappear:YES];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChangeUserPassword:(NSError *)result {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
        [common showAlert:NSLocalizedString(@"Reset success", nil) disappear:YES];
        [[GosCommon sharedInstance] saveUserDefaults:self.phoneCell.textInput.text password:self.passwordCell.textPassword.text uid:nil token:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [common showAlert:info disappear:YES];
    }
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
    [self.passwordCell.textPassword resignFirstResponder];
}

- (void)setShowText:(BOOL)isShow {
    UITextField *textPassword = self.passwordCell.textPassword;
    textPassword.secureTextEntry = !isShow;
    self.passwordCell.btnShowText.selected = isShow;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.passwordCell.textPassword resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSString *textPassword = self.passwordCell.textPassword.text;
    self.passwordCell.textPassword.text = @"";
    self.passwordCell.textPassword.text = textPassword;
}

#pragma mark - Others
- (void)updateVerifyButton {
    if(self.verifyCodeCounter == 0) {
        [self.verifyTimer invalidate];
        self.phoneCell.getVerifyCodeBtn.enabled = true;
        [self.phoneCell.getVerifyCodeBtn setTitle:NSLocalizedString(@"Get verification code", nil) forState:UIControlStateNormal];
        self.phoneCell.getVerifyCodeBtn.backgroundColor = [UIColor colorWithRed:0.980 green:0.875 blue:0.275 alpha:1];
        [self.phoneCell.textInput setEnabled:YES];
        [self.phoneCell.textInput setTextColor:[UIColor blackColor]];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"%i %@", (int)self.verifyCodeCounter, NSLocalizedString(@"Try again", nil)];
    self.phoneCell.getVerifyCodeBtn.enabled = true;
    self.phoneCell.getVerifyCodeBtn.backgroundColor = [UIColor lightGrayColor];
    [self.phoneCell.getVerifyCodeBtn setTitle:title forState:UIControlStateNormal];
    self.phoneCell.getVerifyCodeBtn.enabled = false;
    
    self.verifyCodeCounter--;
}

@end
