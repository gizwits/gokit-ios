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
#import "IoTGokitConfigureTypeSelection.h"
#import "IoTGokitConfigureTypeCell.h"

@interface IoTAirlinkConfigure () <UITextFieldDelegate, IoTGokitConfigureTypeSelectionDelegate>

@property (strong, nonatomic) UILabel *labelSSID;
@property (strong, nonatomic) UITextField *textPassword;

//配置类型
@property (assign, nonatomic) BOOL isGagentTypeSet;
@property (assign, nonatomic) XPGWifiGAgentType gagentType;
@property (assign, nonatomic) IoTGokitConfigureTypeCell *configureTypeCell;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation IoTAirlinkConfigure

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = NSLS(@"gokit_airlink_title");
    
    [XPGWifiSDK sharedInstance].delegate = self;
    
    //当前SSID信息
    UILabel *labelSSID = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160, 30)];
    
    //当前密码
    UITextField *textPassword = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 160, 30)];
    textPassword.borderStyle = UITextBorderStyleRoundedRect;
    textPassword.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.textPassword = textPassword;
    self.labelSSID = labelSSID;
    
    self.tapGesture.cancelsTouchesInView = NO;
    self.tableView.scrollEnabled = NO;
    
    //把左边的按钮变成 <返回
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"        " style:UIBarButtonItemStyleBordered target:self action:nil];
    self.navigationItem.rightBarButtonItem = newBackButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [XPGWifiSDK sharedInstance].delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
#if TARGET_IPHONE_SIMULATOR
    self.labelSSID.text = @"Airport";
#else
    self.labelSSID.text = [[IoTWifiUtil SSIDInfo] objectForKey:@"SSID"];
#endif
    //zonozhang
//    self.textPassword.text = AppDelegate.airlinkPass;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didBecomeActive
{
    self.labelSSID.text = [[IoTWifiUtil SSIDInfo] objectForKey:@"SSID"];
    [XPGWifiSDK sharedInstance].delegate = self;
}

- (IBAction)onConfigure:(id)sender {
    if(![AFNetworkReachabilityManager sharedManager].reachableViaWiFi)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"gokit_airlink_tips") message:NSLS(@"gokit_airlink_not_in_wifi") delegate:nil cancelButtonTitle:NSLS(@"gokit_airlink_confirm") otherButtonTitles:nil] show];
        return;
    }
    
    if(self.labelSSID.text.length == 0)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"gokit_airlink_tips") message:NSLS(@"gokit_airlink_ssid_empty") delegate:nil cancelButtonTitle:NSLS(@"gokit_airlink_confirm") otherButtonTitles:nil] show];
        return;
    }
    //zonozhang
//    AppDelegate.lastSSID = self.labelSSID.text;
//    AppDelegate.airlinkPass = self.textPassword.text;
    
    [self.textPassword resignFirstResponder];
    
    //配置类型没有选择的时候，给提示
    if(!self.isGagentTypeSet)
    {
        [[[UIAlertView alloc] initWithTitle:NSLS(@"gokit_airlink_tips") message:NSLS(@"gokit_airlink_message_type_select") delegate:nil cancelButtonTitle:NSLS(@"gokit_airlink_confirm") otherButtonTitles:nil] show];
        return;
    }
    
    [self.labelSSID resignFirstResponder];
    [self.textPassword resignFirstResponder];
    AppDelegate.hud.labelText = @"正在配置...";
    [AppDelegate.hud show:YES];

//    NSLog(@"==== %@,%@,%@", self.labelSSID.text, self.textPassword.text, @[@(self.gagentType)]);
    
    [[XPGWifiSDK sharedInstance] setDeviceWifi:self.labelSSID.text key:self.textPassword.text mode:XPGWifiSDKAirLinkMode softAPSSIDPrefix:nil timeout:60 wifiGAgentType:@[@(self.gagentType)]];
}

- (IBAction)onTap:(UITapGestureRecognizer *)sender {
    [self.textPassword resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self onConfigure:nil];
    return YES;
}

#pragma mark - delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL configureType = indexPath.row == 0;
    NSString *identifier = @"configureIdentifier";
    
    if(configureType)
        identifier = @"configureTypeIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(nil == cell)
    {
        if(configureType)
        {
            UINib *nib = [UINib nibWithNibName:@"IoTGokitConfigureTypeCell" bundle:nil];
            if(nib)
            {
                [tableView registerNib:nib forCellReuseIdentifier:identifier];
                cell = [tableView dequeueReusableCellWithIdentifier:identifier];
                self.configureTypeCell = (IoTGokitConfigureTypeCell *)cell;
            }
        }
        else
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    
    switch (indexPath.row) {
        case 1:
            cell.textLabel.text = @"";
            cell.backgroundColor = [UIColor clearColor];
            break;
        case 2:
        {
            cell.textLabel.text = NSLS(@"gokit_airlink_label_ssid");
            cell.accessoryView = self.labelSSID;
            break;
        }
        case 3:
        {
            cell.textLabel.text = NSLS(@"gokit_airlink_label_password");
            cell.accessoryView = self.textPassword;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 1)
        return 20;
    return 44;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row > 0)
        return NO;
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.row == 0)
    {
        IoTGokitConfigureTypeSelection *typeSelectionCtrl = [[IoTGokitConfigureTypeSelection alloc] initWithDelegate:self];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] init];
        backItem.title = @"返回";
        self.navigationItem.backBarButtonItem = backItem;
        //zonozhang
        //AppDelegate.airlinkPass = self.textPassword.text;
        [AppDelegate safePushController:typeSelectionCtrl animated:YES];
    }
}

- (void)iotGokitConfigureTypeDidSelectType:(XPGWifiGAgentType)gagentType displayName:(NSString *)name
{
    self.gagentType = gagentType;
    self.configureTypeCell.labelStatus.text = name;
    self.isGagentTypeSet = YES;
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
