//
//  GosConfigModuleSelection.m
//  GOpenSourceAppKit
//
//  Created by Zono on 16/6/2.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosConfigModuleSelection.h"
#import "GosCommon.h"

@interface GosConfigModuleSelection () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) NSInteger currentSelectionIndex;
@property (nonatomic, strong) UITableView *selectionTableView;

@end

@implementation GosConfigModuleSelection

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Module type selection", nil);
    self.selectionTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.selectionTableView.delegate = self;
    self.selectionTableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//- (void)returnConfigModule:(ReturnConfigModule)block {
//    self.ReturnConfigModuleBlock = block;
//}

- (void)viewWillAppear:(BOOL)animated {
    self.currentSelectionIndex = [[GosCommon sharedInstance].configModuleValueArray indexOfObject:@([GosCommon sharedInstance].airlinkConfigType)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"configModuleSelectionCell"];
    if(nil == cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"configModuleSelectionCell"];
    if(indexPath.row == self.currentSelectionIndex)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = [[GosCommon sharedInstance].configModuleTextArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.currentSelectionIndex = indexPath.row;
    [GosCommon sharedInstance].airlinkConfigType = [[[GosCommon sharedInstance].configModuleValueArray objectAtIndex:self.currentSelectionIndex] integerValue];
//    NSLog(@"[GosCommon sharedInstance].airlinkConfigType = %@", @([GosCommon sharedInstance].airlinkConfigType));
//    if (self.ReturnConfigModuleBlock != nil) {
//        self.ReturnConfigModuleBlock([[GosCommon sharedInstance].configModuleTextArray objectAtIndex:self.currentSelectionIndex], self.currentSelectionIndex);
//    }
    [self.navigationController popViewControllerAnimated:YES];
}


@end
