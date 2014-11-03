//
//  IoTAirlinkConfigure.m
//  WiFiDemo
//
//  Created by xpg on 14-6-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTAirlinkConfigure.h"
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <XPGWifiSDK/XPGWifiSSIDInfo.h>

@interface IoTAirlinkConfigure ()

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
    self.textSSID.text = [[XPGWifiSSIDInfo SSIDInfo] objectForKey:@"SSID"];
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
    
    if(![[XPGWifiSDK sharedInstance] setAirLink:self.textSSID.text key:self.textKey.text])
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    else
    {
        MBProgressHUD *hud = AppDelegate.hud;
        hud.labelText = @"正在配置，请等待...";
        
        [hud showAnimated:YES whileExecutingBlock:^{
            usleep(200000);
            for(int i=0; i<430; i++)
            {
                if(hud.alpha == 0)
                    return;
                usleep(100000);
            }
            [self performSelectorOnMainThread:@selector(configTimedout) withObject:nil waitUntilDone:YES];
        }];
    }
}

- (void)configTimedout
{
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置超时" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
}

#pragma mark - delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didSetAirLink:(XPGWifiDevice *)device
{
    if(AppDelegate.hud.alpha == 1)
    {
        if([self.navigationController.viewControllers lastObject] == self)
        {
            [AppDelegate.hud hide:YES];
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"配置成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

@end
