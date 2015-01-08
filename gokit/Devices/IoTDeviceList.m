/**
 * IoTDeviceList.m
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

#import "IoTDeviceList.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFNetworking.h>

#import "IoTLogin.h"
#import "IoTAirlinkConfigure.h"
#import <XPGWifiSDK/XPGWifiSDK.h>
#import <iToast.h>
#import "IoTDeviceController.h"

#define QR_SIMULATOR 0

/*
 wifi模式
 查找设备，如果找到设备，则是小循环，否则是大循环
 
 3G模式
 均为大循环
 */

@interface IoTDeviceList ()
{
    /*是否登录*/
    BOOL isDiscoverLock;
   
    XPGWifiDevice *selectedDevices;
    UIAlertView *_alertView;
}

@property (strong, nonatomic) NSArray *arrayList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign) BOOL isToasted;

@end

@implementation IoTDeviceList

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    iToastSettings *theSettings = [iToastSettings getSharedSettings];
    theSettings.duration = 3000;

    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(downloadBindListFormCloud)];
    UIImage *image = [UIImage imageNamed:@"align"];
    image = [IoTAppDelegate imageWithImage:image scaledToSize:CGSizeMake(25, 20)];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(rightMenu)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.rightBarButtonItem = rightItem;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"设备列表";
    
#if QR_SIMULATOR
    [self performSelector:@selector(qrcodeSimulator) withObject:nil afterDelay:1];
#endif
}

#if QR_SIMULATOR
- (void)qrcodeSimulator
{
    NSString *did = @"9H7oLSMq9CWxkhPiMnZGQH";
    NSString *passcode = @"123456";
    AppDelegate.hud.labelText = [NSString stringWithFormat:@"正在绑定%@...", selectedDevices.macAddress];
    [AppDelegate.hud show:YES];
    [[XPGWifiSDK sharedInstance] bindDeviceWithUid:AppDelegate.uid token:AppDelegate.token did:did passCode:passcode remark:nil];
}
#endif

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(nil != selectedDevices)
        [selectedDevices disconnect];
    
    [[AFNetworkReachabilityManager sharedManager] addObserver:self forKeyPath:@"networkReachabilityStatus" options:NSKeyValueObservingOptionNew context:nil];
    [self checkNetwokStatus];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [XPGWifiSDK sharedInstance].delegate = self;
    
    /*
     进入列表的时候下载一次
     */
    [self downloadBindListFormCloud];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([[UIDevice currentDevice].systemVersion floatValue] < 7.0)
        [self unLockList];
    
    [[AFNetworkReachabilityManager sharedManager] removeObserver:self forKeyPath:@"networkReachabilityStatus"];
    
    [XPGWifiSDK sharedInstance].delegate = nil;
    selectedDevices.delegate = nil;

    [self LockList];
    for(NSArray *section in self.arrayList)
        for(XPGWifiDevice *device in section)
            device.delegate = nil;
    [self unLockList];
    self.arrayList = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 列表部分
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *headers = @[@"", @"发现新设备", @"离线设备"];
    return headers[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [self LockList];
    NSArray *arrSection = self.arrayList[section];
    NSInteger count = arrSection.count;
    if(count == 0)
        count = 1;
    [self unLockList];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *idenetifier = @"IotDevice";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:idenetifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:idenetifier];
    
    /*
     重用，需要重新设置属性
     */
    cell.textLabel.text = @"";
    cell.textLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.text = @"";
    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.numberOfLines = 1;
    
    [self LockList];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:0xfff0];
    if(nil == label)
    {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.tag = 0xfff0;
        label.textAlignment = NSTextAlignmentRight;
        [cell.contentView addSubview:label];
    }
    
    label.textColor = [UIColor blackColor];
    label.frame = CGRectMake(160, 0, 140, 55);
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray *arrSection = self.arrayList[indexPath.section];
    if(indexPath.row + 1 > arrSection.count)
    {
        cell.textLabel.text = @"没有设备";
        label.text = @"";
    }
    else
    {
        XPGWifiDevice *device = arrSection[indexPath.row];
        cell.textLabel.text = device.productName;
        cell.detailTextLabel.text = device.macAddress;
        if(device.isLAN)
        {
            if(![device isBind:AppDelegate.uid])
            {
                label.text = @"未绑定";
            }
            else
            {
                label.text = @"局域网已连接";
            }
            label.frame = CGRectMake(160, 0, 130, 55);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else
        {
            if(!device.isOnline)
            {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.detailTextLabel.textColor = [UIColor grayColor];
                label.textColor = [UIColor grayColor];
                label.text = @"离线";
            }
            else
            {
                label.text = @"远程已连接";
                label.frame = CGRectMake(160, 0, 130, 55);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
    }
    
    [self unLockList];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(isDiscoverLock)
        return;
    [self LockList];
    
    //连接后不用解锁，等到收到连接事件后解锁
    NSArray *arrSection = self.arrayList[indexPath.section];
    selectedDevices = arrSection[indexPath.row];
    selectedDevices.delegate = self;

    if ([selectedDevices.passcode length]) {
        AppDelegate.hud.labelText = [NSString stringWithFormat:@"正在登录%@...", selectedDevices.macAddress];
        [AppDelegate.hud show:YES];
        [selectedDevices login:AppDelegate.uid token:AppDelegate.token];
    } else {
        if(selectedDevices.did.length == 0)
        {
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"此设备尚未与云端注册，无法绑定。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        }
        else
        {
            AppDelegate.hud.labelText = [NSString stringWithFormat:@"正在绑定%@...", selectedDevices.macAddress];
            [AppDelegate.hud show:YES];
            [[XPGWifiSDK sharedInstance] bindDeviceWithUid:AppDelegate.uid token:AppDelegate.token did:selectedDevices.did passCode:nil remark:nil];
        }
    }

    [self unLockList];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *arrSection = self.arrayList[indexPath.section];
    if(arrSection.count == 0)
        return NO;
    return YES;
}

#pragma mark - 加载数据
- (void)downloadBindListFormCloud
{
    //防止操作中点了以后卡主线程。
    if(isDiscoverLock)
        return;
    
    MBProgressHUD *hud = AppDelegate.hud;
    hud.labelText = @"正在加载云端列表...";
    [hud show:YES];
    
    [[XPGWifiSDK sharedInstance] getBoundDevicesWithUid:AppDelegate.uid token:AppDelegate.token specialProductKeys:IOT_PRODUCT, nil];
}

- (void)setArrayList:(NSArray *)arrayList
{
    [self LockList];
    [AppDelegate.hud hide:YES];
    
    //分类
    NSMutableArray
    *arr1 = [NSMutableArray array], //在线
    *arr2 = [NSMutableArray array], //新设备
    *arr3 = [NSMutableArray array]; //不在线
    
    for(XPGWifiDevice *device in arrayList)
    {
        if(device.isLAN && ![device isBind:AppDelegate.uid])
        {
            [arr2 addObject:device];
            continue;
        }
        if(device.isLAN || device.isOnline)
        {
            [arr1 addObject:device];
            continue;
        }
        [arr3 addObject:device];
    }
    
    _arrayList = @[arr1, arr2, arr3];
    [self unLockList];
    [self.tableView reloadData];
}

#pragma mark - 列表回调
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didDiscovered:(NSArray *)deviceList result:(int)result
{
    if(isDiscoverLock)
        return;
    
    for(XPGWifiDevice *device in deviceList)
        device.delegate = self;
    
    self.arrayList = deviceList;
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUpdateProduct:(NSString *)product result:(int)result
{
    if(result == -25)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if(self.isToasted == YES)
                return;
            self.isToasted = YES;
            iToast *toast = [iToast makeText:@"下载配置出错，请检查网络后再试。"];
            [toast performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            sleep(3);
            self.isToasted = NO;
        });
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUserLogin:(NSNumber *)error errorMessage:(NSString *)errorMessage uid:(NSString *)uid token:(NSString *)token
{
    NSLog(@"-----------------------> UserLogin result:%d", [error intValue]);
    if ([error intValue] || uid.length == 0 || token.length == 0) {
        NSLog(@"-----------------------> UserLogin errorMassage:%@", errorMessage);
        [AppDelegate.hud hide:YES];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        NSLog(@"-----------------------> UserLogin uid:%@ token:%@", uid, token);
        
        AppDelegate.uid = uid;
        AppDelegate.token = token;
        [self downloadBindListFormCloud];
    }
}

- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if([selectedDevices.macAddress isEqualToString:device.macAddress] &&
       [selectedDevices.did isEqualToString:device.did])
    {
        if(AppDelegate.hud.alpha == 1 && [AppDelegate.hud.labelText isEqualToString:@"登录中..."])
        {
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
        else if (AppDelegate.hud.alpha == 1 && [AppDelegate.hud.labelText isEqualToString:@"连接中..."])
        {
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"连接失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
        
        [AppDelegate.hud hide:YES];
//       NSLog(@"Disconnected device:%@, %@, %@, %@", device.macAddress, device.did, device.passcode, device.productKey);
        selectedDevices.delegate = nil;
        selectedDevices = nil;
    }
}

- (void)XPGWifiDevice:(XPGWifiDevice *)device didLogin:(int)result
{
    if([selectedDevices.macAddress isEqualToString:device.macAddress] &&
       [selectedDevices.did isEqualToString:device.did])
    {
        [AppDelegate.hud hide:YES];
        [self unLockList];
        if(result == 0)
        {
            @try {
                if(self.navigationController.viewControllers.lastObject == self)
                {
                    IoTDeviceController *controller = [[IoTDeviceController alloc] initWithDevice:selectedDevices];
                    if(controller != nil)
                    {
                        [self.navigationController pushViewController:controller animated:YES];
                    }
                    else
                    {
                        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"不支持此设备控制。若要使用控制，请配置相关文件。" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                        [selectedDevices disconnect];
                        selectedDevices = nil;
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"error:%@", exception);
            }
        }
        else
        {
            if(selectedDevices)
            {
                if(selectedDevices.isConnected)
                    [selectedDevices disconnect];
            }
            
            [_alertView dismissWithClickedButtonIndex:0 animated:NO];
            _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"登录失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [_alertView show];
        }
    }
}

- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didBindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    [AppDelegate.hud hide:YES];
    
    if (![error intValue]) {
        _alertView = [[UIAlertView alloc] initWithTitle:@"绑定成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    } else {
        _alertView = [[UIAlertView alloc] initWithTitle:@"绑定失败" message:errorMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    }
    
    [self downloadBindListFormCloud];
    
    [_alertView show];
}

#pragma mark - 设备列表锁
- (void)LockList
{
    while (isDiscoverLock) {
        usleep(1000);
    }
    isDiscoverLock = YES;
}

- (void)unLockList
{
    isDiscoverLock = NO;
}

#pragma mark - 菜单
- (void)rightMenu
{
    NSString *loginText = AppDelegate.isRegisteredUser && AppDelegate.username.length ? @"退出登录" : @"账号登录";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"添加设备",loginText,nil];
    actionSheet.tag = 0;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case 0://当前页面
        {
            switch (buttonIndex) {
                case 0://添加设备
                {
                    //添加新设备
                    if([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusReachableViaWiFi)
                    {
                        [_alertView dismissWithClickedButtonIndex:0 animated:NO];
                        _alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请切换到WiFi网络" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                        [_alertView show];
                    }
                    else
                    {
                        IoTAirlinkConfigure *airlink = [[IoTAirlinkConfigure alloc] init];
                        [self.navigationController pushViewController:airlink animated:YES];
                    }
                    break;
                }
                case 1://退出登录/账号登录
                {
                    if(AppDelegate.isRegisteredUser && AppDelegate.username.length)
                    {
                        //注销
                        AppDelegate.hud.labelText = @"正在注销...";
                        [AppDelegate.hud show:YES];
                        AppDelegate.username = nil;
                        AppDelegate.password = nil;
                        AppDelegate.uid = nil;
                        AppDelegate.token = nil;
                        AppDelegate.userType = IoTUserTypeAnonymous;
                        [AppDelegate userLogin];
                        break;
                    }
                    //登录
                    IoTLogin *login = [[IoTLogin alloc] init];
                    [self.navigationController pushViewController:login animated:YES];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - 检查网络
- (void)checkNetwokStatus
{
    //    NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus));
    switch ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus) {
        case AFNetworkReachabilityStatusReachableViaWiFi:
        case AFNetworkReachabilityStatusReachableViaWWAN:
        {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            self.navigationItem.rightBarButtonItem.enabled = YES;
            break;
        }
        case AFNetworkReachabilityStatusNotReachable:
        {
            self.navigationItem.leftBarButtonItem.enabled = NO;
            self.navigationItem.rightBarButtonItem.enabled = NO;
            break;
        }
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"networkReachabilityStatus"])
        [self checkNetwokStatus];
}

#pragma mark - 其他
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
        [self.navigationController popViewControllerAnimated:YES];
}

@end