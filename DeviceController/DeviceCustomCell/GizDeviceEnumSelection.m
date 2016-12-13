/**
 * GizDeviceEnumSelection.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "GizDeviceEnumSelection.h"
#import "GizDeviceEnumCell.h"

@interface GizDeviceEnumSelection ()

@property (assign) BOOL isSelected;
@property (nonatomic, strong) GizDeviceEnumCell *cell;

@end

@implementation GizDeviceEnumSelection

- (id)initWithEnumCell:(GizDeviceEnumCell *)cell
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        self.cell = cell;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.cell.title;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isSelected = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if(self.isSelected && [self.cell.delegate respondsToSelector:@selector(GizDeviceEnumDidSelectedValue:index:)])
    {
        [self.cell.delegate GizDeviceEnumDidSelectedValue:self.cell index:self.cell.index];
    }
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cell.values.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *enumIdentifier = @"enumCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:enumIdentifier];
    if(nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:enumIdentifier];
    }
    
    cell.textLabel.text = self.cell.values[indexPath.row];
    if(indexPath.row == self.cell.index)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView selectRowAtIndexPath:nil animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    NSInteger oldValue = self.cell.index;
    if (oldValue != indexPath.row)
    {
        self.cell.index = indexPath.row;
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldValue inSection:0];
        [tableView reloadRowsAtIndexPaths:@[oldIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    self.isSelected = YES;
    [self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:@YES afterDelay:0.2];
}

@end
