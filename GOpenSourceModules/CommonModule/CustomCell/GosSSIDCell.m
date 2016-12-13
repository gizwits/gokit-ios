//
//  GizSSIDCell.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosSSIDCell.h"

@implementation GosSSIDCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self addGestureRecognizer:tapGesture];
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
        NSString *message = NSLocalizedString(@"Manually click \"Settings\" icon on your desktop, then select \"Wi-Fi\"", nil);
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tip", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
    
    [self setSelected:NO animated:NO];
}

@end
