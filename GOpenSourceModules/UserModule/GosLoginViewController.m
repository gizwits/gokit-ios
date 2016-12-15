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
#import "WXApi.h"

#import "GosPushManager.h"
#import "GosAnonymousLogin.h"

#define APPDELEGATE ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface GosLoginViewController () <GizWifiSDKDelegate, TencentSessionDelegate, WXApiDelegate>

//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) GosTextCell *textCell;
@property (strong, nonatomic) GosPasswordCell *passwordCell;
@property (assign, nonatomic) CGFloat top;
@property (assign, nonatomic) IBOutlet UIView *loginBtnsBar;
@property (assign, nonatomic) IBOutlet UIView *loginQQBtn;
@property (assign, nonatomic) IBOutlet UIView *loginWechatBtn;
@property (assign, nonatomic) IBOutlet UIView *loginWeiboBtn;
//@property (assign, nonatomic) IBOutlet UIView *loginSkipBtn;
@property (strong, nonatomic) TencentOAuth *tencentOAuth;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *forgetBtn;

@end

@implementation GosLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //虚线
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
    CGPathMoveToPoint(path, NULL, 20, 0);
    CGPathAddLineToPoint(path, NULL, self.view.frame.size.width-20,0);
    [shapeLayer setPath:path];
    CGPathRelease(path);
    [[self.loginBtnsBar layer] addSublayer:shapeLayer];
    
    BOOL qqOn = [GosCommon sharedInstance].qqOn;
    BOOL wechatOn = [GosCommon sharedInstance].wechatOn;
    if (!qqOn) {
        self.loginQQBtn.hidden = YES;
    }
    
    if (!wechatOn) {
        self.loginWechatBtn.hidden = YES;
    }
    
    if (!qqOn && !wechatOn) {
        self.loginBtnsBar.hidden = YES;
    }
    
    self.loginBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.loginBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.loginBtn.layer setCornerRadius:22.0];
    self.automaticallyAdjustsScrollViewInsets = false;
    self.top = self.navigationController.navigationBar.translucent ? 0 : 64;
    [self setShowText:YES];
    UITapGestureRecognizer*tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInput)];
    [self.view addGestureRecognizer:tapGesture];
    [self.loginQQBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginQQBtnPressed)]];
    [self.loginWechatBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWechatBtnPressed)]];
//    [self.loginSkipBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginSkipBtnPressed)]];
    // 给忘记密码按钮添加下划线
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.forgetBtn.titleLabel.text];
    NSRange strRange = {0, [str length]};
    [str addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:strRange];
    [self.forgetBtn setAttributedTitle:str forState:UIControlStateNormal];
    
    // 默认进入设备列表界面
//    [self toDeviceListWithoutLogin:NO];
    [self autoLogin];
}

- (void)viewWillAppear:(BOOL)animated {
    self.textCell.textInput.text = [GosCommon sharedInstance].tmpUser;
    self.passwordCell.textPassword.text = [GosCommon sharedInstance].tmpPass;
    [GizWifiSDK sharedInstance].delegate = self;
    [self autoLogin];
    
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
//    if ([GizCommon sharedInstance].hasBeenLoggedIn) {
//        [self.skipBtn setHidden:YES];
//    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoLogin) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self cancelInput];
//    [[UIApplication sharedApplication] setStatusBarStyle:[GosCommon sharedInstance].statusBarStyle];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)autoLogin {
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    if (![MBProgressHUD HUDForView:self.view] && //上次没有执行登录操作
        username && [username length] > 0 && password && [password length] > 0) {
        [self userLogin:YES];
    }
}

- (void)cancelInput {
    [self.textCell.textInput resignFirstResponder];
    [self.passwordCell.textPassword resignFirstResponder];
    [self setViewY:self.top];
}

- (void)loginQQBtnPressed {
    if ([TENCENT_APP_ID isEqualToString:@"your_tencent_app_id"] || TENCENT_APP_ID.length == 0) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"请替换 GOpenSourceModules/CommonModule/UIConfig.json 中的参数定义为您申请到的QQ登录授权 app id" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            nil];
    self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:TENCENT_APP_ID andDelegate:self];
    [self.tencentOAuth authorize:permissions inSafari:NO];
}

- (void)loginWechatBtnPressed {
    if ([WECHAT_APP_ID isEqualToString:@"your_wechat_app_id"] || WECHAT_APP_ID.length == 0 || [WECHAT_APP_SECRET isEqualToString:@"your_wechat_app_secret"] || WECHAT_APP_SECRET.length == 0) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"请替换 GOpenSourceModules/CommonModule/UIConfig.json 中的参数定义为您申请到的微信登录授权 app id 及 app secret" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
        return;
    }
    [WXApi registerApp:WECHAT_APP_ID];
    if (![WXApi isWXAppInstalled]) {
        NSString *message = NSLocalizedString(@"haven't WeChat Application", @"未检测到微信，请安装后重试");
        NSString *confirm = NSLocalizedString(@"OK", @"确定");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:message delegate:self cancelButtonTitle:confirm otherButtonTitles:nil, nil] show];
        return;
    }
    [GosCommon sharedInstance].currentLoginStatus = GizLoginNone;
    //构造SendAuthReq结构体
    SendAuthReq* req =[[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"123" ;
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
    [GosCommon sharedInstance].WXApiOnRespHandler = ^(BaseResp *resp) {
        SendAuthResp *aresp = (SendAuthResp *)resp;
        if (aresp.errCode== 0) {
            NSString *code = aresp.code;
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [self getAccessToken:code];
        }
    };
}

-(void)getAccessToken:(NSString *)code {
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",WECHAT_APP_ID,WECHAT_APP_SECRET,code];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString *accessToken = [dic objectForKey:@"access_token"];
                NSString *openId = [dic objectForKey:@"openid"];
                [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdWeChat uid:openId token:accessToken];
                
            }
        });
    });
}

- (IBAction)loginSkipBtnPressed:(id)sender {
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
        [common showAlert:NSLocalizedString(@"please input cellphone", nil) disappear:YES];
        return;
    }
    if ([password isEqualToString:@""]) {
        [common showAlert:NSLocalizedString(@"please input password", nil) disappear:YES];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[GosCommon sharedInstance] saveUserDefaults:username password:password uid:nil token:nil];
    [[GizWifiSDK sharedInstance] userLogin:username password:password];
}

- (IBAction)userLoginBtnPressed:(id)sender {
    if ([GosCommon sharedInstance].anonymousLoginOn) {
        [GosAnonymousLogin cleanup];
    }
    [self userLogin:NO];
}

#pragma mark - GizWifiSDKDelegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    [MBProgressHUD hideHUDForView:self.view animated:!APPDELEGATE.isBackground];
    if ([GosCommon sharedInstance].anonymousLoginOn) {
        GosAnonymousLoginStatus lastStatus = [GosAnonymousLogin lastLoginStatus];
        if (lastStatus == GosAnonymousLoginStatusProcessing ||
            lastStatus == GosAnonymousLoginStatusFailed) {
            return;
        }
    }
    if (result.code == GIZ_SDK_SUCCESS) {
        [common showAlert:NSLocalizedString(@"Login successful", nil) disappear:YES];
        [[GosCommon sharedInstance] saveUserDefaults:nil password:nil uid:uid token:token];
        self.textCell.textInput.text = @"";
        self.passwordCell.textPassword.text = @"";
        UINavigationController *navCtrl = [[UIStoryboard storyboardWithName:@"GosDevice" bundle:nil] instantiateInitialViewController];
        GosDeviceListViewController *devListCtrl = navCtrl.viewControllers.firstObject;
        devListCtrl.parent = self;
        devListCtrl.needRefresh = YES;
        [GosCommon sharedInstance].currentLoginStatus = GizLoginUser;
        [GosPushManager unbindToGDMS:NO];
        [GosPushManager bindToGDMS];
        if (self.navigationController.viewControllers.lastObject == self) {
            [self.navigationController pushViewController:devListCtrl animated:YES];
        }
    } else {
        if (result.code != GIZ_SDK_DNS_FAILED &&
            result.code != GIZ_SDK_CONNECTION_TIMEOUT &&
            result.code != GIZ_SDK_CONNECTION_REFUSED &&
            result.code != GIZ_SDK_CONNECTION_ERROR &&
            result.code != GIZ_SDK_CONNECTION_CLOSED &&
            result.code != GIZ_SDK_SSL_HANDSHAKE_FAILED) {
            [[GosCommon sharedInstance] removeUserDefaults];
        }
        NSString *info = [[GosCommon sharedInstance] checkErrorCode:result.code];
        [common showAlert:info disappear:YES];
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

}

- (void)tencentDidNotNetWork {
    [common showAlert:NSLocalizedString(@"Login failed", nil) disappear:YES];
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
    
    NSString *textPassword = self.passwordCell.textPassword.text;
    self.passwordCell.textPassword.text = @"";
    self.passwordCell.textPassword.text = textPassword;
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
