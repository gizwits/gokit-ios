//
//  IoTAddDeviceViewController.m
//  WiFiDemo
//
//  Created by xpg on 14-6-9.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTAddDeviceViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface IoTAddDeviceViewController ()
{
    NSTimer *timer;
    BOOL isConnectToMQTT;
}

@property (weak, nonatomic) IBOutlet UILabel *textPasscode;

@end

@implementation IoTAddDeviceViewController

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
    self.title = self.device.productName; //@"未知设备";
    
    UIImage *image = [UIImage imageNamed:@"align"];
    image = [IoTAppDelegate imageWithImage:image scaledToSize:CGSizeMake(25, 20)];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(rightMenu)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    self.navigationItem.title = self.title;
    self.textView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    self.textView.layer.borderWidth = 1;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.device.delegate = self;
    [XPGWifiSDK sharedInstance].delegate = self;
    
    if(self.device)
    {
        self.did = self.device.did;
        self.productkey = self.device.productKey;
    }
    else
    {
        self.passcode = self.passcode;
    }
    
    if (self.passcode.length == 0 && self.device) {
        [self.device getHardwareInfo];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.device.delegate = nil;
    [XPGWifiSDK sharedInstance].delegate = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Passcode
- (void)queryPasscode:(id)sender
{
    if(self.device.passcode.length == 0) {
        [self.device getPasscodeFromDevice];
    } else {
        [self setPasscode:self.device.passcode];
    }
}

- (void)setPasscode:(NSString *)passcode
{
    _passcode = passcode;
    int result = _passcode.length > 0?0:-1;
    if(result == 0)
    {
        NSLog(@"query passcode succeed");
        self.textPasscode.text = @"已获取";
        //如果已注册用户，自动绑定
        if(AppDelegate.isRegisteredUser && self.isViewLoaded)
        {
            MBProgressHUD *hud = AppDelegate.hud;
            hud.labelText = @"绑定到服务器...";
            [hud show:YES];
            
            [timer invalidate];
            timer = nil;
            
            [[XPGWifiSDK sharedInstance] bindDeviceWithUid:AppDelegate.uid token:AppDelegate.token did:self.did passCode:self.passcode];
        }
        
    }
    else
        self.textPasscode.text = @"未获取";
}

#pragma mark - Menu
- (void)rightMenu
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"绑定设备" otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0://登录并绑定账号
        {
            if(self.device)
                [timer invalidate];
            timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(queryPasscode:) userInfo:nil repeats:YES];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Delegates
- (void)XPGWifiDevice:(XPGWifiDevice *)device didQueryHardwareInfo:(NSDictionary *)hwInfo {
    
    NSString *hardWareInfo = [NSString stringWithFormat:@"WiFi Hardware Version: %@\n\
WiFi Software Version: %@\n\
MCU Hardware Version: %@\n\
MCU Software Version: %@\n\
Firmware Id: %@\n\
Firmware Version: %@\n\
Product Key: %@\n\
Device ID: %@\n", [hwInfo valueForKey:XPGWifiDeviceHardwareWifiHardVerKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareWifiSoftVerKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareMCUHardVerKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareMCUSoftVerKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareFirmwareIdKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareFirmwareVerKey]
                              , [hwInfo valueForKey:XPGWifiDeviceHardwareProductKey], self.device.did];
    [self.textView performSelectorOnMainThread:@selector(setText:) withObject:hardWareInfo waitUntilDone:NO];
}

- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if([device isEqualToDevice:self.device])
    {
        if(!isConnectToMQTT)
        {
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"连接已断开" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self.device connectToMQTT];
            isConnectToMQTT = NO;
        }
    }
}

- (void)XPGWifiDevice:(XPGWifiDevice *)device didGetPasscode:(int)result
{
    [self setPasscode:device.passcode];
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    if(self.device && ![self.device.did isEqualToString:did])
        return;
    
    if(!self.device && ![self.did isEqualToString:did])
        return;
    
    [AppDelegate.hud hide:YES];
    if([error intValue])
    {
        int errcode = [error intValue];
        if(errcode != -24)
        {
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"绑定失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        }
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"绑定成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
