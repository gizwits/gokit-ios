/**
 * IoTRegister.m
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

#import "IoTRegister.h"
#import "IoTDeviceList.h"

@interface IoTRegister ()
{
    NSInteger verifyCodeCounter;
    NSTimer *verifyTimer;
}

@property (nonatomic, assign) BOOL isForget;
@property (weak, nonatomic) IBOutlet UIButton *btnRegister;
@property (weak, nonatomic) IBOutlet UIButton *btnVerifyCode;

@end

@implementation IoTRegister

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithForgetMode
{
    self = [super init];
    if (self){
        self.isForget = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if(self.isForget)
        [self.btnRegister setTitle:@"重置" forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    [XPGWifiSDK sharedInstance].delegate = self;
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [XPGWifiSDK sharedInstance].delegate = nil;
    [verifyTimer invalidate];
    verifyTimer = nil;
    verifyCodeCounter = 0;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Action
// 获取验证码
- (IBAction)onQueryVerifyCode:(id)sender {
    UITextField *textPhone = (UITextField *)[self.view viewWithTag:1];
    if(textPhone.text.length != 11)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入正确的手机号" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [textPhone becomeFirstResponder];
        return;
    }
    [[XPGWifiSDK sharedInstance] requestSendVerifyCode:textPhone.text];
    
    verifyCodeCounter = 60;
    [self updateVerifyButton];
    verifyTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateVerifyButton) userInfo:nil repeats:YES];
}

// 注册
- (IBAction)onRegister:(id)sender {
    UITextField *textPhone = (UITextField *)[self.view viewWithTag:1];
    UITextField *textCode = (UITextField *)[self.view viewWithTag:2];
    UITextField *textPassword = (UITextField *)[self.view viewWithTag:3];
    UITextField *textPassConfirm = (UITextField *)[self.view viewWithTag:4];
    if([textPassword.text isEqualToString:textPassConfirm.text])
    {
        if(self.isForget)
            [[XPGWifiSDK sharedInstance] changeUserPasswordByCode:textPhone.text code:textCode.text newPassword:textPassword.text];
        else
            [[XPGWifiSDK sharedInstance] registerUserByPhoneAndCode:textPhone.text password:textPassword.text code:textCode.text];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"密码不匹配，请重新输入" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        textPassword.text = @"";
        textPassConfirm.text = @"";
    }
}

#pragma mark - TextField Delegate
// 按下键盘确认按钮后的动作
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITextField *nextText = (UITextField *)[self.view viewWithTag:textField.tag+1];
    if(nil != nextText)
        [nextText becomeFirstResponder];
    else
        [self onRegister:nil];
    return YES;
}

#pragma mark - XPGWifiSDK Delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendVerifyCode:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if([error intValue] != 0)
    {
        //8:{"code":9,"msg":"同一手机号5分钟内重复提交相同的内容超过3次","detail":"同一个手机号 xxxxxxxxxxx 5分钟内重复提交相同的内容超过3次"}
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"获取短信失败。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        verifyCodeCounter = 0;
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didChangeUserPassword:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    int errorValue = [error intValue];
    if(errorValue != 0)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9010:
                message = @"验证码不正确";
                break;
            default:
                break;
        }
        [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"重置成功。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        
        //返回到设备列表页面
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didRegisterUser:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    int errorValue = [error intValue];
    if(errorValue)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9010:
                message = @"验证码不正确";
                break;
            default:
                break;
        }
        [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"注册成功。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        
        UITextField *textPhone = (UITextField *)[self.view viewWithTag:1];
        UITextField *textPassword = (UITextField *)[self.view viewWithTag:3];
        
        //保存相关信息
        AppDelegate.uid = uid;
        AppDelegate.token = token;
        AppDelegate.username = textPhone.text;
        AppDelegate.password = textPassword.text;
        AppDelegate.userType = IoTUserTypeNormal;
        
        //返回到设备列表页面
        for(UIViewController *view in self.navigationController.viewControllers)
        {
            if([view isKindOfClass:[IoTDeviceList class]])
            {
                [self.navigationController popToViewController:view animated:YES];
            }
        }
    }
}

#pragma mark - Others
// 验证码重复获取等待
- (void)updateVerifyButton
{
    if(verifyCodeCounter == 0)
    {
        [verifyTimer invalidate];
        self.btnVerifyCode.enabled = true;
        [self.btnVerifyCode setTitle:@"获取验证码" forState:UIControlStateNormal];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"等待%i秒", (int)verifyCodeCounter];
    self.btnVerifyCode.enabled = true;
    [self.btnVerifyCode setTitle:title forState:UIControlStateNormal];
    self.btnVerifyCode.enabled = false;
    
    verifyCodeCounter--;
}

@end
