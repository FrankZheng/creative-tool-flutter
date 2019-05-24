//
//  AppModel.m
//  Runner
//
//  Created by frank.zheng on 2019/5/24.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "AppModel.h"
#import <UIKit/UIKit.h>

@implementation AppModel

+(void)closeApp {
    
    UIApplication *app = [UIApplication sharedApplication];
    [app performSelector:@selector(suspend)];
    [NSThread sleepForTimeInterval:1];
    exit(0);
}

@end
