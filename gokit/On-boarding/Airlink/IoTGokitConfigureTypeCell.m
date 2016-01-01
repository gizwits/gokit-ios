//
//  IoTGokitConfigureTypeCell.m
//  WiFiDemo
//
//  Created by GeHaitong on 15/11/23.
//  Copyright © 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTGokitConfigureTypeCell.h"

@implementation IoTGokitConfigureTypeCell

- (void)awakeFromNib {
    // Initialization code
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
