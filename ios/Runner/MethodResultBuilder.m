//
//  MethodResultBuilder.m
//  Runner
//
//  Created by frank.zheng on 2019/5/26.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "MethodResultBuilder.h"
#import "FlutterChannelDefines.h"

@interface MethodResultBuilder()
@property(nonatomic, strong) NSError *error;
@property(nonatomic, assign) BOOL didError;

@end

@implementation MethodResultBuilder

+ (instancetype)builder {
    MethodResultBuilder *instance = [MethodResultBuilder alloc];
    return instance;
}

- (void)didError:(NSError *)error {
    _didError = YES;
    _error = error;
}


- (NSDictionary *)build {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if(_didError) {
        result[kReturnValue] = @(NO);
        if(_error != nil) {
            result[kErrCode] = @(_error.code);
            result[kErrMsg] = _error.localizedDescription;
        }
    } else {
        result[kReturnValue] = @(YES);
    }
    return [result copy];
}


@end
