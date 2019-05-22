//
//  ObjcUtils.m
//  VungleSDKProxy
//
//  Created by Frank Zheng on 2019/5/19.
//  Copyright © 2019 Frank Zheng. All rights reserved.
//

#import "ObjcUtils.h"
@import ObjectiveC;

@implementation ObjcUtils

+ (BOOL)isSelector:(SEL)selector
        ofProtocol:(Protocol *)protocol {
    unsigned int outCount = 0;
    struct objc_method_description *descriptions
    = protocol_copyMethodDescriptionList(protocol,
                                         NO, //get optional methods
                                         YES,
                                         &outCount);
    for (unsigned int i = 0; i < outCount; ++i) {
        if (descriptions[i].name == selector) {
            free(descriptions);
            return YES;
        }
    }
    free(descriptions);
    return NO;
}


@end
