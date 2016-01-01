//
//  IoTGokitConfigureTypeSelection.h
//  WiFiDemo
//
//  Created by GeHaitong on 15/11/23.
//  Copyright © 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IoTGokitConfigureTypeSelectionDelegate <NSObject>

- (void)iotGokitConfigureTypeDidSelectType:(XPGWifiGAgentType)gagentType displayName:(NSString *)name;

@end

@interface IoTGokitConfigureTypeSelection : UITableViewController

- (id)initWithDelegate:(id<IoTGokitConfigureTypeSelectionDelegate>)delegate;

@end
