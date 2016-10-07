//
//  GosDeviceListCell.h
//  GosGokit
//
//  Created by Zono on 16/6/8.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GosDeviceListCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *mac;
@property (nonatomic, weak) IBOutlet UILabel *lan;

@end
