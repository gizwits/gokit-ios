//
//  IoTNotReachable.m
//  WiFiDemo
//
//  Created by xpg on 14-6-6.
//  Copyright (c) 2014年 Xtreme Programming Group, Inc. All rights reserved.
//

#import "IoTNotReachable.h"

@interface IoTNotReachable ()

@end

@implementation IoTNotReachable

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.hidesBackButton = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)retry:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
