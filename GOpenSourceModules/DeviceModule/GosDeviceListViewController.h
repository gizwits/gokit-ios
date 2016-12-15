//
//  DeviceListViewController.h
//  GBOSA
//
//  Created by Zono on 16/5/6.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GosConfigStart.h"

@interface GosDeviceListViewController : UIViewController <GosConfigStartDelegate>

@property (nonatomic, strong) IBOutlet UITableView *deviceListTableView;
@property (nonatomic, strong) UIViewController *parent;
@property (nonatomic, strong) NSArray *deviceListArray;

@property (nonatomic, weak) IBOutlet UIButton *addDeviceImageBtn;
@property (nonatomic, weak) IBOutlet UIButton *addDeviceLabelBtn;

@property (nonatomic, assign) BOOL needRefresh;

@end