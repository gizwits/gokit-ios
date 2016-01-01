//
//  IoTNewRegisterProcess.m
//  WiFiDemo
//
//  Created by ChaoSo on 15/9/16.
//  Copyright (c) 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTNewRegisterSendMessage.h"
#import "IoTNewEnterValidateNumViewController.h"

@interface IoTNewRegisterSendMessage ()<XPGWifiSDKDelegate>

@property (strong, nonatomic) NSString *validateToken;
@property (strong, nonatomic) IoTRegisterProcessModel *registerModel;

@property (weak, nonatomic) IBOutlet UITextField *sendValidatePhoneText;
@property (weak, nonatomic) IBOutlet UITextField *verifyValidateNum;
@property (weak, nonatomic) IBOutlet UIImageView *validateNumImageView;
@property (weak, nonatomic) IBOutlet UIButton *changeValidateNum;
@property (weak, nonatomic) IBOutlet UIButton *confirmSendMessage;

@end

@implementation IoTNewRegisterSendMessage


-(instancetype)initWithToForgetPassword:(BOOL)isForget
{
    self = [super init];
    if (self)
    {
        self.registerModel = [IoTRegisterProcessModel sharedModel];
        [self.registerModel removeAllData];
        
        self.registerModel.isForget = isForget;
    }
    return self;
}

#pragma mark - action
- (IBAction)onReloadCaptcha:(id)sender
{
    [self reloadCaptcha];
}
- (IBAction)onSendValidateNum:(id)sender
{
    NSString *validateNum = self.sendValidatePhoneText.text;
    if(validateNum.length != 11)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_am") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
        [self.sendValidatePhoneText becomeFirstResponder];
        return;
    }
    NSLog(@" token ========= %@  captchaId ===== %@",AppDelegate.token,self.registerModel.validateCaptchaId);
    [[XPGWifiSDK sharedInstance] requestSendPhoneSMSCode:self.registerModel.validateToken captchaId:self.registerModel.validateCaptchaId captchaCode:self.verifyValidateNum.text phone:validateNum];
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
            self.validateNumImageView.image = image;
        }
    }
}

-(void)wifiSDK:(XPGWifiSDK *)wifiSDK didRequestSendPhoneSMSCode:(NSError *)result
{
    if (!result.code)
    {
        self.registerModel.validateSendPhone = self.sendValidatePhoneText.text;
        IoTNewEnterValidateNumViewController *validateNumVc = [[IoTNewEnterValidateNumViewController alloc] init];
        [AppDelegate safePushController:validateNumVc animated:YES];
    }
    else if (result.code == 9037)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"提示") message:@"暂时无法获取，请稍后重试。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [self reloadCaptcha];
    }
    else
    {
        if(self.navigationController.viewControllers.lastObject == self){
            [[[UIAlertView alloc] initWithTitle:NSLS(@"register_tips") message:NSLS(@"register_identifyingCode") delegate:nil cancelButtonTitle:NSLS(@"register_confirm") otherButtonTitles:nil] show];
            [self reloadCaptcha];
        }
    }
}
-(void)reloadCaptcha
{
    [[XPGWifiSDK sharedInstance] getCaptchaCode:AppDelegate.appSecret];
}

// 按下键盘确认按钮后的动作
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(!self.registerModel.isForget){
        self.navigationItem.title = NSLS(@"register_newAccount");
    }else{
        self.navigationItem.title = NSLS(@"register_reset");
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
    [self reloadCaptcha];
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
