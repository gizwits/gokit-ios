//
//  IoTDeviceEnumSelection.m
//  Gokit-demo
//
//  Created by xpg on 14/10/27.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import "IoTDeviceEnumSelection.h"
#import "IoTDeviceEnumCell.h"

@interface IoTDeviceEnumSelection ()
{
    BOOL selected;
}

@property (nonatomic, strong) IoTDeviceEnumCell *cell;

@end

@implementation IoTDeviceEnumSelection

- (id)initWithEnumCell:(IoTDeviceEnumCell *)cell
{
    self = [super initWithStyle:UITableViewStylePlain];
    if(self)
    {
        self.cell = cell;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = self.cell.title;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    selected = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if(selected && [self.cell.delegate respondsToSelector:@selector(IoTDeviceEnumDidSelectedValue:index:)])
        [self.cell.delegate IoTDeviceEnumDidSelectedValue:self.cell index:self.cell.index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cell.values.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *enumIdentifier = @"enumCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:enumIdentifier];
    if(nil == cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:enumIdentifier];
    
    cell.textLabel.text = self.cell.values[indexPath.row];
    if(indexPath.row == self.cell.index)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    NSInteger oldValue = self.cell.index;
    if(oldValue != indexPath.row)
    {
        self.cell.index = indexPath.row;
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldValue inSection:0];
        [tableView reloadRowsAtIndexPaths:@[oldIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    selected = YES;
    [self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:@YES afterDelay:0.2];
}

@end
