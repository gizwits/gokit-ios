//
//  IoTWaitForConfigureAP.m
//  WiFiDemo
//
//  Created by xpg on 14-6-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTWaitForConfigureAP.h"
#import "IoTDeviceList.h"
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <XPGWifiSDK/XPGWifiSSIDInfo.h>

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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /**
         * @brief 配置失败，返回
         * @brief 配置后，等待 Soft AP 模式退出，超时30s
         */
        BOOL isTimeout = YES;
        AFNetworkReachabilityStatus reachStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
        for(int i=0; i<60; i++)
        {
            //间隔 5s 发送一次请求
            if((i % 10) == 0)
                [[XPGWifiSDK sharedInstance] setSSID:self.ssid key:self.key];
            
            reachStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
            if(![XPGWifiSSIDInfo isSoftAPMode] && reachStatus == AFNetworkReachabilityStatusNotReachable)
                break;
            
            usleep(500000);
        }
        
        /**
         * @brief 等待30s，重新连上旧热点
         */
        for(int i=0; i<60; i++)
        {
            reachStatus = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
            if(([XPGWifiSSIDInfo isConnectedWifi] &&
               ![XPGWifiSSIDInfo isSoftAPMode] &&
               reachStatus == AFNetworkReachabilityStatusReachableViaWiFi) ||
               reachStatus == AFNetworkReachabilityStatusReachableViaWWAN)
            {
                isTimeout = NO;
                break;
            }
            usleep(500000);
        }
        
        if(!isTimeout)
        {
            [self performSelectorOnMainThread:@selector(pushToDeviceList) withObject:nil waitUntilDone:YES];
            return;
        }
        
        /**
         * @brief 未连上网络
         */
        [self performSelectorOnMainThread:@selector(pushBack) withObject:nil waitUntilDone:YES];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 页面
- (void)pushBack
{
    if(self.navigationController.viewControllers.lastObject == self)
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushToDeviceList
{
    if(self.navigationController.viewControllers.lastObject == self)
        [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
