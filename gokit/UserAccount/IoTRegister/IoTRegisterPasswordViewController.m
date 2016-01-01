//
//  IoTRegisterPasswordViewController.m
//  WiFiDemo
//
//  Created by ChaoSo on 15/9/17.
//  Copyright (c) 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTRegisterPasswordViewController.h"
#import "IoTDeviceList.h"

@interface IoTRegisterPasswordViewController ()<XPGWifiSDKDelegate>

@property (strong, nonatomic) IoTRegisterProcessModel *registerModel;
@property (strong, nonatomic) NSString *validatePhoneNum;
@property (strong, nonatomic) NSString *validateCode;

@property (weak, nonatomic) IBOutlet UITextField *passwordText;
@property (weak, nonatomic) IBOutlet UITextField *recheckNewPasswordText;
- (IBAction)onRegister:(id)sender;
@end

@implementation IoTRegisterPasswordViewController

-(instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.registerModel = [IoTRegisterProcessModel sharedModel];
        
        self.validatePhoneNum = self.registerModel.validateSendPhone;
        self.validateCode = self.registerModel.verifyCode;
    }
    return self;
}
- (IBAction)onRegister:(id)sender {
    if([[self.passwordText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0){
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_lengthFail_empty") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        self.passwordText.text = @"";
        return;
    }
    if([[self.passwordText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] < 6){
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_lengthFail") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        self.passwordText.text = @"";
        return;
    }
    if (self.registerModel.isForget)
    {
        if (![self.passwordText.text isEqualToString:self.recheckNewPasswordText.text])
        {
            [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_failed") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
            self.passwordText.text = @"";
            self.recheckNewPasswordText.text = @"";
            return ;
        }
        else
        {
            [[XPGWifiSDK sharedInstance] changeUserPasswordByCode:self.validatePhoneNum code:self.validateCode newPassword:self.passwordText.text];
        }
    }
    else
    {
         [[XPGWifiSDK sharedInstance] registerUserByPhoneAndCode:self.validatePhoneNum password:self.passwordText.text code:self.validateCode];
    }
}

-(void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK
  didRegisterUser:(NSNumber *)error
     errorMessage:(NSString *)errorMessage
              uid:(NSString *)uid
            token:(NSString *)token
{
    int errorValue = [error intValue];
    if(errorValue)
    {
        NSString *message = errorMessage;
        switch (errorValue) {
            case 9010:
                message = NSLS(@"register_identifyingCodeFailed");
                break;
            case 9018:
                message = NSLS(@"register_phoneAlreadyExists");
                break;
            default:
                message = NSLS(@"register_fail");
                break;
        }
        if(self.navigationController.viewControllers.lastObject == self){
            [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:message delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        }
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_success") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        
        UITextField *textPhone = (UITextField *)[self.view viewWithTag:1];
        UITextField *textPassword = (UITextField *)[self.view viewWithTag:3];
        
        //保存相关信息
        AppDelegate.uid = uid;
        AppDelegate.token = token;
        AppDelegate.result = error;
        AppDelegate.username = textPhone.text;
        AppDelegate.password = textPassword.text;
        AppDelegate.userType = IoTUserTypeNormal;
        
        //返回到设备列表页面
        for(UIViewController *view in self.navigationController.viewControllers)
        {
            if([view isKindOfClass:[IoTDeviceList class]])
            {
                [AppDelegate safePushController:view animated:YES];
            }
        }
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
                message = NSLS(@"register_identifyingCodeFailed");
                break;
            default:
                break;
        }
        if(self.navigationController.viewControllers.lastObject == self){
            [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:message delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        }
    }
    else
    {
        if(self.navigationController.viewControllers.lastObject == self){
            [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_resetScs") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        }
        //返回到设备列表页面
        [AppDelegate safePopController:YES currentViewController:self];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(!self.registerModel.isForget){
        self.navigationItem.title = NSLS(@"register_newAccount");
        self.recheckNewPasswordText.hidden = YES;

    }else{
        self.navigationItem.title = NSLS(@"register_reset");
        self.recheckNewPasswordText.hidden = NO;
        self.passwordText.placeholder = @"新密码";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
