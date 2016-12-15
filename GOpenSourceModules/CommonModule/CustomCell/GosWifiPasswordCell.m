//
//  GosWifiPasswordCell.m
//  NewFlow
//
//  Created by Zono on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosWifiPasswordCell.h"

@implementation GosWifiPasswordCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
