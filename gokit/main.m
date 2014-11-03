//
//  main.m
//  Gokit-demo
//
//  Created by xpg on 14/10/21.
//  Copyright (c) 2014年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IoTAppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        @try {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([IoTAppDelegate class]));
        }
        @catch (NSException *exception) {

        }
    }
}
