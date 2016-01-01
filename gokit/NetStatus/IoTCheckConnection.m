/**
 * IoTCheckConnection.m
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

#import "IoTCheckConnection.h"
#import <AFNetworking/AFNetworking.h>
#import "IoTDeviceList.h"
#import "IoTNotReachable.h"
#import "IoTDeviceAP.h"
#import "IoTWifiUtil.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface IoTCheckConnection ()
{
    BOOL inited;
}

@end

@implementation IoTCheckConnection

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didBecomeActive
{
    if(self.navigationController.viewControllers.lastObject != self)
        return;
    
    // 防止多次初始化
    if(inited)
        return;
    inited = YES;
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [self checkNetwokStatus];
    }];
    
    // 检测Wifi/移动数据(WWAN)/关闭状态(Not Reachable)
    [self checkNetwokStatus];
    
    // 检测 SDK 是否加载
    [self performSelectorInBackground:@selector(checkSDK) withObject:nil];
}

- (void)willResignActive
{
    [self viewWillDisappear:YES];
}

- (void)didEnterBackground
{
    [self viewDidDisappear:YES];
}

#pragma mark - Other methods
- (void)sdkCheckFailed
{
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"SDK 初始化失败。" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    [self performSelector:@selector(pushToNotReachable) withObject:nil afterDelay:0.5];
}

- (void)checkSDK
{
    //延迟 1s 后再判断 SDK
    sleep(1);
    
    if(![XPGWifiSDK sharedInstance])
    {
        [self performSelectorOnMainThread:@selector(sdkCheckFailed) withObject:nil waitUntilDone:NO];
        return;
    }
    
    // 确认 SDK 加载成功，把 delegate 赋值
    [self performSelectorOnMainThread:@selector(checkMode) withObject:nil waitUntilDone:NO];
}

- (void)checkMode
{
    [XPGWifiSDK sharedInstance].delegate = self;
    
    // 检测到 Soft AP 模式，自动跳转，无需登录
    // 防止页面过快的自动跳转，延迟 0.5s
    if([IoTWifiUtil isSoftAPMode:@"XPG-GAgent"])
        [self performSelector:@selector(pushToDeviceAP) withObject:nil afterDelay:0.5];
    else
        [self performSelector:@selector(initAccount) withObject:nil afterDelay:0.5];
}

- (void)initAccount
{
    // 如果未注册匿名用户，系统会自动注册一个匿名用户
    // 用户已注册，直接登录
    if(!AppDelegate.isRegisteredUser)
        [[XPGWifiSDK sharedInstance] userLoginAnonymous];
    else
        [AppDelegate userLogin];
}

- (void)checkNetwokStatus
{
    AFNetworkReachabilityStatus netStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    switch (netStatus) {
        case AFNetworkReachabilityStatusNotReachable:
        {
            if(netStatus == AFNetworkReachabilityStatusNotReachable)
                [self performSelector:@selector(pushToNotReachable) withObject:nil afterDelay:0.5];
            break;
        }
        default:
            break;
    }
}

#pragma mark - SDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    if([AppDelegate respondsToSelector:@selector(XPGWifiSDK:didUserLogin:errorMessage:uid:token:)])
        [AppDelegate XPGWifiSDK:wifiSDK didUserLogin:error errorMessage:errorMessage uid:uid token:token];
    
    // 登录失败，跳转错误页面
    if ([error intValue] || uid.length == 0 || token.length == 0)
        [self performSelector:@selector(pushToNotReachable) withObject:nil afterDelay:0.5];
    else
        [self performSelector:@selector(pushToDeviceList) withObject:nil afterDelay:0.5];
}


#pragma mark - Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self didBecomeActive];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if(self.navigationController.viewControllers.lastObject == self)
        [XPGWifiSDK sharedInstance].delegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    inited = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - push to where?
- (void)pushToNotReachable
{
    if([self.navigationController.viewControllers lastObject] == self)
    {
        IoTNotReachable *notReach = [[IoTNotReachable alloc] init];
        [self.navigationController pushViewController:notReach animated:YES];
    }
}

- (void)pushToDeviceList
{
    if([self.navigationController.viewControllers lastObject] == self)
    {
        IoTDeviceList *device = [[IoTDeviceList alloc] init];
        [self.navigationController pushViewController:device animated:YES];
    }
}

- (void)pushToDeviceAP
{
    if([self.navigationController.viewControllers lastObject] == self)
    {
        IoTDeviceAP *devAP = [[IoTDeviceAP alloc] init];
        [self.navigationController pushViewController:devAP animated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    abort();
}

@end
