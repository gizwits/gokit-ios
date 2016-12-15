//
//  DeviceListViewController.m
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosDeviceListViewController.h"
#import "GosCommon.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import <AVFoundation/AVFoundation.h>
#import "QRCodeController.h"
#import "AppDelegate.h"
#import "GosSettingsViewController.h"
#import "GosDeviceListCell.h"

#import "GosPushManager.h"
#import "GosAnonymousLogin.h"
#import "GosCommon.h"

#import <TargetConditionals.h>

@interface GosDeviceListViewController () <UIActionSheetDelegate, GizWifiSDKDelegate, GizWifiDeviceDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation GosDeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
    [self.navigationController.navigationBar setHidden:NO];
    self.deviceListArray = @[@[],@[],@[]];
//    if (![GizCommon sharedInstance].isLogin) {
//        self.navigationItem.leftBarButtonItem = nil;
//        self.navigationItem.hidesBackButton = YES;
//    }
    if ([GosCommon sharedInstance].anonymousLoginOn) {
        GosAnonymousLoginStatus lastLoginStatus = [GosAnonymousLogin lastLoginStatus];
        if ([GosCommon sharedInstance].currentLoginStatus == GizLoginNone || lastLoginStatus == GosAnonymousLoginStatusLogout) {
            GosDidLogin loginHandler = ^(NSError *result, NSString *uid, NSString *token) {
                if (result.code == GIZ_SDK_SUCCESS) {
//                    [GizCommon sharedInstance].hasBeenLoggedIn = YES;
                    NSString *info = [NSString stringWithFormat:@"%@，%@ - %@", NSLocalizedString(@"Login successful", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
                    GIZ_LOG_BIZ("userLoginAnonymous_end", "success", "%s", info.UTF8String);
                    [[GosCommon sharedInstance] saveUserDefaults:nil password:nil uid:uid token:token];
                    [GosPushManager unbindToGDMS:NO];
                    [GosPushManager bindToGDMS];
                }
                else {
                    [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
                    NSString *info = [NSString stringWithFormat:@"%@，%@ - %@", NSLocalizedString(@"Login failed", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
                    GIZ_LOG_BIZ("userLoginAnonymous_end", "failed", "%s", info.UTF8String);
                    double delayInSeconds = 3.0;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        if ([GosCommon sharedInstance].currentLoginStatus == GizLoginNone) {
                            [GosAnonymousLogin loginAnonymous:loginHandler];
                            [[GizWifiSDK sharedInstance] userLoginAnonymous];
                        }
                    });
                }
            };
            [GosAnonymousLogin loginAnonymous:loginHandler];
        }
    }
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(actionSheet:)];
    
    [self.addDeviceLabelBtn.layer setCornerRadius:20.0];
    [self.addDeviceLabelBtn.layer setBorderWidth:1.0];
    self.addDeviceLabelBtn.layer.borderColor=[UIColor grayColor].CGColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [GizWifiSDK sharedInstance].delegate = self;
    if (self.needRefresh) {
        [self refreshBtnPressed:nil];
        self.needRefresh = NO;
    }
    else {
        [self refreshTableView];
    }
}

- (IBAction)refreshBtnPressed:(id)sender {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self getBoundDevice];
}

- (void)getBoundDevice {
    NSString *uid = [GosCommon sharedInstance].uid;
    NSString *token = [GosCommon sharedInstance].token;
    if (uid.length == 0) {
        uid = nil;
    }
    if (token.length == 0) {
        token = nil;
    }
    [[GizWifiSDK sharedInstance] getBoundDevices:uid token:token specialProductKeys:[GosCommon sharedInstance].productKey];
}

- (IBAction)actionSheet:(id)sender {
    UIActionSheet *actionSheet = nil;
    if ([GosCommon sharedInstance].currentLoginStatus == GizLoginUser) {
        actionSheet = [[UIActionSheet alloc]
                                      initWithTitle:nil
                                      delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                      destructiveButtonTitle:nil
                                      otherButtonTitles:NSLocalizedString(@"Scan QR code", nil), NSLocalizedString(@"Add Device", nil), NSLocalizedString(@"Setting", nil), NSLocalizedString(@"Logout", nil), nil];
    }
    else {
        actionSheet = [[UIActionSheet alloc]
                       initWithTitle:nil
                       delegate:self
                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                       destructiveButtonTitle:nil
                       otherButtonTitles:NSLocalizedString(@"Scan QR code", nil), NSLocalizedString(@"Add Device", nil), NSLocalizedString(@"Setting", nil), NSLocalizedString(@"Login", nil), nil];
    }
    
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [actionSheet showInView:self.view];
}

#pragma mark - actionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger offset = 0;
//    if (![GizCommon sharedInstance].isLogin) {
//        offset = -1;
//    }
    if (buttonIndex == offset) {
        [self intoQRCodeVC];
    }else if (buttonIndex == offset+1) {
        [self toAirLink:nil];
    }else if(buttonIndex == offset+2) {
        [self toSettings];
    }else if(buttonIndex == offset+3) {
        [self onUserLogout];
    }
}

-(void)showAlert:(NSString *)msg {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"tip", nil)
                          message:msg
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles: nil];
    [alert show];
}

- (void)onUserLogout {
    if ([GosCommon sharedInstance].currentLoginStatus == GizLoginUser) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Logout?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        [alertView show];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [GosPushManager unbindToGDMS:YES];
            self.deviceListArray  = @[@[],@[],@[]];
            [[GosCommon sharedInstance] removeUserDefaults];
            if ([GosCommon sharedInstance].anonymousLoginOn) {
                [GosAnonymousLogin logout];
            }
            [self.navigationController popToViewController:self.parent animated:YES];
        });
    }
}

- (void)refreshTableView {
    NSArray *devList = [GizWifiSDK sharedInstance].deviceList;
    if ([devList count] == 0) {
        [self.addDeviceImageBtn setHidden:NO];
        [self.addDeviceLabelBtn setHidden:NO];
    }
    else {
        [self.addDeviceImageBtn setHidden:YES];
        [self.addDeviceLabelBtn setHidden:YES];
    }
    NSMutableArray *deviceListBind = [[NSMutableArray alloc] init];
    NSMutableArray *deviceListUnBind = [[NSMutableArray alloc] init];
    NSMutableArray *deviceListOffLine = [[NSMutableArray alloc] init];
    for (GizWifiDevice *dev in devList) {
        if (dev.netStatus == GizDeviceOnline || dev.netStatus == GizDeviceControlled) {
            if (dev.isBind) {
                [deviceListBind addObject:dev];
            }
            else {
                [deviceListUnBind addObject:dev];
            }
        }
        else [deviceListOffLine addObject:dev];
    }
    self.deviceListArray = @[deviceListBind, deviceListUnBind, deviceListOffLine];
    [self.deviceListTableView reloadData];
}

#pragma mark - alert view
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        [GosPushManager unbindToGDMS:YES];
        self.deviceListArray  = @[@[],@[],@[]];
        [[GosCommon sharedInstance] removeUserDefaults];
        [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
        [self.navigationController popToViewController:self.parent animated:YES];
    }
}

#pragma mark - table view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self.deviceListArray objectAtIndex:indexPath.section] count] == 0) {
        return 60;
    }
    return 80;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[self.deviceListArray objectAtIndex:0] count] == 0 &&
        [[self.deviceListArray objectAtIndex:1] count] == 0 &&
        [[self.deviceListArray objectAtIndex:2] count] == 0) {
        return 0;
    }
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[self.deviceListArray objectAtIndex:section] count] == 0) {
        return 1;
    }
    return [[self.deviceListArray objectAtIndex:section] count];
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return NSLocalizedString(@"Bound devices", nil);
    else if (section == 1) return NSLocalizedString(@"Discovery of new devices", nil);
    else return NSLocalizedString(@"Offline devices", nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GosDeviceListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CellIdentifier"];
        cell = [[[NSBundle mainBundle] loadNibNamed:@"GosDeviceListCell" owner:self options:nil] lastObject];
//        UILabel *lanLabel = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 110, 0, 74, 80)];
//        lanLabel.textAlignment = NSTextAlignmentRight;
//        lanLabel.tag = 99;
//        [cell addSubview:lanLabel];
    }
    
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    /*
    UILabel *lanLabel = nil;
    for (UILabel *label in cell.subviews) {
        if (label.tag == 99) {
            lanLabel = label;
            lanLabel.text = @"";
        }
    }
    if (!lanLabel) {
        for (UILabel *label in cell.subviews[0].subviews) {
            if (label.tag == 99) {
                lanLabel = label;
                lanLabel.text = @"";
            }
        }
    }
    */
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([devArr count] > 0) {
        GizWifiDevice *dev = [devArr objectAtIndex:indexPath.row];
        NSString *devName = dev.alias;
        if (devName == nil || devName.length == 0) {
            devName = dev.productName;
        }
        cell.title.text = devName;
        [self customCell:cell device:dev];
        cell.imageView.hidden = NO;
        cell.textLabel.text = @"";
    }
    else {
        cell.textLabel.text = NSLocalizedString(@"No device", nil);
        cell.title.text = @"";
        cell.mac.text = @"";
        cell.lan.text = @"";
        [cell.imageView setImage:nil];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if (devArr.count == 0) {
        return NO;
    }
    return YES;
}

- (void)customCell:(GosDeviceListCell *)cell device:(GizWifiDevice *)dev {
    // 添加左边的图片
    UIGraphicsBeginImageContext(CGSizeMake(60, 60));
    UIImage *blankImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *subImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lst_icon_gokit-device"]];
    CGRect frame = subImageView.frame;
    
    frame.origin = CGPointMake(14, 14);
    subImageView.frame = frame;
    
    [cell.imageView addSubview:subImageView];
    cell.imageView.image = blankImage;
    cell.imageView.layer.cornerRadius = 10;
    
    cell.mac.text = dev.macAddress;
    
    if (dev.netStatus == GizDeviceOnline || dev.netStatus == GizDeviceControlled) {
        cell.imageView.backgroundColor = CUSTOM_GOKIT_COLOR();
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.lan.text = dev.isLAN?NSLocalizedString(@"Lan", nil):NSLocalizedString(@"Remote", nil);
        if (!dev.isBind) {
            cell.lan.text = NSLocalizedString(@"unbound", nil);
        }
    }
    else {
        cell.imageView.backgroundColor = [UIColor lightGrayColor];
        cell.lan.text = @"";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
//    NSArray *devArray = [self.deviceListArray objectAtIndex:indexPath.section];
//    if ([devArray count] > 0) {
////        [self.delegate deviceListController:self device:[devArray objectAtIndex:indexPath.row]];
//        [[GizDeviceControllerInstance sharedInstance] controller:self device:[devArray objectAtIndex:indexPath.row]];
//    }
    
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if ([devArr count] > 0) {
//        if ([[GizCommon sharedInstance] currentLoginStatus] == GizLoginNone) {
//            [self showAlert:@"请登录后再进行绑定操作"];
//            return;
//        }
        GizWifiDevice *dev = [devArr objectAtIndex:indexPath.row];
        if (dev.netStatus == GizDeviceOnline || dev.netStatus == GizDeviceControlled) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dev.delegate = self;
            [dev setSubscribe:YES];
            NSLog(@"****************************订阅设备****************************");
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return NO;
    }
    NSMutableArray *devArr = [self.deviceListArray objectAtIndex:indexPath.section];
    if (devArr.count == 0) {
        return NO;
    }
    return YES;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [dataArray removeObjectAtIndex:indexPath.row];
        // Delete the row from the data source.
//        [self.deviceListTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        NSString *uid = [GosCommon sharedInstance].uid;
        NSString *token = [GosCommon sharedInstance].token;
        GizWifiDevice *dev = [self getDeviceFromTable:indexPath];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[GizWifiSDK sharedInstance] unbindDevice:uid token:token did:dev.did];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return NSLocalizedString(@"Unbinding", nil);
}

#pragma mark
- (GizWifiDevice *)getDeviceFromTable:(NSIndexPath *)indexPath {
    NSArray *deviceArray = [self.deviceListArray objectAtIndex:indexPath.section];
    return [deviceArray objectAtIndex:indexPath.row];
}

- (IBAction)toAirLink:(id)sender {
#if (!TARGET_IPHONE_SIMULATOR)
    if (GetCurrentSSID().length > 0) {
#endif
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosAirLink" bundle:nil] instantiateInitialViewController];
        GosConfigStart *configStartVC = nav.viewControllers.firstObject;
        configStartVC.delegate = self;
        [self.navigationController pushViewController:configStartVC animated:YES];
#if (!TARGET_IPHONE_SIMULATOR)
    } else {
        [self showAlert:NSLocalizedString(@"Please switch to Wifi environment", nil)];
    }
#endif
}

- (void)toSettings {
    GosCommon *dataCommon = [GosCommon sharedInstance];
    if (dataCommon.settingPageHandler) {
        dataCommon.settingPageHandler(self.navigationController);
    } else {
        UINavigationController *nav = [[UIStoryboard storyboardWithName:@"GosSettings" bundle:nil] instantiateInitialViewController];
        GosSettingsViewController *settingsVC = nav.viewControllers.firstObject;
        [self.navigationController pushViewController:settingsVC animated:YES];
    }
}

#pragma mark - Back to root
- (void)gosConfigDidFinished {
    [self onPopToSelf:YES];
}

- (void)onPopToSelf:(BOOL)animated {
    if (self.navigationController.viewControllers.lastObject != self) {
        [self.navigationController popToViewController:self animated:YES];
    }
}

- (void)gosConfigDidSucceed:(GizWifiDevice *)device {
    //延迟1s执行
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [self loginWithDevice:device];
            [[GosCommon sharedInstance] onCancel];
        });
    });
}

#pragma mark - GizWifiSDK Delegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    if ([GosCommon sharedInstance].anonymousLoginOn) {
        [GosAnonymousLogin didUserLogin:result uid:uid token:token];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSError *)result deviceList:(NSArray *)deviceList {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [self refreshTableView];
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didBindDevice:(NSError *)result did:(NSString *)did {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code != GIZ_SDK_SUCCESS) {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSError *)result did:(NSString *)did {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
//        [self getBoundDevice];
    }
    else {
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDUnBind:(NSError *)result {
    [GosPushManager didUnbind:result];
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDBind:(NSError *)result {
    [GosPushManager didBind:result];
}

#pragma mark - GizWifiSDKDeviceDelegate
- (void)device:(GizWifiDevice *)device didSetSubscribe:(NSError *)result isSubscribed:(BOOL)isSubscribed {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS && isSubscribed == YES) {
        [GosCommon sharedInstance].controlHandler(device, self);
    }
    else {
        device.delegate = nil;
    }
}

#pragma mark - QRCode
- (void)intoQRCodeVC {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    if(authStatus == AVAuthorizationStatusDenied){
        if (IS_VAILABLE_IOS8) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera access restricted", nil) message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Allow camera prepend", nil), app_Name, NSLocalizedString(@"Allow camera append", nil)] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Go to Setting", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([self canOpenSystemSettingView]) {
                    [self systemSettingView];
                }
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera access restricted", nil) message:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"Allow camera prepend", nil), app_Name, NSLocalizedString(@"Allow camera append", nil)] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alert show];
        }
        
        return;
    }
    
    QRCodeController *qrcodeVC = [[QRCodeController alloc] init];
    qrcodeVC.view.alpha = 0;
    [qrcodeVC setDidCancelBlock:^{
        if ([GosCommon sharedInstance].recordPageHandler) {
            [GosCommon sharedInstance].recordPageHandler(self);
        }
    }];
    [qrcodeVC setDidReceiveBlock:^(NSString *result) {
        NSDictionary *dict = [self getScanResult:result];
        if(dict != nil)
        {
            NSString *did = [dict valueForKey:@"did"];
            NSString *passcode = [dict valueForKey:@"passcode"];
            NSString *productkey = [dict valueForKey:@"product_key"];
            
            //这里，要通过did，passcode，productkey获取一个设备
            if(did.length > 0 && passcode.length > 0 && productkey > 0)
            {
                NSString *uid = [GosCommon sharedInstance].uid;
                NSString *token = [GosCommon sharedInstance].token;
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [[GizWifiSDK sharedInstance] bindDeviceWithUid:uid token:token did:did passCode:passcode remark:nil];
            }
            else {
                [self showAlert:NSLocalizedString(@"Unknown QR Code", nil)];
            }
        }
        else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[GizWifiSDK sharedInstance] bindDeviceByQRCode:[GosCommon sharedInstance].uid token:[GosCommon sharedInstance].token QRContent:result];
        }
    }];
    AppDelegate *del = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [del.window.rootViewController addChildViewController:qrcodeVC];
    [del.window.rootViewController.view addSubview:qrcodeVC.view];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        qrcodeVC.view.alpha = 1;
        if ([GosCommon sharedInstance].recordPageHandler) {
            [GosCommon sharedInstance].recordPageHandler(qrcodeVC);
        }
    } completion:^(BOOL finished) {
    }];
}

- (BOOL)canOpenSystemSettingView {
    if (IS_VAILABLE_IOS8) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)systemSettingView {
    if (IS_VAILABLE_IOS8) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (NSDictionary *)getScanResult:(NSString *)result
{
    NSArray *arr1 = [result componentsSeparatedByString:@"?"];
    if(arr1.count != 2)
        return nil;
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    NSArray *arr2 = [arr1[1] componentsSeparatedByString:@"&"];
    for(NSString *str in arr2)
    {
        NSArray *keyValue = [str componentsSeparatedByString:@"="];
        if(keyValue.count != 2)
            continue;
        
        NSString *key = keyValue[0];
        NSString *value = keyValue[1];
        [mdict setValue:value forKeyPath:key];
    }
    return mdict;
}

@end
