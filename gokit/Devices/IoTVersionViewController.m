//
//  IoTVersionViewController.m
//  gokit
//
//  Created by Zono on 15/12/24.
//  Copyright © 2015年 xpg. All rights reserved.
//

#import "IoTVersionViewController.h"

@interface IoTVersionViewController () <UIAlertViewDelegate> {
    BOOL isUpdateReuqired;
    NSDictionary *dictUpdateInfo;
    
    UIAlertView *_alertView;
}

@property (weak, nonatomic) IBOutlet UILabel *textVersion;
@property (weak, nonatomic) IBOutlet UILabel *textSDKVersion;

@end

@implementation IoTVersionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textVersion.text = [self.textVersion.text stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    self.textSDKVersion.text = [self.textSDKVersion.text stringByAppendingString:[XPGWifiSDK getVersion]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
