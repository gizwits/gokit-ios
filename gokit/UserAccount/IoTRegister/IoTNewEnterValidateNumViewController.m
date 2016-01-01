//
//  IoTNewEnterValidateNumViewController.m
//  WiFiDemo
//
//  Created by ChaoSo on 15/9/17.
//  Copyright (c) 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTNewEnterValidateNumViewController.h"
#import "IoTRegisterPasswordViewController.h"
#import "IoTDeviceList.h"

@interface IoTNewEnterValidateNumViewController ()<XPGWifiSDKDelegate>
{
    NSUInteger verifyCodeCounter;
    NSTimer *verifyCountTimer;
}
@property (strong, nonatomic) IoTRegisterProcessModel *registerModel;
@property (strong, nonatomic) NSString *validatePhoneNum;
@property (strong, nonatomic) NSString *validateToken;
@property (weak, nonatomic) IBOutlet UITextField *passwordText;
@property (weak, nonatomic) IBOutlet UITextField *recheckNewPasswordText;


@property (weak, nonatomic) IBOutlet UIView *reloadView;
@property (weak, nonatomic) IBOutlet UILabel *validatePhoneNumText;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeText;
@property (weak, nonatomic) IBOutlet UIButton *confirmVerifyButton;
@property (weak, nonatomic) IBOutlet UIButton *reloadVerifyCodeButton;

@property (weak, nonatomic) IBOutlet UITextField *verifyCodeInAlertViewText;
@property (weak, nonatomic) IBOutlet UIImageView *verifyCodeInAlertViewImageView;
@property (weak, nonatomic) IBOutlet UILabel *warningInAlertView;
- (IBAction)onVerifyCodeInAlertViewReloadButton:(id)sender;



@end

@implementation IoTNewEnterValidateNumViewController

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.registerModel = [IoTRegisterProcessModel sharedModel];
        
        self.validatePhoneNum = self.registerModel.validateSendPhone;
        self.validateToken = self.registerModel.validateToken;
    }
    return self;
}

#pragma mark - action
- (IBAction)onConfirmVerify:(id)sender {
    if([[self.verifyCodeText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0){
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_lengthFail_verifyCode_empty") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        self.verifyCodeText.text = @"";
        return;
    }
    if([[self.verifyCodeText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] < 6){
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_lengthFail_verifyCode") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        self.verifyCodeText.text = @"";
        return;
    }
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
            [[XPGWifiSDK sharedInstance] changeUserPasswordByCode:self.validatePhoneNum code:self.verifyCodeText.text newPassword:self.passwordText.text];
        }
    }
    else
    {
        [[XPGWifiSDK sharedInstance] registerUserByPhoneAndCode:self.validatePhoneNum password:self.passwordText.text code:self.verifyCodeText.text];
    }

}
- (IBAction)onReloadVerifyCode:(id)sender {
    [self reloadCaptcha];
    [self.reloadView setHidden:NO];
}

- (IBAction)onConfirmResendMessage:(id)sender {
    [[XPGWifiSDK sharedInstance] requestSendPhoneSMSCode:self.registerModel.validateToken captchaId:self.registerModel.validateCaptchaId captchaCode:self.verifyCodeInAlertViewText.text phone:self.validatePhoneNum];
}
- (IBAction)onVerifyCodeInAlertViewReloadButton:(id)sender {
    [self reloadCaptcha];
    self.warningInAlertView.text = @"";
}

- (IBAction)onHideAlertView:(id)sender {
    [self.reloadView setHidden:YES];
}
#pragma mark - delegate
-(void)wifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result
{
    if (!result.code)
    {
        [self startCountDownForVerifyCodeButton];
        [self.reloadView setHidden:YES];
    }
    else if (result.code == 9037)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"提示") message:@"暂时无法获取，请稍后重试。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [self reloadCaptcha];
    }
    else
    {
        if(self.navigationController.viewControllers.lastObject == self){
            self.warningInAlertView.text = NSLS(@"warning_incorrect_code");
            [self reloadCaptcha];
        }
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
                message = NSLS(@"new_register_unavailablePhone");
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


-(void)wifiSDK:(XPGWifiSDK *)wifiSDK didGetCaptchaCode:(NSError *)result token:(NSString *)token captchaId:(NSString *)captchaId captchaURL:(NSString *)captchaURL
{
    if (!result.code)
    {
        self.registerModel.validateToken = token;
        self.registerModel.validateCaptchaId = captchaId;
        
        NSURL* url = [NSURL URLWithString:[captchaURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];//网络图片url
        NSData* data = [NSData dataWithContentsOfURL:url];//获取网咯图片数据
        if(data!=nil)
        {
            UIImage *image = [[UIImage alloc] initWithData:data];//根据图片数据流构造image
            self.verifyCodeInAlertViewImageView.image = image;
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
            case 9005:
                message = NSLS(@"register_userDoesNotExist");
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
            
            //返回到设备列表页面
            [AppDelegate safePopController:YES currentViewController:nil];
        }
    }
}

#pragma mark - Others
// 验证码重复获取等待
- (void)refreshVerifyCodeButton
{
    if(verifyCodeCounter == 0)
    {
        [self counterTimerInvalidate];
        self.reloadVerifyCodeButton.enabled = true;
        [self.reloadVerifyCodeButton setTitle:NSLS(@"register_reloadVerifyCode") forState:UIControlStateNormal];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:NSLS(@"register_wait2"), (int)verifyCodeCounter];
    self.reloadVerifyCodeButton.enabled = true;
    [self.reloadVerifyCodeButton setTitle:title forState:UIControlStateNormal];
    self.reloadVerifyCodeButton.enabled = false;
    
    verifyCodeCounter--;
}
-(void)startCountDownForVerifyCodeButton
{
    self.verifyCodeInAlertViewText.text = @"";
    [self counterTimerInvalidate];
    verifyCodeCounter = 59;
    verifyCountTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refreshVerifyCodeButton) userInfo:nil repeats:YES];
}
-(void)reloadCaptcha
{
    [[XPGWifiSDK sharedInstance] getCaptchaCode:AppDelegate.appSecret];
}

-(void)counterTimerInvalidate
{
    [verifyCountTimer invalidate];
    verifyCountTimer = nil;
}

// 按下键盘确认按钮后的动作
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark  - ViewController Flow
- (void)viewDidLoad {
    [super viewDidLoad];
    self.validatePhoneNumText.text = self.validatePhoneNum;
    if(!self.registerModel.isForget){
        self.navigationItem.title = NSLS(@"register_newAccount");
        self.recheckNewPasswordText.hidden = YES;
        
    }else{
        self.navigationItem.title = NSLS(@"register_reset");
        self.recheckNewPasswordText.hidden = NO;
        self.passwordText.placeholder = @"新密码";
    }
    [self.reloadView setHidden:YES];
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
    [self counterTimerInvalidate];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self refreshVerifyCodeButton];
    [self startCountDownForVerifyCodeButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
