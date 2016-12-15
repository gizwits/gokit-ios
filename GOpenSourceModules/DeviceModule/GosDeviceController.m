//
//  GizDeviceController.m
//  GizOpenSourceKit
//
//  Created by Zono on 16/5/20.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosDeviceController.h"

@interface GosDeviceController () <GizWifiDeviceDelegate>

@property (nonatomic, strong) GizWifiDevice *device;
@property (nonatomic, weak) IBOutlet UILabel *macLabel;

@end

@implementation GosDeviceController

- (id)initWithDevice:(GizWifiDevice *)device {
    self = [super init];
    if (self) {
        _device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.device.delegate = self;
    self.macLabel.text = self.device.macAddress;
    
    if (self.device.alias.length) {
        self.navigationItem.title = self.device.alias;
    } else {
        self.navigationItem.title = self.device.productName;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
