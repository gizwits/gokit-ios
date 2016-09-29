//
//  ViewController.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosConfigStart.h"
#import "GosSSIDCell.h"
#import "GosWifiPasswordCell.h"
#import "GosCommon.h"
#import "GosConfigModuleSelection.h"

@interface GosConfigStart () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) GosSSIDCell *ssidCell;
@property (strong, nonatomic) GosWifiPasswordCell *passwordCell;

@property (assign, nonatomic) CGFloat top;
@property (weak, nonatomic) IBOutlet UIButton *btnAutoJump;

@property (weak, nonatomic) IBOutlet UIButton *selectModuleBtn;
//@property (assign, nonatomic) NSInteger currentSelectionIndex;
//@property (strong, nonatomic) NSString *currentSelectionText;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@end

@implementation GosConfigStart

- (void)didEnterBackground {
    [self.passwordCell.textPassword resignFirstResponder];
    
}

- (void)didBecomeActive {
    if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            usleep(500000);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.passwordCell.textPassword becomeFirstResponder];
            });
        });
    } else {
        [self.passwordCell.textPassword becomeFirstResponder];
    }
    [self getCurrentConfig];
}

- (void)getCurrentConfig {
    NSString *ssid = GetCurrentSSID();
    self.ssidCell.textSSID.text = ssid;
    self.passwordCell.textPassword.text = [[GosCommon sharedInstance] getPasswrodFromSSID:ssid];
    
    if (0 < self.passwordCell.textPassword.text.length) {
        [self setShowText:NO];
    } else {
        [self setShowText:YES];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.currentSelectionIndex = 0;
    self.tableView.scrollEnabled = NO;
    self.top = self.navigationController.navigationBar.translucent ? 0 : 64;
    if ([GosCommon sharedInstance].moduleSelectOn) {
        [self.selectModuleBtn setHidden:NO];
    }
    
    self.nextBtn.backgroundColor = [GosCommon sharedInstance].buttonColor;
    [self.nextBtn setTitleColor:[GosCommon sharedInstance].buttonTextColor forState:UIControlStateNormal];
    [self.nextBtn.layer setCornerRadius:19.0];
    NSString *titleString = [GosCommon sharedInstance].addDeviceTitle;
    if (titleString && titleString.length > 0) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Add", nil), titleString];
    }
    
    if (0 == GetCurrentSSID().length) {
        [[GosCommon sharedInstance] showAlert:NSLocalizedString(@"No open Wi-Fi", nil) disappear:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self.tableView reloadData];
    
    NSInteger indexOfAirlinkType = [[GosCommon sharedInstance].configModuleValueArray indexOfObject:@([GosCommon sharedInstance].airlinkConfigType)];
    [self.selectModuleBtn setTitle:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Select the type of module", nil), [[GosCommon sharedInstance].configModuleTextArray objectAtIndex:indexOfAirlinkType]] forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self onTap];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

    [self.passwordCell.textPassword resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDelegate:(id<GizConfigStartDelegate>)delegate {
    [GosCommon sharedInstance].delegate = delegate;
}

- (IBAction)selectModule:(id)sender {
    GosConfigModuleSelection *configModuleSelection = [[GosConfigModuleSelection alloc] init];
//    configModuleSelection.currentSelectionIndex = self.currentSelectionIndex;
    [self.navigationController pushViewController:configModuleSelection animated:YES];
//    [configModuleSelection returnConfigModule:^(NSString *text, NSInteger index) {
//        NSLog(@" ======== %@, %@", text, @(index));
//        self.currentSelectionIndex = index;
//        self.currentSelectionText = text;
//        [self.selectModuleBtn setTitle:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Select the type of module", nil), text] forState:UIControlStateNormal];
//    }];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            if (nil == self.ssidCell) {
                self.ssidCell = GetControllerWithClass([GosSSIDCell class], tableView, @"ssidCell");
                self.ssidCell.textSSID.delegate = self;
                self.ssidCell.textSSID.returnKeyType = UIReturnKeyNext;
                self.ssidCell.textSSID.enabled = NO;
            }
            return self.ssidCell;
        case 1:
            if (nil == self.passwordCell) {
                self.passwordCell = GetControllerWithClass([GosWifiPasswordCell class], tableView, @"passwordCell");
                self.passwordCell.textPassword.delegate = self;
                self.passwordCell.textPassword.returnKeyType = UIReturnKeyDone;
//                [self.passwordCell.btnClearPassword addTarget:self action:@selector(onClearPassword) forControlEvents:UIControlEventTouchUpInside];
                [self.passwordCell.btnShowText addTarget:self action:@selector(onShowText) forControlEvents:UIControlEventTouchUpInside];
                
                //加载初始化的信息
                [self getCurrentConfig];
            }
            return self.passwordCell;
        default:
            break;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - text field
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        [self setViewY:-118];
    }
    NSString *textPassword = self.passwordCell.textPassword.text;
    self.passwordCell.textPassword.text = @"";
    self.passwordCell.textPassword.text = textPassword;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.ssidCell.textSSID) {
        [self.passwordCell.textPassword becomeFirstResponder];
    } else {
        [self.passwordCell.textPassword resignFirstResponder];
        [self setViewY:self.top];
    }
    return NO;
}

#pragma mark - alert view
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (1 == buttonIndex) {
        if (ALERT_TAG_CANCEL_CONFIG == alertView.tag) {
            [[GosCommon sharedInstance] onCancel];
        } else if (ALERT_TAG_EMPTY_PASSWORD == alertView.tag) {
            [self onPushToNextPage];
        }
    }
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
//    NSString *textPassword = self.passwordCell.textPassword.text;
//    self.passwordCell.textPassword.text = @"";
    self.passwordCell.textPassword.secureTextEntry = !isShow;
    self.passwordCell.btnShowText.selected = isShow;
//    self.passwordCell.textPassword.text = textPassword;
}

#pragma mark - Event
- (void)onClearPassword {
    self.passwordCell.textPassword.text = @"";
}

- (void)onShowText {
    [self onTap];
    [self setShowText:self.passwordCell.textPassword.secureTextEntry];
}

- (void)onPushToNextPage {
    GosCommon *dataCommon = [GosCommon sharedInstance];
    dataCommon.ssid = self.ssidCell.textSSID.text;
    if (nil == dataCommon.ssid) {
        dataCommon.ssid = @"";
    }
    [dataCommon saveSSID:dataCommon.ssid key:self.passwordCell.textPassword.text];
    [self.btnAutoJump sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)onNext:(id)sender {
    if (0 == self.passwordCell.textPassword.text.length) {
        SHOW_ALERT_EMPTY_PASSWORD(self);
    } else {
        [self onPushToNextPage];
    }
}

- (IBAction)onTap {
    [self setViewY:self.top];
    [self.passwordCell.textPassword resignFirstResponder];
}

- (IBAction)onCancel:(id)sender {
    SHOW_ALERT_CANCEL_CONFIG(self);
}

@end
