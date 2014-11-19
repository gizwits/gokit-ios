/**
 * IoTDeviceAP.m
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

#import "IoTDeviceAP.h"
#import "LMAlertView.h"
#import "IoTWaitForConfigureAP.h"
#import <XPGWifiSDK/XPGWifiSDK.h>

@interface IoTDeviceAP ()
{
    BOOL isTextAnimated;
    NSTimer *timer;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) NSArray *arraylist;

@end

@implementation IoTDeviceAP

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
    self.navigationItem.title = @"Soft AP 模式";
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [XPGWifiSDK sharedInstance].delegate = self;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(loadSSID:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [XPGWifiSDK sharedInstance].delegate = nil;
    
    if(timer)
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 每隔 3 秒读取一次 SSID 列表
- (void)loadSSID:(NSTimer *)timer
{
    [[XPGWifiSDK sharedInstance] getSSIDList];
}

#pragma mark - 回调
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arraylist.count+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"Device AP List";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    if(indexPath.row == self.arraylist.count)
    {
        cell.textLabel.text = @"其他";
    }
    else
    {
        XPGWifiSSID *ssid = self.arraylist[indexPath.row];
        cell.textLabel.text = ssid.name;
        
        int rssiLevel = 0;
        if(ssid.rssi > 75)
            rssiLevel = 4;
        else if(ssid.rssi > 50)
            rssiLevel = 3;
        else if(ssid.rssi > 25)
            rssiLevel = 2;
        else
            rssiLevel = 1;
        
        NSString *file = [NSString stringWithFormat:@"rssi_%i@2x", rssiLevel];
        UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:file ofType:@"png"]];
        cell.accessoryView = [[UIImageView alloc] initWithImage:image];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    if(indexPath.row == self.arraylist.count)
    {
        NSString *message = @"\n\n\n";
        if([UIDevice currentDevice].systemVersion.floatValue < 7.0)
        {
            message = @"\n\n";
        }
        LMAlertView *alert = [[LMAlertView alloc] initWithTitle:@"test" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        UIView *contentView = alert.contentView;
        UILabel *labelSSID = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 50, 20)];
        labelSSID.text = @"SSID";
        [contentView addSubview:labelSSID];
        
        UILabel *labelPassword = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 50, 20)];
        labelPassword.text = @"密码";
        [contentView addSubview:labelPassword];
        
        UITextField *textSSID = [[UITextField alloc] initWithFrame:CGRectMake(60, 51, 200, 20)];
        textSSID.tag = 10;
        textSSID.delegate = self;
        [contentView addSubview:textSSID];
        
        UITextField *textPass = [[UITextField alloc] initWithFrame:CGRectMake(60, 81, 200, 20)];
        textPass.tag = 11;
        textPass.delegate = self;
        [contentView addSubview:textPass];
        
        if([UIDevice currentDevice].systemVersion.floatValue < 7.0)
        {
            CGRect frame = textSSID.frame;
            frame.origin.y -= 2;
            textSSID.frame = frame;
            textSSID.font = [UIFont systemFontOfSize:16];
            
            frame = textPass.frame;
            frame.origin.y -= 2;
            textPass.frame = frame;
            textPass.font = [UIFont systemFontOfSize:16];
        }
        [alert show];
    }
    else
    {
        XPGWifiSSID *ssid = self.arraylist[indexPath.row];
        
        //配置AP
        LMAlertView *alert = [[LMAlertView alloc] initWithTitle:@"test" message:@"\n\n\n" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        UIView *contentView = alert.contentView;
        UILabel *labelSSID = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, 50, 20)];
        labelSSID.text = @"SSID";
        [contentView addSubview:labelSSID];
        
        UILabel *labelPassword = [[UILabel alloc] initWithFrame:CGRectMake(10, 80, 50, 20)];
        labelPassword.text = @"密码";
        [contentView addSubview:labelPassword];
        
        UILabel *textSSID = [[UILabel alloc] initWithFrame:CGRectMake(60, 51, 200, 20)];
        textSSID.tag = 10;
        textSSID.text = ssid.name;
        [contentView addSubview:textSSID];
        
        UITextField *textPass = [[UITextField alloc] initWithFrame:CGRectMake(60, 81, 200, 20)];
        textPass.tag = 11;
        textPass.delegate = self;
        [contentView addSubview:textPass];
        
        [alert show];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *contentView = textField.superview;
    LMAlertView *alertView = (LMAlertView *)contentView.superview;
    isTextAnimated = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = alertView.frame;
        frame.origin.y = 80;
        alertView.frame = frame;
    } completion:^(BOOL finished) {
        isTextAnimated = YES;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //100ms以内如果没有begin则close
        for(int i=0; i<100; i++)
        {
            usleep(1000);//1ms
            if(!isTextAnimated)
            {
                return;
            }
        }
        [self performSelectorOnMainThread:@selector(textEndAnimation:) withObject:textField waitUntilDone:NO];
    });
}

- (void)textEndAnimation:(UITextField *)textField
{
    NSLog(@"textEndAnimation");
    if(!isTextAnimated)
        return;
    UIView *contentView = textField.superview;
    LMAlertView *alertView = (LMAlertView *)contentView.superview;
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = alertView.frame;
        frame.origin.y = 161;
        alertView.frame = frame;
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        LMAlertView *_alertView = (LMAlertView *)alertView;
        
        NSString *ssid = ((UITextField *)[_alertView.contentView viewWithTag:10]).text;
        NSString *key = ((UITextField *)[_alertView.contentView viewWithTag:11]).text;
        
        if(ssid.length == 0 || key.length == 0)
        {
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"SSID 或密码不能为空" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
            return;
        }
        
        //配置AP
        IoTWaitForConfigureAP *waitCfg = [[IoTWaitForConfigureAP alloc] init];
        waitCfg.ssid = ssid;
        waitCfg.key = key;
        [self.navigationController pushViewController:waitCfg animated:YES];
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didGetSSIDList:(NSArray *)ssidList result:(int)result
{
    if(result == 0)
    {
        self.arraylist = ssidList;
        [self.tableView reloadData];
    }
}

@end
