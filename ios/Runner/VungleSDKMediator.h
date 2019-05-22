//
//  VungleSDKMediator.h
//  Runner
//
//  Created by frank.zheng on 2019/5/20.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "GeneratedPluginRegistrant.h"

NS_ASSUME_NONNULL_BEGIN

@interface VungleSDKMediator : NSObject

+(instancetype)sharedInstance;

- (void)startWithFlutterViewController:(FlutterViewController*)vc;

@end

NS_ASSUME_NONNULL_END
