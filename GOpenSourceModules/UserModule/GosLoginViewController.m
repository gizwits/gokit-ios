//
//  LoginViewController.m
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosLoginViewController.h"
#import "AppDelegate.h"
#import "GosTextCell.h"
#import "GosPasswordCell.h"
#import <GizWifiSDK/GizWifiSDK.h>

#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentApiInterface.h>

#import "GosPushManager.h"

#define APPDELEGATE ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface GosLoginViewController () <GizWifiSDKDelegate, TencentSessionDelegate>

//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) GosTextCell *textCell;
@property (strong, nonatomic) GosPasswordCell *passwordCell;
@property (assign, nonatomic) CGFloat top;
@property (assign, nonatomic) IBOutlet UIView *loginBtnsBar;
@property (assign, nonatomic) IBOutlet UIView *loginQQBtn;
@property (assign, nonatomic) IBOutlet UIView *loginWechatBtn;
@property (assign, nonatomic) IBOutlet UIView *loginWeiboBtn;
@property (assign, nonatomic) IBOutlet UIView *loginSkipBtn;
@property (strong, nonatomic) TencentOAuth *tencentOAuth;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation GosLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setBounds:self.view.bounds];
    [shapeLayer setPosition:self.view.center];
    [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
    [shapeLayer setStrokeColor:[[UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1.0f] CGColor]];
    [shapeLayer setLineWidth:1.0f];
    [shapeLayer setLineJoin:kCALineJoinRound];
    [shapeLayer setLineDashPattern:
     [NSArray arrayWithObjects:[NSNumber numberWithInt:3], [NSNumber numberWithInt:2],nil]];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, self.view.frame.size.width,0);
    [shapeLayer setPath:path];
    CGPathRelease(path);
    [[self.loginBtnsBar layer] addSublayer:shapeLayer];
    
    self.loginBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.loginBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    self.automaticallyAdjustsScrollViewInsets = false;
    self.top = self.navigationController.navigationBar.translucent ? 0 : 64;
    [self setShowText:YES];
    UITapGestureRecognizer*tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInput)];
    [self.view addGestureRecognizer:tapGesture];
    [self.loginQQBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginQQBtnPressed)]];
    [self.loginSkipBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginSkipBtnPressed)]];
    
    // 默认进入设备列表界面
//    [self toDeviceListWithoutLogin:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    [self.navigationController.navigationBar setHidden:YES];
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    if (username && [username length] > 0 && password && [password length] > 0) {
        [self userLogin:YES];
    }
    [GizWifiSDK sharedInstance].delegate = self;
//    if ([GizCommon sharedInstance].hasBeenLoggedIn) {
//        [self.skipBtn setHidden:YES];
//    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self cancelInput];
//    [[UIApplication sharedApplication] setStatusBarStyle:[GosCommon sharedInstance].statusBarStyle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)cancelInput {
    [self.textCell.textInput resignFirstResponder];
    [self.passwordCell.textPassword resignFirstResponder];
    [self setViewY:self.top];
}

- (void)loginQQBtnPressed {
    [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            nil];
    self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:TENCENT_APP_ID andDelegate:self];
    [self.tencentOAuth authorize:permissions inSafari:NO];
}

- (void)loginSkipBtnPressed {
    [self toDeviceListWithoutLogin:YES];
}

#pragma mark - table view
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
//    
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
//    }
//    cell.textLabel.text = @"";
//    return cell;
    
    switch (indexPath.row) {
        case 0:
            if (nil == self.textCell) {
                self.textCell = GetControllerWithClass([GosTextCell class], tableView, @"ssidCell");
                self.textCell.textInput.delegate = self;
                self.textCell.textInput.returnKeyType = UIReturnKeyNext;
            }
            return self.textCell;
        case 1:
            if (nil == self.passwordCell) {
                self.passwordCell = GetControllerWithClass([GosPasswordCell class], tableView, @"passwordCell");
                self.passwordCell.textPassword.delegate = self;
                self.passwordCell.textPassword.returnKeyType = UIReturnKeyDone;
                [self.passwordCell.btnShowText addTarget:self action:@selector(onShowText) forControlEvents:UIControlEventTouchUpInside];
            }
            return self.passwordCell;
        default:
            break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark
- (void)userLogin:(BOOL)automatic {
    [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
    NSString *username = nil;
    NSString *password = nil;
    if (automatic) {
        username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
        password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    }
    else {
        username = self.textCell.textInput.text;
        password = self.passwordCell.textPassword.text;
    }
    if([username isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Username can not be empty", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        return;
    }
    if (password.length < 6) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"The password must be at least six characters", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[GosCommon sharedInstance] saveUserDefaults:username password:password uid:nil token:nil];
    [[GizWifiSDK sharedInstance] userLogin:username password:password];
}

- (IBAction)userLoginBtnPressed:(id)sender {
    [self userLogin:NO];
}

#pragma mark - GizWifiSDKDelegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    if ([GosCommon sharedInstance].currentLoginStatus == GizLoginAnonymousProcess || [GosCommon sharedInstance].currentLoginStatus == GizLoginAnonymousCancel) {
        return;
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (result.code == GIZ_SDK_SUCCESS) {
//        [GizCommon sharedInstance].hasBeenLoggedIn = YES;
        [[GosCommon sharedInstance] saveUserDefaults:nil password:nil uid:uid token:token];
        self.textCell.textInput.text = @"";
        self.passwordCell.textPassword.text = @"";
        UINavigationController *navCtrl = [[UIStoryboard storyboardWithName:@"GosDevice" bundle:nil] instantiateInitialViewController];
        GosDeviceListViewController *devListCtrl = navCtrl.viewControllers.firstObject;
        devListCtrl.parent = self;
        devListCtrl.needRefresh = YES;
        [GosCommon sharedInstance].currentLoginStatus = GizLoginUser;
        [GosPushManager bindToGDMS];
        [self.navigationController pushViewController:devListCtrl animated:YES];
    }
//    else if (result.code == 8050) {
//        GIZ_LOG_DEBUG("userLoginAnonymous failed");
//    }
    else {
        [[GosCommon sharedInstance] removeUserDefaults];
        NSString *info = [NSString stringWithFormat:@"%@\n%@ - %@", NSLocalizedString(@"Login failed", nil), @(result.code), [result.userInfo objectForKey:@"NSLocalizedDescription"]];
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:info delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
    }
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDUnBind:(NSError *)result {
    [GosPushManager didUnbind:result];
}

#pragma mark - TencentDelegate
- (void)tencentDidLogin {
    GIZ_LOG_DEBUG("tencent login successed");
    if (self.tencentOAuth.accessToken && 0 != [self.tencentOAuth.accessToken length])
    {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdQQ uid:self.tencentOAuth.openId token:self.tencentOAuth.accessToken];
    }
    else
    {
        GIZ_LOG_DEBUG("tencent login successed, but no accessToken");
    }
}

- (void)tencentDidNotLogin:(BOOL)cancelled {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Login Cancel", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}

- (void)tencentDidNotNetWork {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Login failed", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}


#pragma mark - textField Delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.textCell.textInput) {
//        [self setViewY:-60];
    } else {
        if ([[UIScreen mainScreen] bounds].size.height == 480) {
            [self setViewY:-20];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textCell.textInput) {
        [self.passwordCell.textPassword becomeFirstResponder];
    } else {
        [self.passwordCell.textPassword resignFirstResponder];
        [self setViewY:self.top];
    }
    return NO;
}

#pragma mark - view animation
- (void)setViewY:(CGFloat)y {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    CGRect rc = self.view.frame;
    rc.origin.y = y;
    self.view.frame = rc;
    [UIView commitAnimations];
}

- (void)setShowText:(BOOL)isShow {
    UITextField *textPassword = self.passwordCell.textPassword;
    textPassword.secureTextEntry = !isShow;
    self.passwordCell.btnShowText.selected = isShow;
}

#pragma mark - Event
- (void)onClearPassword {
    self.passwordCell.textPassword.text = @"";
}

- (void)onShowText {
    [self onTap];
    [self setShowText:self.passwordCell.textPassword.secureTextEntry];
}

- (IBAction)onTap {
    [self setViewY:self.top];
    [self.passwordCell.textPassword resignFirstResponder];
}

- (void)toDeviceListWithoutLogin:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navCtrl = [[UIStoryboard storyboardWithName:@"GosDevice" bundle:nil] instantiateInitialViewController];
        GosDeviceListViewController *devListCtrl = navCtrl.viewControllers.firstObject;
        devListCtrl.parent = self;
        devListCtrl.needRefresh = YES;
        [self.navigationController pushViewController:devListCtrl animated:animated];
    });
}

@end
