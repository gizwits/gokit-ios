//
//  GizPasswordCell.m
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import "GosPasswordCell.h"

@implementation GosPasswordCell

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
