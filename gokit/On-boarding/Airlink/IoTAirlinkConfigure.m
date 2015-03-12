/**
 * IoTAirlinkConfigure.m
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

#import "IoTAirlinkConfigure.h"
#import "IoTWifiUtil.h"
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface IoTAirlinkConfigure () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textSSID;
@property (weak, nonatomic) IBOutlet UITextField *textKey;

@end

@implementation IoTAirlinkConfigure

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
    self.navigationItem.title = @"AirLink网络配置";
    self.textSSID.text = [[IoTWifiUtil SSIDInfo] objectForKey:@"SSID"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
    [AppDelegate.hud hide:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)configure:(id)sender
{
    [self.textSSID resignFirstResponder];
    [self.textKey resignFirstResponder];
    AppDelegate.hud.labelText = @"正在配置...";
    [AppDelegate.hud show:YES];
    [[XPGWifiSDK sharedInstance] setDeviceWifi:self.textSSID.text key:self.textKey.text mode:XPGWifiSDKAirLinkMode timeout:60];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self configure:nil];
    return YES;
}

#pragma mark - delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetDeviceWifi:(XPGWifiDevice *)device result:(int)result
{
    if(AppDelegate.hud.alpha == 1)
    {
        if([self.navigationController.viewControllers lastObject] == self)
        {
            if(result == 0)
            {
                [AppDelegate.hud hide:YES];
                [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                [self.navigationController popViewControllerAnimated:YES];
            }
            else if(result == -40)
            {
                [AppDelegate.hud hide:YES];
                [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置超时" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            }
            else
            {
                [AppDelegate.hud hide:YES];
                NSString *message = [NSString stringWithFormat:@"配置失败，错误码：%i", result];
                [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            }
        }
    }
}

@end
