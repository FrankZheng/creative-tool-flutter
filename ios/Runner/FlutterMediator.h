//
//  FlutterMediator.h
//  Runner
//
//  Created by frank.zheng on 2019/5/15.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "GeneratedPluginRegistrant.h"

NS_ASSUME_NONNULL_BEGIN

@interface FlutterMediator : NSObject

+ (instancetype)sharedInstance;

- (void)startWithFlutterViewController:(FlutterViewController*)vc;





@end

NS_ASSUME_NONNULL_END
