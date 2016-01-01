/**
 * IoTLogin.m
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

#import "IoTLogin.h"
#import <MBProgressHUD/MBProgressHUD.h>

#import <XPGWifiSDK/XPGWifiSDK.h>
//#import "IoTRegister.h"
#import "IoTNewRegisterSendMessage.h"

@interface IoTLogin () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textPass;

@end

@implementation IoTLogin

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"账号登录";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"注册" style:UIBarButtonItemStylePlain target:self action:@selector(onRegister)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!AppDelegate.isRegisteredUser)
        self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [XPGWifiSDK sharedInstance].delegate = self;
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [XPGWifiSDK sharedInstance].delegate = nil;
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Action
- (IBAction)login:(id)sender
{
    MBProgressHUD *hud = AppDelegate.hud;
    hud.labelText = @"登录中...";
    [hud show:YES];
    
    [[XPGWifiSDK sharedInstance] userLoginWithUserName:self.textUser.text password:self.textPass.text];
    NSLog(@"username: %@, password: %@",self.textUser.text, self.textPass.text);
}

- (IBAction)forgetPassword:(id)sender {
    IoTNewRegisterSendMessage *fp = [[IoTNewRegisterSendMessage alloc] initWithToForgetPassword:YES];
    [AppDelegate safePushController:fp animated:YES];
}

- (void)onRegister
{
    IoTNewRegisterSendMessage *reg = [[IoTNewRegisterSendMessage alloc] initWithToForgetPassword:NO];
    [AppDelegate safePushController:reg animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == self.textUser)
    {
        [self.textPass becomeFirstResponder];
    }
    else
    {
        [self login:nil];
    }
    return YES;
}

#pragma mark - delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    if([error intValue])
    {
        [AppDelegate.hud hide:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        AppDelegate.userType = IoTUserTypeNormal;
        AppDelegate.uid = uid;
        AppDelegate.token = token;
        AppDelegate.username = self.textUser.text;
        AppDelegate.password = self.textPass.text;
        
        [AppDelegate.hud hide:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
