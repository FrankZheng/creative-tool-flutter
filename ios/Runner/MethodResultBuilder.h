//
//  MethodResultBuilder.h
//  Runner
//
//  Created by frank.zheng on 2019/5/26.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MethodResultBuilder : NSObject


+ (instancetype)builder;

- (void)didError:(nullable NSError *)error;

- (NSDictionary *)build;

@end

NS_ASSUME_NONNULL_END
