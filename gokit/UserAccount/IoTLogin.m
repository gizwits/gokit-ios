//
//  IoTLogin.m
//  WiFiDemo
//
//  Created by xpg on 14-6-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTLogin.h"
#import <MBProgressHUD/MBProgressHUD.h>

#import <XPGWifiSDK/XPGWifiSDK.h>
#import "IoTRegister.h"

@interface IoTLogin ()

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
}

- (IBAction)forgetPassword:(id)sender {
    IoTRegister *fp = [[IoTRegister alloc] initWithForgetMode];
    [self.navigationController pushViewController:fp animated:YES];
}

- (void)onRegister
{
    IoTRegister *reg = [[IoTRegister alloc] init];
    [self.navigationController pushViewController:reg animated:YES];
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
