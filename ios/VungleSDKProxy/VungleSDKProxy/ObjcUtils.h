//
//  ObjcUtils.h
//  VungleSDKProxy
//
//  Created by Frank Zheng on 2019/5/19.
//  Copyright © 2019 Frank Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjcUtils : NSObject

+ (BOOL)isSelector:(SEL)selector
        ofProtocol:(Protocol *)protocol;


@end

NS_ASSUME_NONNULL_END
