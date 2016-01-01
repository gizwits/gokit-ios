//
//  IoTGokitConfigureTypeSelection.m
//  WiFiDemo
//
//  Created by GeHaitong on 15/11/23.
//  Copyright © 2015年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTGokitConfigureTypeSelection.h"
//#import "IoTGokitConfigurationHelp.h"

@interface IoTGokitConfigureTypeSelection ()

@property (assign, nonatomic) id<IoTGokitConfigureTypeSelectionDelegate>delegate;

@property (strong, nonatomic) NSArray *gagentTypes;

@end

@implementation IoTGokitConfigureTypeSelection

- (id)initWithDelegate:(id<IoTGokitConfigureTypeSelectionDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.gagentTypes = @[@{@"name": NSLS(@"gokit_airlink_type_HF"), @"value": @(XPGWifiGAgentTypeHF)},
                         @{@"name": NSLS(@"gokit_airlink_type_EMW"), @"value": @(XPGWifiGAgentTypeMXCHIP)},
                         @{@"name": NSLS(@"gokit_airlink_type_ESP"), @"value": @(XPGWifiGAgentTypeESP)},
                         @{@"name": NSLS(@"gokit_airlink_type_RTK"), @"value": @(XPGWifiGAgentTypeRTK)},
                         @{@"name": NSLS(@"gokit_airlink_type_QCA"), @"value": @(XPGWifiGAgentTypeQCA)},
                         @{@"name": NSLS(@"gokit_airlink_type_WM"), @"value": @(XPGWifiGAgentTypeWM)},
                         @{@"name": NSLS(@"gokit_airlink_type_TI"), @"value": @(XPGWifiGAgentTypeTI)},
                         ];
    
    self.navigationItem.title = NSLS(@"gokit_airlink_title_selection");
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"help.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(onHelp)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onHelp
{
//    IoTGokitConfigurationHelp * helpCtrl = [[IoTGokitConfigurationHelp alloc] init];
//    [AppDelegate safePushController:helpCtrl animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.gagentTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"gagentTypeIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = self.gagentTypes[indexPath.row][@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [AppDelegate safePopController:YES currentViewController:self];
    
    NSDictionary *gagentInfo = self.gagentTypes[indexPath.row];
    NSInteger type = [gagentInfo[@"value"] integerValue];
    NSString *displayName = gagentInfo[@"name"];
    [self.delegate iotGokitConfigureTypeDidSelectType:type displayName:displayName];;
}

@end
