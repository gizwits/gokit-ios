/**
 * IoTWaitForConfigureAP.m
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

#import "IoTWaitForConfigureAP.h"
#import "IoTDeviceList.h"
#import <XPGWifiSDK/XPGWifiSDK.h>

@interface IoTWaitForConfigureAP ()

@end

@implementation IoTWaitForConfigureAP

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
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
    [XPGWifiSDK sharedInstance].delegate = self;
    [[XPGWifiSDK sharedInstance] setDeviceWifi:self.ssid key:self.key mode:XPGWifiSDKSoftAPMode timeout:60];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 页面
- (void)pushBack
{
    if(self.navigationController.viewControllers.lastObject == self) {
        [XPGWifiSDK sharedInstance].delegate = nil;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)pushToDeviceList
{
    if(self.navigationController.viewControllers.lastObject == self)
        [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetDeviceWifi:(XPGWifiDevice *)device result:(int)result
{
    if (!result) {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [self pushToDeviceList];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
}

@end
