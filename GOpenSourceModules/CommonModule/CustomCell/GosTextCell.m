//
//  GizTextCell.m
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosTextCell.h"

@implementation GosTextCell

- (void)awakeFromNib {
    // Initialization code
//    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
//    [self addGestureRecognizer:tapGesture];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)onTap {
    NSURL *url = [NSURL URLWithString:@"prefs:root=WIFI"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:@"请手动点击桌面的 '设置' 图标，然后选择 '无线局域网'。" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    [self setSelected:NO animated:NO];
}

@end
